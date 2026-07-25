import Foundation

// MARK: - Content authority

/// Environmental interactables for P9 Big-Box proof. Explicit opportunity + cost; no hidden stat scaling.
public struct InteractableCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let maxActiveInteractables: Int
    public let interactables: [InteractableDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/interactables"

    public static let allowedFamilies: Set<String> = [
        "electrical", "communications", "access", "civilian", "response", "surveillance",
        "traffic", "transit", "construction"
    ]

    public static let allowedActivationKinds: Set<String> = [
        "stressInfrastructure"
    ]

    public static let bundled: InteractableCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled interactables: \(error)") }
    }()

    public static func loadBundled() throws -> InteractableCatalog {
        guard let url = contentBundle.url(forResource: "interactables", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "interactables", withExtension: "json")
        else { throw InteractableError.missingResource }
        let catalog = try JSONDecoder().decode(InteractableCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func interactables(for district: DistrictID) -> [InteractableDefinition] {
        interactables.filter { $0.districtId == district }
    }

    public func definition(_ id: String) -> InteractableDefinition? {
        interactables.first { $0.id == id }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw InteractableError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw InteractableError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw InteractableError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard maxActiveInteractables >= 1, maxActiveInteractables <= 32 else {
            throw InteractableError.invalidDefinition("maxActiveInteractables out of band")
        }
        guard !interactables.isEmpty else {
            throw InteractableError.invalidDefinition("interactables must be non-empty")
        }
        guard Set(interactables.map(\.id)).count == interactables.count else {
            throw InteractableError.invalidDefinition("duplicate interactable ids")
        }
        // P9/P10 proof floor: projected districts need ≥6 interactables when present.
        for district in [DistrictID.wichita, .louisville, .tulsa, .dayton, .oakland, .sanFrancisco] {
            let items = interactables.filter { $0.districtId == district }
            if !items.isEmpty {
                guard items.count >= 6 else {
                    throw InteractableError.invalidDefinition(
                        "\(district.rawValue) proof requires ≥6 interactables"
                    )
                }
            }
        }
        for item in interactables {
            try item.validate(
                families: Self.allowedFamilies,
                activationKinds: Self.allowedActivationKinds
            )
        }
        // Cross-check linked infrastructure nodes when city-state graph exists for that district.
        let city = CityStateCatalog.bundled
        for item in interactables {
            if let graph = city.graph(for: item.districtId) {
                guard graph.node(id: item.linkedInfrastructureNodeId) != nil else {
                    throw InteractableError.invalidDefinition(
                        "\(item.id) links unknown node \(item.linkedInfrastructureNodeId)"
                    )
                }
            }
        }
    }
}

public struct InteractableActivation: Codable, Equatable, Sendable {
    public let kind: String
    public let integrityHit: Double
}

public struct InteractableDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let districtId: DistrictID
    public let family: String
    public let label: String
    public let position: Vector2
    public let radius: Double
    public let telegraphSeconds: Double
    public let cooldownSeconds: Double
    public let linkedInfrastructureNodeId: String
    public let activation: InteractableActivation
    public let opportunity: String
    public let cost: String

    func validate(families: Set<String>, activationKinds: Set<String>) throws {
        guard !id.isEmpty, !label.isEmpty else {
            throw InteractableError.invalidDefinition("id/label required")
        }
        guard families.contains(family) else {
            throw InteractableError.invalidDefinition("\(id) unknown family \(family)")
        }
        guard radius > 0, radius <= 80 else {
            throw InteractableError.invalidDefinition("\(id) radius out of band")
        }
        guard telegraphSeconds >= 0, telegraphSeconds <= 2 else {
            throw InteractableError.invalidDefinition("\(id) telegraphSeconds out of band")
        }
        guard cooldownSeconds > 0, cooldownSeconds <= 120 else {
            throw InteractableError.invalidDefinition("\(id) cooldownSeconds out of band")
        }
        guard !linkedInfrastructureNodeId.isEmpty else {
            throw InteractableError.invalidDefinition("\(id) linkedInfrastructureNodeId required")
        }
        guard activationKinds.contains(activation.kind) else {
            throw InteractableError.invalidDefinition("\(id) bad activation kind")
        }
        guard (0.05...0.5).contains(activation.integrityHit) else {
            throw InteractableError.invalidDefinition("\(id) integrityHit out of band")
        }
        guard !opportunity.isEmpty, !cost.isEmpty else {
            throw InteractableError.invalidDefinition("\(id) opportunity and cost required")
        }
    }
}

