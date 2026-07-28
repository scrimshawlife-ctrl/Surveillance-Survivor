import Foundation
import SurveillanceCore

/// Explicit receipt migration boundary. Additive schemas currently decode without
/// transforms; incompatible future versions must add fixture-tested steps here
/// before bumping `compatibility.run_receipt.compatibility_version`.
enum RunReceiptMigration {
    /// Oldest envelope schema still accepted for compatible decode.
    static let minimumSupportedSchema = 1
    static let currentSchema = RunReceipt.schemaVersion

    enum MigrationError: Error, Equatable, Sendable {
        case unsupportedPast(Int)
        case unsupportedFuture(Int)
    }

    /// Apply version-specific transforms. Identity for all currently supported
    /// additive schemas (1...current). Returns a diagnostic token describing
    /// whether a real migration ran or only a compatible decode.
    static func migrate(
        from schemaVersion: Int,
        receipt: DeviceRunReceipt
    ) throws -> (receipt: DeviceRunReceipt, diagnostic: String?) {
        if schemaVersion < minimumSupportedSchema {
            throw MigrationError.unsupportedPast(schemaVersion)
        }
        if schemaVersion > currentSchema {
            throw MigrationError.unsupportedFuture(schemaVersion)
        }
        if schemaVersion == currentSchema {
            return (receipt, nil)
        }
        // No incompatible transforms exist yet between 1...12. Additive v12
        // boss phase samples decode as an empty list for older receipts.
        // "migrated-from-\(schemaVersion)" only after a real transform.
        var current = receipt
        for version in schemaVersion..<currentSchema {
            current = try migrateStep(from: version, receipt: current)
        }
        // Identity steps above → compatible decode, not a migration event.
        return (current, "compatible-decode-from-\(schemaVersion)")
    }

    private static func migrateStep(
        from schemaVersion: Int,
        receipt: DeviceRunReceipt
    ) throws -> DeviceRunReceipt {
        // Reserved for incompatible envelope/payload evolution.
        // Example:
        // case 11: return migrateV11toV12(receipt)
        _ = schemaVersion
        return receipt
    }
}

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
        if lastLoadDiagnostic?.hasPrefix("compatible-") == true
            || lastLoadDiagnostic?.hasPrefix("migrated-") == true
        {
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
        // Read the envelope version before its payload. A future envelope can
        // legitimately contain receipt fields this build does not understand;
        // decoding the full record first would misclassify it as corruption and
        // let a subsequent save overwrite data meant for a newer build.
        if let envelope = try? JSONDecoder().decode(ReceiptEnvelopeVersion.self, from: data) {
            if envelope.schemaVersion > RunReceiptMigration.currentSchema {
                return (nil, "unsupported-future-schema-\(envelope.schemaVersion)")
            }
            if envelope.schemaVersion < RunReceiptMigration.minimumSupportedSchema {
                return (nil, "unsupported-past-schema-\(envelope.schemaVersion)")
            }
        }
        if let record = try? JSONDecoder().decode(DeviceRunReceiptRecord.self, from: data) {
            do {
                let migrated = try RunReceiptMigration.migrate(
                    from: record.schemaVersion,
                    receipt: record.receipt
                )
                return (migrated.receipt, migrated.diagnostic)
            } catch RunReceiptMigration.MigrationError.unsupportedFuture(let version) {
                return (nil, "unsupported-future-schema-\(version)")
            } catch RunReceiptMigration.MigrationError.unsupportedPast(let version) {
                return (nil, "unsupported-past-schema-\(version)")
            } catch {
                return (nil, "corrupt-or-unreadable")
            }
        }
        // Legacy: bare DeviceRunReceipt (pre-envelope).
        if let legacy = try? JSONDecoder().decode(DeviceRunReceipt.self, from: data) {
            return (legacy, "compatible-legacy-bare-receipt")
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

/// Minimal probe used to preserve unsupported envelopes even when their
/// payload is unreadable to this build.
private struct ReceiptEnvelopeVersion: Decodable {
    var schemaVersion: Int
}
