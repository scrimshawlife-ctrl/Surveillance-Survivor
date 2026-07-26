import Foundation
import SurveillanceCore

/// Persists campaign unlocks offline. Simulation never reads this store.
///
/// Storage contract (schema 1): JSON `CampaignProgressRecord` under
/// `surveillance.campaignProgress`. Legacy bare `CampaignProgress` payloads
/// are still accepted and rewritten on the next save.
final class CampaignProgressStore {
    static let storageKey = "surveillance.campaignProgress"
    static let currentSchemaVersion = CampaignProgress.schemaVersion

    private let defaults: UserDefaults
    private(set) var progress: CampaignProgress
    private(set) var lastLoadDiagnostic: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loaded = Self.load(from: defaults)
        progress = loaded.progress
        lastLoadDiagnostic = loaded.diagnostic
    }

    func save(_ progress: CampaignProgress) {
        let sanitized = progress.sanitized()
        self.progress = sanitized
        // Unsupported schema payloads must stay byte-intact so an upgrade can read them again.
        // Session memory may still advance; we just refuse to clobber the stored envelope.
        if shouldPreserveStoredPayload {
            return
        }
        let record = CampaignProgressRecord(schemaVersion: Self.currentSchemaVersion, progress: sanitized)
        guard let data = try? JSONEncoder().encode(record) else {
            lastLoadDiagnostic = "encode-failed"
            return
        }
        defaults.set(data, forKey: Self.storageKey)
        if lastLoadDiagnostic?.hasPrefix("migrated-") == true {
            lastLoadDiagnostic = nil
        }
    }

    @discardableResult
    func applyRunOutcome(district: DistrictID, extractionCompleted: Bool) -> CampaignProgress {
        var updated = progress
        updated.recordRunOutcome(district: district, extractionCompleted: extractionCompleted)
        save(updated)
        return updated
    }

    /// True when defaults still hold an unreadably-new/old schema envelope we must not replace.
    var shouldPreserveStoredPayload: Bool {
        Self.preservesStoredPayload(diagnostic: lastLoadDiagnostic)
    }

    static func preservesStoredPayload(diagnostic: String?) -> Bool {
        guard let diagnostic else { return false }
        return diagnostic.hasPrefix("unsupported-future-schema")
            || diagnostic.hasPrefix("unsupported-past-schema")
    }

    /// Exposed for tests: interpret raw bytes without writing.
    static func decodeProgress(from data: Data) -> (progress: CampaignProgress, diagnostic: String?) {
        // Preferred: versioned envelope.
        if let record = try? JSONDecoder().decode(CampaignProgressRecord.self, from: data) {
            if record.schemaVersion > currentSchemaVersion {
                return (.initial, "unsupported-future-schema-\(record.schemaVersion)")
            }
            if record.schemaVersion < 1 {
                return (.initial, "unsupported-past-schema-\(record.schemaVersion)")
            }
            return (record.progress.sanitized(), record.schemaVersion == currentSchemaVersion ? nil : "migrated-from-\(record.schemaVersion)")
        }
        // Legacy: bare CampaignProgress.
        if let legacy = try? JSONDecoder().decode(CampaignProgress.self, from: data) {
            return (legacy.sanitized(), "migrated-legacy-bare-progress")
        }
        return (.initial, "corrupt-or-unreadable")
    }

    private static func load(from defaults: UserDefaults) -> (progress: CampaignProgress, diagnostic: String?) {
        guard let data = defaults.data(forKey: storageKey) else {
            return (.initial, nil)
        }
        return decodeProgress(from: data)
    }
}

/// Versioned persistence envelope for campaign unlocks.
struct CampaignProgressRecord: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var progress: CampaignProgress
}

extension CampaignProgress {
    /// Clamp levels, drop unknown/duplicate/skip-ahead district IDs, and repair the
    /// unlock frontier to `contiguousCompletedPrefix + 1` (campaign opener when empty).
    func sanitized() -> CampaignProgress {
        let maxLevel = maxCampaignLevel
        var seen = Set<DistrictID>()
        var completed: [DistrictID] = []
        for district in completedDistricts where (1...maxLevel).contains(district.definition.level) {
            if seen.insert(district).inserted {
                completed.append(district)
            }
        }
        let completedLevels = Set(completed.map(\.definition.level))
        var contiguousThrough = 0
        for level in 1...maxLevel {
            if completedLevels.contains(level) {
                contiguousThrough = level
            } else {
                break
            }
        }
        completed = completed.filter { $0.definition.level <= contiguousThrough }
        let repairedHighest = min(max(1, contiguousThrough + 1), maxLevel)
        let last = lastPlayedDistrict.flatMap { id -> DistrictID? in
            DistrictID(rawValue: id.rawValue)
        }
        return CampaignProgress(
            highestUnlockedLevel: repairedHighest,
            completedDistricts: completed,
            lastPlayedDistrict: last
        )
    }
}
