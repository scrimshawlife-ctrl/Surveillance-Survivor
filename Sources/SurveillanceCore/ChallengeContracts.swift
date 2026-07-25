import Foundation

// MARK: - Catalog

/// P11 challenge contracts: explicit policy mutators for daily/weekly runs.
/// Never damage/health inflation.
public struct ChallengeContractCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String
    public let forbidHiddenStatScaling: Bool
    public let contracts: [ChallengeContract]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/challenge_contracts"

    public static let allowedMutatorKinds: Set<String> = [
        "observationPressureBonus",
        "spawnIntervalMultiplier",
        "guardTargetDelta",
        "extraUpgradeWeightingTag"
    ]

    public static let forbiddenMutatorKinds: Set<String> = [
        "playerDamageScale",
        "enemyHealthScale",
        "playerHealthScale",
        "hiddenDifficulty",
        "damageScale",
        "healthScale"
    ]

    public static let bundled: ChallengeContractCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled challenge contracts: \(error)") }
    }()

    public static func loadBundled() throws -> ChallengeContractCatalog {
        guard let url = contentBundle.url(forResource: "challenge_contracts", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "challenge_contracts", withExtension: "json")
        else { throw ChallengeContractError.missingResource }
        let catalog = try JSONDecoder().decode(ChallengeContractCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func contract(id: String) -> ChallengeContract? {
        contracts.first { $0.id == id }
    }

    public func contracts(kind: String) -> [ChallengeContract] {
        contracts.filter { $0.kind == kind }
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw ChallengeContractError.unsupportedSchema(schemaVersion)
        }
        guard schemaId == Self.expectedSchemaId else {
            throw ChallengeContractError.invalidDefinition("schemaId must be \(Self.expectedSchemaId)")
        }
        guard forbidHiddenStatScaling else {
            throw ChallengeContractError.invalidDefinition("forbidHiddenStatScaling must be true")
        }
        guard contracts.count >= 3 else {
            throw ChallengeContractError.invalidDefinition("need ≥3 challenge contracts")
        }
        guard Set(contracts.map(\.id)).count == contracts.count else {
            throw ChallengeContractError.invalidDefinition("duplicate contract ids")
        }
        let families = BuildEngineCatalog.expectedFamilies
        for contract in contracts {
            try contract.validate(families: families)
        }
    }
}

public struct ChallengeContract: Codable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    public let kind: String
    public let mutators: [ChallengeMutator]
    public let opportunity: String
    public let cost: String

    func validate(families: Set<String>) throws {
        guard !id.isEmpty, !displayName.isEmpty else {
            throw ChallengeContractError.invalidDefinition("contract needs id and displayName")
        }
        guard kind == "daily" || kind == "weekly" else {
            throw ChallengeContractError.invalidDefinition("\(id) kind must be daily|weekly")
        }
        guard !mutators.isEmpty else {
            throw ChallengeContractError.invalidDefinition("\(id) needs ≥1 mutator")
        }
        guard !opportunity.isEmpty, !cost.isEmpty else {
            throw ChallengeContractError.invalidDefinition("\(id) needs opportunity and cost")
        }
        guard Set(mutators.map(\.id)).count == mutators.count else {
            throw ChallengeContractError.invalidDefinition("\(id) duplicate mutator ids")
        }
        for mutator in mutators {
            try mutator.validate(families: families, contractId: id)
        }
    }

    public var extraUpgradeWeightingTags: [String] {
        mutators.compactMap { $0.kind == "extraUpgradeWeightingTag" ? $0.tag : nil }
    }

    public var observationPressureBonus: Double {
        mutators
            .filter { $0.kind == "observationPressureBonus" }
            .compactMap(\.amount)
            .reduce(0, +)
    }

    public var spawnIntervalMultiplier: Double {
        let values = mutators
            .filter { $0.kind == "spawnIntervalMultiplier" }
            .compactMap(\.amount)
        guard !values.isEmpty else { return 1.0 }
        return values.reduce(1.0, *)
    }

    public var guardTargetDelta: Int {
        Int(mutators
            .filter { $0.kind == "guardTargetDelta" }
            .compactMap(\.amount)
            .reduce(0, +)
            .rounded())
    }
}

public struct ChallengeMutator: Codable, Equatable, Sendable {
    public let id: String
    public let kind: String
    public let amount: Double?
    public let tag: String?

    public init(id: String, kind: String, amount: Double? = nil, tag: String? = nil) {
        self.id = id
        self.kind = kind
        self.amount = amount
        self.tag = tag
    }

    func validate(families: Set<String>, contractId: String) throws {
        guard !id.isEmpty else {
            throw ChallengeContractError.invalidDefinition("\(contractId) empty mutator id")
        }
        if ChallengeContractCatalog.forbiddenMutatorKinds.contains(kind) {
            throw ChallengeContractError.invalidDefinition("\(contractId) forbidden mutator \(kind)")
        }
        guard ChallengeContractCatalog.allowedMutatorKinds.contains(kind) else {
            throw ChallengeContractError.invalidDefinition("\(contractId) unknown mutator kind \(kind)")
        }
        switch kind {
        case "observationPressureBonus":
            guard let amount, (0...0.25).contains(amount) else {
                throw ChallengeContractError.invalidDefinition("\(id) observationPressureBonus out of band")
            }
        case "spawnIntervalMultiplier":
            guard let amount, (0.5...1.5).contains(amount) else {
                throw ChallengeContractError.invalidDefinition("\(id) spawnIntervalMultiplier out of band")
            }
        case "guardTargetDelta":
            guard let amount, (-2...3).contains(amount) else {
                throw ChallengeContractError.invalidDefinition("\(id) guardTargetDelta out of band")
            }
        case "extraUpgradeWeightingTag":
            guard let tag, families.contains(tag) else {
                throw ChallengeContractError.invalidDefinition("\(id) needs valid build-family tag")
            }
        default:
            break
        }
    }
}

