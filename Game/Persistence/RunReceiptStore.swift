import Foundation
import SurveillanceCore

/// Persists the latest completed device run receipt offline.
///
/// Storage contract (schema matches `RunReceipt.schemaVersion`): JSON
/// `DeviceRunReceiptRecord` under `surveillance.latestRunReceipt`. Legacy bare
/// `DeviceRunReceipt` payloads are still accepted and rewritten on the next save.
final class RunReceiptStore {
    static let storageKey = "surveillance.latestRunReceipt"
    static let currentSchemaVersion = RunReceipt.schemaVersion

    private let defaults: UserDefaults
    private(set) var latest: DeviceRunReceipt?
    private(set) var lastLoadDiagnostic: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let loaded = Self.load(from: defaults)
        latest = loaded.receipt
        lastLoadDiagnostic = loaded.diagnostic
    }

    func save(_ receipt: DeviceRunReceipt) {
        // Unsupported schema payloads must stay byte-intact so an upgrade can read them again.
        if shouldPreserveStoredPayload {
            return
        }
        let record = DeviceRunReceiptRecord(
            schemaVersion: Self.currentSchemaVersion,
            receipt: receipt
        )
        guard let data = try? JSONEncoder().encode(record) else {
            lastLoadDiagnostic = "encode-failed"
            return
        }
        defaults.set(data, forKey: Self.storageKey)
        latest = receipt
        if lastLoadDiagnostic?.hasPrefix("migrated-") == true {
            lastLoadDiagnostic = nil
        }
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
    static func decodeReceipt(from data: Data) -> (receipt: DeviceRunReceipt?, diagnostic: String?) {
        if let record = try? JSONDecoder().decode(DeviceRunReceiptRecord.self, from: data) {
            if record.schemaVersion > currentSchemaVersion {
                return (nil, "unsupported-future-schema-\(record.schemaVersion)")
            }
            if record.schemaVersion < 1 {
                return (nil, "unsupported-past-schema-\(record.schemaVersion)")
            }
            let diagnostic = record.schemaVersion == currentSchemaVersion
                ? nil
                : "migrated-from-\(record.schemaVersion)"
            return (record.receipt, diagnostic)
        }
        // Legacy: bare DeviceRunReceipt (pre-envelope).
        if let legacy = try? JSONDecoder().decode(DeviceRunReceipt.self, from: data) {
            return (legacy, "migrated-legacy-bare-receipt")
        }
        return (nil, "corrupt-or-unreadable")
    }

    private static func load(from defaults: UserDefaults) -> (receipt: DeviceRunReceipt?, diagnostic: String?) {
        guard let data = defaults.data(forKey: storageKey) else {
            return (nil, nil)
        }
        return decodeReceipt(from: data)
    }
}

/// Versioned persistence envelope for the latest device run receipt.
struct DeviceRunReceiptRecord: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var receipt: DeviceRunReceipt
}
