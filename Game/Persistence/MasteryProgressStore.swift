import Foundation
import SurveillanceCore

/// Persists mastery / run history offline. Simulation never reads this store.
///
/// Storage contract (schema 1): JSON `MasteryProgressRecord` under
/// `surveillance.masteryProgress`.
final class MasteryProgressStore {
    static let storageKey = "surveillance.masteryProgress"
    static let currentSchemaVersion = MasteryProgress.schemaVersion

    private let defaults: UserDefaults
    private(set) var progress: MasteryProgress
    private(set) var lastLoadDiagnostic: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loaded = Self.load(from: defaults)
        progress = loaded.progress
        lastLoadDiagnostic = loaded.diagnostic
    }

    func save(_ progress: MasteryProgress) {
        let sanitized = progress.sanitized()
        self.progress = sanitized
        let record = MasteryProgressRecord(schemaVersion: Self.currentSchemaVersion, progress: sanitized)
        guard let data = try? JSONEncoder().encode(record) else {
            lastLoadDiagnostic = "encode-failed"
            return
        }
        defaults.set(data, forKey: Self.storageKey)
    }

    @discardableResult
    func recordReceipt(_ receipt: RunReceipt, finishedAt: String = ISO8601DateFormatter().string(from: Date())) -> MasteryProgress {
        var updated = progress
        updated.record(entry: RunHistoryEntry.fromReceipt(receipt, finishedAt: finishedAt))
        save(updated)
        return updated
    }

    static func decodeProgress(from data: Data) -> (progress: MasteryProgress, diagnostic: String?) {
        if let record = try? JSONDecoder().decode(MasteryProgressRecord.self, from: data) {
            if record.schemaVersion > currentSchemaVersion {
                return (.initial, "unsupported-future-schema-\(record.schemaVersion)")
            }
            if record.schemaVersion < 1 {
                return (.initial, "unsupported-past-schema-\(record.schemaVersion)")
            }
            return (
                record.progress.sanitized(),
                record.schemaVersion == currentSchemaVersion ? nil : "migrated-from-\(record.schemaVersion)"
            )
        }
        if let legacy = try? JSONDecoder().decode(MasteryProgress.self, from: data) {
            return (legacy.sanitized(), "migrated-legacy-bare-mastery")
        }
        return (.initial, "corrupt-or-unreadable")
    }

    private static func load(from defaults: UserDefaults) -> (progress: MasteryProgress, diagnostic: String?) {
        guard let data = defaults.data(forKey: storageKey) else {
            return (.initial, nil)
        }
        return decodeProgress(from: data)
    }
}

struct MasteryProgressRecord: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var progress: MasteryProgress
}
