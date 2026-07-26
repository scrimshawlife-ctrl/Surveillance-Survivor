import Foundation

// MARK: - Content authority

/// Dynamic City State graph authority (P8). Nodes + edges only; no hidden damage/health scaling.
public struct CityStateCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let nodeFamilies: [String]
    public let relationKinds: [String]
    public let districtGraphs: [DistrictInfrastructureGraph]
    public let degradedThreshold: Double
    public let offlineThreshold: Double
    public let sensorDestroyIntegrityHit: Double
    public let maxPropagationDepth: Int

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/infrastructure_nodes"

    public static let expectedFamilies: Set<String> = [
        "surveillanceSensors",
        "electricalPower",
        "communicationsFiber",
        "trafficControl",
        "accessControl",
        "transitSystems",
        "civilianReporting",
        "emergencyResponse"
    ]

    public static let expectedRelations: Set<String> = [
        "powers",
        "carriesSignal",
        "routesThrough",
        "reportsTo",
        "reinforces"
    ]

    public static let bundled: CityStateCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled infrastructure nodes: \(error)") }
    }()

    public static func loadBundled() throws -> CityStateCatalog {
        guard let url = contentBundle.url(forResource: "infrastructure_nodes", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "infrastructure_nodes", withExtension: "json")
        else { throw CityStateError.missingResource }
        let catalog = try JSONDecoder().decode(CityStateCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func graph(for district: DistrictID) -> DistrictInfrastructureGraph? {
        districtGraphs.first { $0.districtId == district }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw CityStateError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw CityStateError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw CityStateError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard Set(nodeFamilies) == Self.expectedFamilies else {
            throw CityStateError.invalidDefinition("nodeFamilies must match the approved eight families")
        }
        guard Set(relationKinds) == Self.expectedRelations else {
            throw CityStateError.invalidDefinition("relationKinds must match the approved set")
        }
        guard (0...1).contains(degradedThreshold), (0...1).contains(offlineThreshold) else {
            throw CityStateError.invalidDefinition("thresholds must be in 0...1")
        }
        guard offlineThreshold < degradedThreshold else {
            throw CityStateError.invalidDefinition("offlineThreshold must be < degradedThreshold")
        }
        guard (0...1).contains(sensorDestroyIntegrityHit), sensorDestroyIntegrityHit > 0 else {
            throw CityStateError.invalidDefinition("sensorDestroyIntegrityHit must be in (0...1]")
        }
        guard maxPropagationDepth >= 1, maxPropagationDepth <= 8 else {
            throw CityStateError.invalidDefinition("maxPropagationDepth out of band")
        }
        guard !districtGraphs.isEmpty else {
            throw CityStateError.invalidDefinition("districtGraphs must be non-empty")
        }
        var seenDistricts = Set<DistrictID>()
        for graph in districtGraphs {
            if !seenDistricts.insert(graph.districtId).inserted {
                throw CityStateError.invalidDefinition("duplicate district graph \(graph.districtId.rawValue)")
            }
            try graph.validate(families: Self.expectedFamilies, relations: Self.expectedRelations)
        }
    }
}

public struct DistrictInfrastructureGraph: Codable, Equatable, Sendable {
    public let districtId: DistrictID
    public let displayName: String
    public let nodes: [InfrastructureNodeDefinition]
    public let edges: [InfrastructureEdgeDefinition]

    public func node(id: String) -> InfrastructureNodeDefinition? {
        nodes.first { $0.id == id }
    }

    func validate(families: Set<String>, relations: Set<String>) throws {
        guard !displayName.isEmpty else {
            throw CityStateError.invalidDefinition("empty displayName for \(districtId.rawValue)")
        }
        guard nodes.count >= 3 else {
            throw CityStateError.invalidDefinition("\(districtId.rawValue) needs at least 3 infrastructure nodes")
        }
        guard Set(nodes.map(\.id)).count == nodes.count else {
            throw CityStateError.invalidDefinition("\(districtId.rawValue) has duplicate node ids")
        }
        let ids = Set(nodes.map(\.id))
        for node in nodes {
            try node.validate(families: families)
        }
        guard !edges.isEmpty else {
            throw CityStateError.invalidDefinition("\(districtId.rawValue) needs at least one edge")
        }
        for edge in edges {
            guard ids.contains(edge.from), ids.contains(edge.to) else {
                throw CityStateError.invalidDefinition("\(districtId.rawValue) edge references unknown node")
            }
            guard edge.from != edge.to else {
                throw CityStateError.invalidDefinition("\(districtId.rawValue) self-edge forbidden")
            }
            guard relations.contains(edge.relation) else {
                throw CityStateError.invalidDefinition("unknown relation \(edge.relation)")
            }
            guard (0...1).contains(edge.propagationWeight) else {
                throw CityStateError.invalidDefinition("propagationWeight out of band")
            }
        }
        // At least three approved families present (P9 proof floor for one district).
        let familiesPresent = Set(nodes.map(\.family))
        guard familiesPresent.count >= 3 else {
            throw CityStateError.invalidDefinition("\(districtId.rawValue) must use ≥3 node families")
        }
    }
}

public struct InfrastructureNodeDefinition: Codable, Equatable, Sendable {
    public let id: String
    public let family: String
    public let label: String
    public let integrity: Double
    public let opportunityOnOffline: String
    public let costOnOffline: String

    func validate(families: Set<String>) throws {
        guard !id.isEmpty, !label.isEmpty else {
            throw CityStateError.invalidDefinition("node id/label must be non-empty")
        }
        guard families.contains(family) else {
            throw CityStateError.invalidDefinition("unknown family \(family)")
        }
        guard (0...1).contains(integrity) else {
            throw CityStateError.invalidDefinition("node integrity out of band")
        }
        guard !opportunityOnOffline.isEmpty, !costOnOffline.isEmpty else {
            throw CityStateError.invalidDefinition("node \(id) must declare opportunity and cost when offline")
        }
    }
}

public struct InfrastructureEdgeDefinition: Codable, Equatable, Sendable {
    public let from: String
    public let to: String
    public let relation: String
    public let propagationWeight: Double
}

public enum CityStateError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Runtime state

public enum InfrastructureNodeStatus: String, Codable, Equatable, Sendable {
    case online
    case degraded
    case offline
}

public struct InfrastructureNodeRuntime: Codable, Equatable, Sendable {
    public var id: String
    public var family: String
    public var integrity: Double
    public var status: InfrastructureNodeStatus

    public init(id: String, family: String, integrity: Double, status: InfrastructureNodeStatus) {
        self.id = id
        self.family = family
        self.integrity = integrity
        self.status = status
    }
}

public struct DistrictState: Codable, Equatable, Sendable {
    public var districtId: DistrictID
    public var nodes: [InfrastructureNodeRuntime]
    public var lastPropagationTick: UInt64?

    public static func empty(district: DistrictID) -> DistrictState {
        DistrictState(districtId: district, nodes: [], lastPropagationTick: nil)
    }

    public init(districtId: DistrictID, nodes: [InfrastructureNodeRuntime], lastPropagationTick: UInt64? = nil) {
        self.districtId = districtId
        self.nodes = nodes
        self.lastPropagationTick = lastPropagationTick
    }

    public func node(id: String) -> InfrastructureNodeRuntime? {
        nodes.first { $0.id == id }
    }

    public var offlineCount: Int { nodes.filter { $0.status == .offline }.count }
    public var degradedCount: Int { nodes.filter { $0.status == .degraded }.count }
}

public struct CityStateEventSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var nodeId: String
    public var family: String
    public var status: InfrastructureNodeStatus
    public var integrity: Double
    public var reason: String

    public init(
        tick: UInt64,
        nodeId: String,
        family: String,
        status: InfrastructureNodeStatus,
        integrity: Double,
        reason: String
    ) {
        self.tick = tick
        self.nodeId = nodeId
        self.family = family
        self.status = status
        self.integrity = integrity
        self.reason = reason
    }
}

