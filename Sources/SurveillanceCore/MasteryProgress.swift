import Foundation

/// Offline mastery / run-history value type (P11).
/// Simulation never reads this store; the app layer persists it like CampaignProgress.
public struct MasteryProgress: Codable, Equatable, Sendable {
    public static let schemaVersion = 1
    public static let defaultHistoryCap = 40

    public var runHistory: [RunHistoryEntry]
    public var challengeCompletions: [String: Int]
    public var totalRuns: Int
    public var totalExtractions: Int
    public var dailyBestStreak: Int
    public var currentDailyStreak: Int
    public var lastDailyDayKey: String?
    /// Presentation unlock ids earned via mastery (cosmetics / radio / weather / motifs).
    public var unlockedItemIds: [String]
    /// Most recent unlock ids granted on the last `record` call (for UI toast).
    public var lastGrantedUnlockIds: [String]

    public static var initial: MasteryProgress {
        MasteryProgress(
            runHistory: [],
            challengeCompletions: [:],
            totalRuns: 0,
            totalExtractions: 0,
            dailyBestStreak: 0,
            currentDailyStreak: 0,
            lastDailyDayKey: nil,
            unlockedItemIds: [],
            lastGrantedUnlockIds: []
        )
    }

    public init(
        runHistory: [RunHistoryEntry],
        challengeCompletions: [String: Int],
        totalRuns: Int,
        totalExtractions: Int,
        dailyBestStreak: Int,
        currentDailyStreak: Int,
        lastDailyDayKey: String?,
        unlockedItemIds: [String] = [],
        lastGrantedUnlockIds: [String] = []
    ) {
        self.runHistory = runHistory
        self.challengeCompletions = challengeCompletions
        self.totalRuns = totalRuns
        self.totalExtractions = totalExtractions
        self.dailyBestStreak = dailyBestStreak
        self.currentDailyStreak = currentDailyStreak
        self.lastDailyDayKey = lastDailyDayKey
        self.unlockedItemIds = unlockedItemIds
        self.lastGrantedUnlockIds = lastGrantedUnlockIds
    }

    private enum CodingKeys: String, CodingKey {
        case runHistory, challengeCompletions, totalRuns, totalExtractions
        case dailyBestStreak, currentDailyStreak, lastDailyDayKey
        case unlockedItemIds, lastGrantedUnlockIds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        runHistory = try c.decodeIfPresent([RunHistoryEntry].self, forKey: .runHistory) ?? []
        challengeCompletions = try c.decodeIfPresent([String: Int].self, forKey: .challengeCompletions) ?? [:]
        totalRuns = try c.decodeIfPresent(Int.self, forKey: .totalRuns) ?? 0
        totalExtractions = try c.decodeIfPresent(Int.self, forKey: .totalExtractions) ?? 0
        dailyBestStreak = try c.decodeIfPresent(Int.self, forKey: .dailyBestStreak) ?? 0
        currentDailyStreak = try c.decodeIfPresent(Int.self, forKey: .currentDailyStreak) ?? 0
        lastDailyDayKey = try c.decodeIfPresent(String.self, forKey: .lastDailyDayKey)
        unlockedItemIds = try c.decodeIfPresent([String].self, forKey: .unlockedItemIds) ?? []
        lastGrantedUnlockIds = try c.decodeIfPresent([String].self, forKey: .lastGrantedUnlockIds) ?? []
    }

    /// Record a finished run. Caps history; never applies permanent damage/HP inflation.
    @discardableResult
    public mutating func record(
        entry: RunHistoryEntry,
        historyCap: Int = Self.defaultHistoryCap,
        unlockCatalog: UnlockCatalog = .bundled
    ) -> [UnlockableItem] {
        totalRuns += 1
        if entry.extractionCompleted {
            totalExtractions += 1
        }
        if let contractId = entry.challengeContractId, entry.extractionCompleted {
            challengeCompletions[contractId, default: 0] += 1
        }
        if entry.challengeKind == "daily", let dayKey = entry.challengeDayKey {
            updateDailyStreak(dayKey: dayKey, extracted: entry.extractionCompleted)
        }
        runHistory.insert(entry, at: 0)
        if runHistory.count > historyCap {
            runHistory = Array(runHistory.prefix(historyCap))
        }
        let earned = grantUnlocks(using: unlockCatalog)
        return earned
    }

    /// Grant any newly eligible unlockables. Returns newly granted items.
    @discardableResult
    public mutating func grantUnlocks(using catalog: UnlockCatalog = .bundled) -> [UnlockableItem] {
        let newly = catalog.newlyEarned(by: self)
        guard !newly.isEmpty else {
            lastGrantedUnlockIds = []
            return []
        }
        var owned = Set(unlockedItemIds)
        for item in newly {
            owned.insert(item.id)
        }
        unlockedItemIds = owned.sorted()
        lastGrantedUnlockIds = newly.map(\.id).sorted()
        return newly
    }