public enum ChallengeContractError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case invalidDefinition(String)
}

// MARK: - Challenge resolution

/// Resolved daily or weekly challenge instance (seed + city + contract).
public struct ChallengeInstance: Codable, Equatable, Sendable {
    public var kind: String
    public var dayKey: String
    public var seed: UInt64
    public var districtId: DistrictID
    public var contractId: String
    public var contractDisplayName: String
    public var mutatorIds: [String]
    public var extraUpgradeWeightingTags: [String]
    public var observationPressureBonus: Double
    public var spawnIntervalMultiplier: Double
    public var guardTargetDelta: Int

    public init(
        kind: String,
        dayKey: String,
        seed: UInt64,
        districtId: DistrictID,
        contractId: String,
        contractDisplayName: String,
        mutatorIds: [String],
        extraUpgradeWeightingTags: [String],
        observationPressureBonus: Double,
        spawnIntervalMultiplier: Double,
        guardTargetDelta: Int
    ) {
        self.kind = kind
        self.dayKey = dayKey
        self.seed = seed
        self.districtId = districtId
        self.contractId = contractId
        self.contractDisplayName = contractDisplayName
        self.mutatorIds = mutatorIds
        self.extraUpgradeWeightingTags = extraUpgradeWeightingTags
        self.observationPressureBonus = observationPressureBonus
        self.spawnIntervalMultiplier = spawnIntervalMultiplier
        self.guardTargetDelta = guardTargetDelta
    }
}

public enum ChallengeResolver: Sendable {
    /// UTC calendar day key `YYYY-MM-DD`.
    public static func dayKey(for date: Date, calendar: Calendar = ChallengeResolver.utcCalendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 1970
        let m = c.month ?? 1
        let d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// ISO week key `YYYY-Www` in UTC.
    public static func weekKey(for date: Date, calendar: Calendar = ChallengeResolver.utcCalendar) -> String {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let y = cal.component(.yearForWeekOfYear, from: date)
        let w = cal.component(.weekOfYear, from: date)
        return String(format: "%04d-W%02d", y, w)
    }

    public static var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return cal
    }

    public static func daily(
        for date: Date = Date(),
        catalog: ChallengeContractCatalog = .bundled,
        districts: [DistrictID] = DistrictID.allCases
    ) -> ChallengeInstance {
        let key = dayKey(for: date)
        let seed = mixSeed(salt: 0xD41A_0001, key: key)
        return resolve(
            kind: "daily",
            key: key,
            seed: seed,
            pool: catalog.contracts(kind: "daily"),
            fallbackPool: catalog.contracts,
            districts: districts
        )
    }

    public static func weekly(
        for date: Date = Date(),
        catalog: ChallengeContractCatalog = .bundled,
        districts: [DistrictID] = DistrictID.allCases
    ) -> ChallengeInstance {
        let key = weekKey(for: date)
        let seed = mixSeed(salt: 0x0EE3_0002, key: key)
        return resolve(
            kind: "weekly",
            key: key,
            seed: seed,
            pool: catalog.contracts(kind: "weekly"),
            fallbackPool: catalog.contracts,
            districts: districts
        )
    }

    private static func resolve(
        kind: String,
        key: String,
        seed: UInt64,
        pool: [ChallengeContract],
        fallbackPool: [ChallengeContract],
        districts: [DistrictID]
    ) -> ChallengeInstance {
        let contracts = pool.isEmpty ? fallbackPool : pool
        precondition(!contracts.isEmpty && !districts.isEmpty)
        let district = districts[Int(seed % UInt64(districts.count))]
        let contract = contracts[Int((seed >> 17) % UInt64(contracts.count))]
        return ChallengeInstance(
            kind: kind,
            dayKey: key,
            seed: seed,
            districtId: district,
            contractId: contract.id,
            contractDisplayName: contract.displayName,
            mutatorIds: contract.mutators.map(\.id),
            extraUpgradeWeightingTags: contract.extraUpgradeWeightingTags,
            observationPressureBonus: contract.observationPressureBonus,
            spawnIntervalMultiplier: contract.spawnIntervalMultiplier,
            guardTargetDelta: contract.guardTargetDelta
        )
    }

    /// Stable FNV-1a style mix of salt + key bytes.
    public static func mixSeed(salt: UInt64, key: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        hash ^= salt
        hash &*= 0x100000001b3
        for byte in key.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        // Scramble so low bits are well mixed for district indexing.
        hash ^= hash >> 33
        hash &*= 0xff51afd7ed558ccd
        hash ^= hash >> 33
        hash &*= 0xc4ceb9fe1a85ec53
        hash ^= hash >> 33
        return hash == 0 ? 0x9E3779B97F4A7C15 : hash
    }
}