// MARK: - Pure graph engine

public enum CityStateEngine: Sendable {
    /// Seed a runtime district state from the authored graph (identity integrity).
    public static func initialState(
        catalog: CityStateCatalog = .bundled,
        district: DistrictID
    ) -> DistrictState {
        guard let graph = catalog.graph(for: district) else {
            return .empty(district: district)
        }
        let nodes = graph.nodes.map { def in
            InfrastructureNodeRuntime(
                id: def.id,
                family: def.family,
                integrity: def.integrity,
                status: status(for: def.integrity, catalog: catalog)
            )
        }
        return DistrictState(districtId: district, nodes: nodes)
    }

    public static func status(for integrity: Double, catalog: CityStateCatalog) -> InfrastructureNodeStatus {
        if integrity <= catalog.offlineThreshold { return .offline }
        if integrity <= catalog.degradedThreshold { return .degraded }
        return .online
    }

    /// Apply a direct integrity hit, then propagate downstream consequences.
    public static func applyHit(
        catalog: CityStateCatalog = .bundled,
        state: DistrictState,
        nodeId: String,
        amount: Double,
        tick: UInt64,
        reason: String
    ) -> (DistrictState, [CityStateEventSample]) {
        guard let graph = catalog.graph(for: state.districtId),
              state.nodes.contains(where: { $0.id == nodeId })
        else { return (state, []) }

        var next = state
        var events: [CityStateEventSample] = []
        guard let index = next.nodes.firstIndex(where: { $0.id == nodeId }) else { return (state, []) }
        let prior = next.nodes[index]
        let hit = max(0, amount)
        next.nodes[index].integrity = max(0, min(1, prior.integrity - hit))
        next.nodes[index].status = status(for: next.nodes[index].integrity, catalog: catalog)
        if next.nodes[index] != prior {
            events.append(
                CityStateEventSample(
                    tick: tick,
                    nodeId: nodeId,
                    family: next.nodes[index].family,
                    status: next.nodes[index].status,
                    integrity: next.nodes[index].integrity,
                    reason: reason
                )
            )
        }

        // BFS propagate integrity loss along outgoing edges. Visit edges (not nodes) so
        // converging paths each contribute loss without re-traversing the same edge.
        var frontier: [(id: String, depth: Int, loss: Double)] = [(nodeId, 0, hit)]
        var visitedEdges = Set<String>()
        while let current = frontier.first {
            frontier.removeFirst()
            guard current.depth < catalog.maxPropagationDepth else { continue }
            let outgoing = graph.edges.filter { $0.from == current.id }
            for edge in outgoing {
                let edgeKey = "\(edge.from)->\(edge.to)"
                guard visitedEdges.insert(edgeKey).inserted else { continue }
                let propagatedLoss = current.loss * edge.propagationWeight
                guard propagatedLoss > 0.001 else { continue }
                guard let targetIndex = next.nodes.firstIndex(where: { $0.id == edge.to }) else { continue }
                let before = next.nodes[targetIndex]
                next.nodes[targetIndex].integrity = max(0, min(1, before.integrity - propagatedLoss))
                next.nodes[targetIndex].status = status(for: next.nodes[targetIndex].integrity, catalog: catalog)
                if next.nodes[targetIndex] != before {
                    events.append(
                        CityStateEventSample(
                            tick: tick,
                            nodeId: edge.to,
                            family: next.nodes[targetIndex].family,
                            status: next.nodes[targetIndex].status,
                            integrity: next.nodes[targetIndex].integrity,
                            reason: "propagated via \(edge.relation) from \(current.id)"
                        )
                    )
                }
                frontier.append((edge.to, current.depth + 1, propagatedLoss))
            }
        }
        next.lastPropagationTick = tick
        return (next, events)
    }

    /// Primary surveillance node for a district (first surveillanceSensors family), if any.
    public static func primarySurveillanceNodeId(
        catalog: CityStateCatalog = .bundled,
        district: DistrictID
    ) -> String? {
        catalog.graph(for: district)?.nodes.first(where: { $0.family == "surveillanceSensors" })?.id
    }

    /// Explicit, readable observation multiplier from city-state (never damage/health).
    /// Offline sensor grid softens pressure; degraded is partial.
    public static func observationPressureMultiplier(state: DistrictState) -> Double {
        guard let sensor = state.nodes.first(where: { $0.family == "surveillanceSensors" }) else {
            return 1.0
        }
        switch sensor.status {
        case .online: return 1.0
        case .degraded: return 0.85
        case .offline: return 0.65
        }
    }
}