public enum InteractableError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Runtime

public struct InteractableRuntimeState: Codable, Equatable, Sendable {
    public var id: String
    public var availableAtElapsed: Double
    public var activationCount: Int

    public init(id: String, availableAtElapsed: Double = 0, activationCount: Int = 0) {
        self.id = id
        self.availableAtElapsed = availableAtElapsed
        self.activationCount = activationCount
    }
}

public struct InteractableActivationSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var interactableId: String
    public var label: String
    public var linkedNodeId: String
    public var opportunity: String
    public var cost: String
    public var integrityHit: Double

    public init(
        tick: UInt64,
        interactableId: String,
        label: String,
        linkedNodeId: String,
        opportunity: String,
        cost: String,
        integrityHit: Double
    ) {
        self.tick = tick
        self.interactableId = interactableId
        self.label = label
        self.linkedNodeId = linkedNodeId
        self.opportunity = opportunity
        self.cost = cost
        self.integrityHit = integrityHit
    }
}

public struct InteractableStepResult: Equatable, Sendable {
    public var states: [InteractableRuntimeState]
    public var samples: [InteractableActivationSample]
    public var districtState: DistrictState
    public var cityStateEvents: [CityStateEventSample]
}

public enum InteractableEngine: Sendable {
    public static func initialStates(
        catalog: InteractableCatalog = .bundled,
        district: DistrictID
    ) -> [InteractableRuntimeState] {
        catalog.interactables(for: district).map { InteractableRuntimeState(id: $0.id) }
    }

    /// Activate the nearest ready interactable in range when utility is pressed.
    public static func tryActivate(
        catalog: InteractableCatalog = .bundled,
        cityCatalog: CityStateCatalog = .bundled,
        district: DistrictID,
        playerPosition: Vector2,
        elapsed: Double,
        tick: UInt64,
        utilityPressed: Bool,
        states: [InteractableRuntimeState],
        districtState: DistrictState
    ) -> InteractableStepResult {
        guard catalog.forbidHiddenStatScaling else {
            return InteractableStepResult(
                states: states,
                samples: [],
                districtState: districtState,
                cityStateEvents: []
            )
        }
        guard utilityPressed else {
            return InteractableStepResult(
                states: states,
                samples: [],
                districtState: districtState,
                cityStateEvents: []
            )
        }

        var nextStates = states
        var samples: [InteractableActivationSample] = []
        var nextDistrict = districtState
        var cityEvents: [CityStateEventSample] = []

        let defs = catalog.interactables(for: district)
        // Nearest ready interactable in radius.
        let candidates: [(InteractableDefinition, Int, Double)] = defs.compactMap { def in
            guard let index = nextStates.firstIndex(where: { $0.id == def.id }) else { return nil }
            guard elapsed >= nextStates[index].availableAtElapsed else { return nil }
            let distance = (playerPosition - def.position).magnitude
            guard distance <= def.radius else { return nil }
            return (def, index, distance)
        }
        guard let best = candidates.min(by: { $0.2 < $1.2 }) else {
            return InteractableStepResult(
                states: nextStates,
                samples: [],
                districtState: nextDistrict,
                cityStateEvents: []
            )
        }

        let def = best.0
        let index = best.1
        nextStates[index].availableAtElapsed = elapsed + def.cooldownSeconds
        nextStates[index].activationCount += 1

        samples.append(
            InteractableActivationSample(
                tick: tick,
                interactableId: def.id,
                label: def.label,
                linkedNodeId: def.linkedInfrastructureNodeId,
                opportunity: def.opportunity,
                cost: def.cost,
                integrityHit: def.activation.integrityHit
            )
        )

        if def.activation.kind == "stressInfrastructure" {
            let (hitState, hitEvents) = CityStateEngine.applyHit(
                catalog: cityCatalog,
                state: nextDistrict,
                nodeId: def.linkedInfrastructureNodeId,
                amount: def.activation.integrityHit,
                tick: tick,
                reason: "interactable \(def.id)"
            )
            nextDistrict = hitState
            cityEvents.append(contentsOf: hitEvents)
        }

        return InteractableStepResult(
            states: nextStates,
            samples: samples,
            districtState: nextDistrict,
            cityStateEvents: cityEvents
        )
    }
}
