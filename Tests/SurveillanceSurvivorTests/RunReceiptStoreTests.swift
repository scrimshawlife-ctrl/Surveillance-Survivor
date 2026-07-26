import Foundation
import SurveillanceCore
import Testing
@testable import SurveillanceSurvivor

@Test func receiptStoreRoundTripsTheCompletedDeviceReceipt() {
    let suiteName = "RunReceiptStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var simulation = Simulation(seed: 44)
    for _ in 0..<60 { _ = simulation.step(input: .init()) }
    let receipt = DeviceRunReceipt(
        core: simulation.runReceipt(),
        frameTimes: [0.016, 0.020],
        frameTimeSummary: .init(sampleCount: 2, p50: 0.016, p95: 0.020, maximum: 0.020)
    )

    let firstStore = RunReceiptStore(defaults: defaults)
    firstStore.save(receipt)
    let reloadedStore = RunReceiptStore(defaults: defaults)

    #expect(reloadedStore.latest == receipt)
    #expect(reloadedStore.lastLoadDiagnostic == nil)
}

@Test func receiptStoreMigratesLegacyBareReceiptPayload() throws {
    let suiteName = "RunReceiptStoreLegacy-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var simulation = Simulation(seed: 45)
    for _ in 0..<30 { _ = simulation.step(input: .init()) }
    let receipt = DeviceRunReceipt(
        core: simulation.runReceipt(),
        frameTimes: [0.017],
        frameTimeSummary: .init(sampleCount: 1, p50: 0.017, p95: 0.017, maximum: 0.017)
    )
    let bare = try JSONEncoder().encode(receipt)
    defaults.set(bare, forKey: RunReceiptStore.storageKey)

    let store = RunReceiptStore(defaults: defaults)
    #expect(store.latest == receipt)
    #expect(store.lastLoadDiagnostic == "compatible-legacy-bare-receipt")

    // Next save rewrites the versioned envelope.
    store.save(receipt)
    let reloaded = RunReceiptStore(defaults: defaults)
    #expect(reloaded.latest == receipt)
    #expect(reloaded.lastLoadDiagnostic == nil)
}

@Test func receiptStoreRejectsFutureSchemaWithoutClobbering() throws {
    let suiteName = "RunReceiptStoreFuture-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var simulation = Simulation(seed: 46)
    _ = simulation.step(input: .init())
    let receipt = DeviceRunReceipt(
        core: simulation.runReceipt(),
        frameTimes: [],
        frameTimeSummary: .empty
    )
    let future = DeviceRunReceiptRecord(schemaVersion: 99, receipt: receipt)
    let futureData = try JSONEncoder().encode(future)
    defaults.set(futureData, forKey: RunReceiptStore.storageKey)

    let store = RunReceiptStore(defaults: defaults)
    #expect(store.latest == nil)
    #expect(store.lastLoadDiagnostic == "unsupported-future-schema-99")
    #expect(store.shouldPreserveStoredPayload)

    store.save(receipt)
    #expect(defaults.data(forKey: RunReceiptStore.storageKey) == futureData)
}

@Test func receiptStoreAcceptsOlderCompatibleEnvelopeSchema() throws {
    let suiteName = "RunReceiptStoreOlder-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var simulation = Simulation(seed: 47)
    _ = simulation.step(input: .init())
    let receipt = DeviceRunReceipt(
        core: simulation.runReceipt(),
        frameTimes: [0.016],
        frameTimeSummary: .init(sampleCount: 1, p50: 0.016, p95: 0.016, maximum: 0.016)
    )
    let older = DeviceRunReceiptRecord(schemaVersion: 10, receipt: receipt)
    defaults.set(try JSONEncoder().encode(older), forKey: RunReceiptStore.storageKey)

    let store = RunReceiptStore(defaults: defaults)
    #expect(store.latest == receipt)
    #expect(store.lastLoadDiagnostic == "compatible-decode-from-10")
    #expect(!store.shouldPreserveStoredPayload)

    let migrated = try RunReceiptMigration.migrate(from: 10, receipt: receipt)
    #expect(migrated.receipt == receipt)
    #expect(migrated.diagnostic == "compatible-decode-from-10")
}

@Test func receiptStoreCorruptPayloadFailsClosedWithDiagnostic() {
    let suiteName = "RunReceiptStoreCorrupt-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    defaults.set(Data("not-json{{{".utf8), forKey: RunReceiptStore.storageKey)
    let store = RunReceiptStore(defaults: defaults)
    #expect(store.latest == nil)
    #expect(store.lastLoadDiagnostic == "corrupt-or-unreadable")
}
