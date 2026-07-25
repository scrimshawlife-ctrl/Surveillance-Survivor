import Foundation
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test func masteryProgressStoreRoundTripsHistory() {
    let suiteName = "MasteryProgressStoreTests-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let store = MasteryProgressStore(defaults: defaults)
    #expect(store.progress.totalRuns == 0)

    var sim = Simulation(seed: 7, district: .wichita, challenge: ChallengeResolver.daily(
        for: ChallengeResolver.utcCalendar.date(from: DateComponents(year: 2026, month: 7, day: 25))!
    ))
    _ = sim.step(input: .init(autoFireEnabled: false))
    let receipt = sim.runReceipt()
    let updated = store.recordReceipt(receipt, finishedAt: "2026-07-25T12:00:00Z")
    #expect(updated.totalRuns == 1)
    #expect(updated.runHistory.first?.challengeKind == "daily")
    #expect(updated.runHistory.first?.districtId == receipt.district)

    let reloaded = MasteryProgressStore(defaults: defaults)
    #expect(reloaded.progress.totalRuns == 1)
    #expect(reloaded.progress.runHistory.count == 1)
    #expect(reloaded.lastLoadDiagnostic == nil)
}

@Test func masteryProgressStoreFailsClosedOnCorruptData() {
    let suiteName = "MasteryProgressStoreCorrupt-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    defaults.set(Data("not-json{{{".utf8), forKey: MasteryProgressStore.storageKey)
    let store = MasteryProgressStore(defaults: defaults)
    #expect(store.progress == .initial)
    #expect(store.lastLoadDiagnostic == "corrupt-or-unreadable")
}

@Test func masteryProgressStoreRejectsFutureSchema() throws {
    let suiteName = "MasteryProgressStoreFuture-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let future = MasteryProgressRecord(schemaVersion: 99, progress: .initial)
    defaults.set(try JSONEncoder().encode(future), forKey: MasteryProgressStore.storageKey)
    let store = MasteryProgressStore(defaults: defaults)
    #expect(store.progress == .initial)
    #expect(store.lastLoadDiagnostic == "unsupported-future-schema-99")
}
