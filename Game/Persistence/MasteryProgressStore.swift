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
        // Unsupported schema payloads must stay byte-intact so an upgrade can read them again.
        // Session memory may still advance; we just refuse to clobber the stored envelope.
        if shouldPreserveStoredPayload {
            return
        }
        let record = MasteryProgressRecord(schemaVersion: Self.currentSchemaVersion, progress: sanitized)
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
    func recordReceipt(_ receipt: RunReceipt, finishedAt: String = ISO8601DateFormatter().string(from: Date())) -> MasteryProgress {
        var updated = progress
        updated.record(entry: RunHistoryEntry.fromReceipt(receipt, finishedAt: finishedAt))
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

    static func decodeProgress(from data: Data) -> (progress: MasteryProgress, diagnostic: String?) {
        // Read the envelope version before its payload. A future envelope can
        // legitimately contain progress fields this build does not understand;
        // decoding the full record first would misclassify it as corruption and
        // let a subsequent save overwrite data meant for a newer build.
        if let envelope = try? JSONDecoder().decode(MasteryProgressEnvelopeVersion.self, from: data) {
            if envelope.schemaVersion > currentSchemaVersion {
                return (.initial, "unsupported-future-schema-\(envelope.schemaVersion)")
            }
            if envelope.schemaVersion < 1 {
                return (.initial, "unsupported-past-schema-\(envelope.schemaVersion)")
            }
        }
        if let record = try? JSONDecoder().decode(MasteryProgressRecord.self, from: data) {
            if record.schemaVersion > currentSchemaVersion {
                return (.initial, "unsupported-future-schema-\(record.schemaVersion)")
            }
            if record.schemaVersion < 1 {
                return (.initial, "unsupported-past-schema-\(record.schemaVersion)")
            }
            return (
                record.progress.sanitized(),
                record.schemaVersion == currentSchemaVersion
                    ? nil
                    : "compatible-decode-from-\(record.schemaVersion)"
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

/// Minimal probe used to preserve unsupported envelopes even when their
/// payload is unreadable to this build.
private struct MasteryProgressEnvelopeVersion: Decodable {
    var schemaVersion: Int
}
