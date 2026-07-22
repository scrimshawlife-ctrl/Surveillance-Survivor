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
}
