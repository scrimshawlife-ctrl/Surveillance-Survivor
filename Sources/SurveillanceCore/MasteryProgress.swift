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

    public static var initial: MasteryProgress {
        MasteryProgress(
            runHistory: [],
            challengeCompletions: [:],
            totalRuns: 0,
            totalExtractions: 0,
            dailyBestStreak: 0,
            currentDailyStreak: 0,
            lastDailyDayKey: nil
        )
    }

    public init(
        runHistory: [RunHistoryEntry],
        challengeCompletions: [String: Int],
        totalRuns: Int,
        totalExtractions: Int,
        dailyBestStreak: Int,
        currentDailyStreak: Int,
        lastDailyDayKey: String?
    ) {
        self.runHistory = runHistory
        self.challengeCompletions = challengeCompletions
        self.totalRuns = totalRuns
        self.totalExtractions = totalExtractions
        self.dailyBestStreak = dailyBestStreak
        self.currentDailyStreak = currentDailyStreak
        self.lastDailyDayKey = lastDailyDayKey
    }

    /// Record a finished run. Caps history; never applies permanent damage/HP inflation.
    public mutating func record(
        entry: RunHistoryEntry,
        historyCap: Int = Self.defaultHistoryCap
    ) {
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
        copy.currentDailyStreak = max(0, min(currentDailyStreak, dailyBestStreak == 0 ? currentDailyStreak : max(dailyBestStreak, currentDailyStreak)))
        if copy.runHistory.count > historyCap {
            copy.runHistory = Array(copy.runHistory.prefix(historyCap))
        }
        copy.challengeCompletions = challengeCompletions.filter { $0.value > 0 }
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
