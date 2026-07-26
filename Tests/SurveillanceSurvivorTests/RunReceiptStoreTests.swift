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
    #expect(store.lastLoadDiagnostic == "migrated-legacy-bare-receipt")

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

@Test func receiptStoreCorruptPayloadFailsClosedWithDiagnostic() {
    let suiteName = "RunReceiptStoreCorrupt-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    defaults.set(Data("not-json{{{".utf8), forKey: RunReceiptStore.storageKey)
    let store = RunReceiptStore(defaults: defaults)
    #expect(store.latest == nil)
    #expect(store.lastLoadDiagnostic == "corrupt-or-unreadable")
}
