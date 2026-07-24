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
        let record = CampaignProgressRecord(schemaVersion: Self.currentSchemaVersion, progress: sanitized)
        guard let data = try? JSONEncoder().encode(record) else {
            lastLoadDiagnostic = "encode-failed"
            return
        }
        defaults.set(data, forKey: Self.storageKey)
    }

    @discardableResult
    func applyRunOutcome(district: DistrictID, extractionCompleted: Bool) -> CampaignProgress {
        var updated = progress
        updated.recordRunOutcome(district: district, extractionCompleted: extractionCompleted)
        save(updated)
        return updated
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
    /// Clamp levels and drop unknown/duplicate district IDs after decode.
    func sanitized() -> CampaignProgress {
        let maxLevel = maxCampaignLevel
        let clampedHighest = min(max(1, highestUnlockedLevel), maxLevel)
        var seen = Set<DistrictID>()
        var completed: [DistrictID] = []
        for district in completedDistricts where district.definition.level <= maxLevel {
            if seen.insert(district).inserted {
                completed.append(district)
            }
        }
        let last = lastPlayedDistrict.flatMap { id -> DistrictID? in
            DistrictID(rawValue: id.rawValue)
        }
        return CampaignProgress(
            highestUnlockedLevel: clampedHighest,
            completedDistricts: completed,
            lastPlayedDistrict: last
        )
    }
}