    private mutating func updateDailyStreak(dayKey: String, extracted: Bool) {
        guard extracted else {
            // Failed daily does not break streak tracking day-to-day until a win lands.
            return
        }
        if let last = lastDailyDayKey, last == dayKey {
            // Same day re-clear: no streak change.
            return
        }
        if let last = lastDailyDayKey, Self.isConsecutiveDay(previous: last, current: dayKey) {
            currentDailyStreak += 1
        } else {
            currentDailyStreak = 1
        }
        dailyBestStreak = max(dailyBestStreak, currentDailyStreak)
        lastDailyDayKey = dayKey
    }

    /// Pure YYYY-MM-DD consecutive check (UTC keys).
    public static func isConsecutiveDay(previous: String, current: String) -> Bool {
        guard let prev = parseDay(previous), parseDay(current) != nil else { return false }
        let cal = ChallengeResolver.utcCalendar
        guard let prevDate = cal.date(from: prev),
              let expected = cal.date(byAdding: .day, value: 1, to: prevDate)
        else { return false }
        let expectedKey = ChallengeResolver.dayKey(for: expected, calendar: cal)
        return expectedKey == current
    }

    private static func parseDay(_ key: String) -> DateComponents? {
        let parts = key.split(separator: "-")
        guard parts.count == 3,
              let y = Int(parts[0]),
              let m = Int(parts[1]),
              let d = Int(parts[2])
        else { return nil }
        return DateComponents(year: y, month: m, day: d)
    }

    public func sanitized(historyCap: Int = Self.defaultHistoryCap) -> MasteryProgress {
        var copy = self
        copy.totalRuns = max(0, totalRuns)
        copy.totalExtractions = max(0, min(totalExtractions, totalRuns))
        copy.dailyBestStreak = max(0, dailyBestStreak)
        copy.currentDailyStreak = max(0, currentDailyStreak)
        // Best must never lag current after decode/sanitize recovery.
        copy.dailyBestStreak = max(copy.dailyBestStreak, copy.currentDailyStreak)
        if copy.runHistory.count > historyCap {
            copy.runHistory = Array(copy.runHistory.prefix(historyCap))
        }
        copy.challengeCompletions = challengeCompletions.filter { $0.value > 0 }
        // Stable unique unlock ids; drop unknown ids; repair earned rewards from totals.
        let catalog = UnlockCatalog.bundled
        let knownIds = Set(catalog.items.map(\.id))
        var seen = Set<String>()
        copy.unlockedItemIds = unlockedItemIds
            .filter { knownIds.contains($0) && seen.insert($0).inserted }
        for item in catalog.eligible(for: copy) where !copy.unlockedItemIds.contains(item.id) {
            copy.unlockedItemIds.append(item.id)
        }
        copy.unlockedItemIds.sort()
        // Sanitize must not invent toast grants; only keep still-owned prior grants.
        copy.lastGrantedUnlockIds = lastGrantedUnlockIds.filter { copy.unlockedItemIds.contains($0) }
        return copy
    }
}

public struct RunHistoryEntry: Codable, Equatable, Sendable {
    public var finishedAt: String
    public var seed: UInt64
    public var districtId: DistrictID
    public var extractionCompleted: Bool
    public var elapsedSeconds: Double
    public var selectedUpgrades: [String]
    public var matchedClearingBuildId: String?
    public var challengeKind: String?
    public var challengeContractId: String?
    public var challengeDayKey: String?

    public init(
        finishedAt: String,
        seed: UInt64,
        districtId: DistrictID,
        extractionCompleted: Bool,
        elapsedSeconds: Double,
        selectedUpgrades: [String],
        matchedClearingBuildId: String? = nil,
        challengeKind: String? = nil,
        challengeContractId: String? = nil,
        challengeDayKey: String? = nil
    ) {
        self.finishedAt = finishedAt
        self.seed = seed
        self.districtId = districtId
        self.extractionCompleted = extractionCompleted
        self.elapsedSeconds = elapsedSeconds
        self.selectedUpgrades = selectedUpgrades
        self.matchedClearingBuildId = matchedClearingBuildId
        self.challengeKind = challengeKind
        self.challengeContractId = challengeContractId
        self.challengeDayKey = challengeDayKey
    }

    public static func fromReceipt(
        _ receipt: RunReceipt,
        finishedAt: String = ISO8601DateFormatter().string(from: Date())
    ) -> RunHistoryEntry {
        RunHistoryEntry(
            finishedAt: finishedAt,
            seed: receipt.seed,
            districtId: receipt.district,
            extractionCompleted: receipt.extractionCompleted,
            elapsedSeconds: receipt.elapsedSeconds,
            selectedUpgrades: receipt.selectedUpgrades.map(\.rawValue),
            matchedClearingBuildId: receipt.matchedClearingBuildId,
            challengeKind: receipt.challenge?.kind,
            challengeContractId: receipt.challenge?.contractId,
            challengeDayKey: receipt.challenge?.dayKey
        )
    }
}
