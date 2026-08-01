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

    let corruptData = Data("not-json{{{".utf8)
    defaults.set(corruptData, forKey: MasteryProgressStore.storageKey)
    let store = MasteryProgressStore(defaults: defaults)
    #expect(store.progress == .initial)
    #expect(store.lastLoadDiagnostic == "corrupt-or-unreadable")
    #expect(!store.shouldPreserveStoredPayload)

    store.save(.initial)
    #expect(defaults.data(forKey: MasteryProgressStore.storageKey) != corruptData)
    let reloaded = MasteryProgressStore(defaults: defaults)
    #expect(reloaded.progress == .initial)
    #expect(reloaded.lastLoadDiagnostic == nil)
}

@Test func masteryProgressStoreRejectsFutureSchema() throws {
    let suiteName = "MasteryProgressStoreFuture-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    var rich = MasteryProgress.initial
    rich.record(entry: RunHistoryEntry(
        finishedAt: "2026-07-25T12:00:00Z",
        seed: 9,
        districtId: .atlanta,
        extractionCompleted: true,
        elapsedSeconds: 120,
        selectedUpgrades: ["signalFlood"],
        challengeKind: "daily",
        challengeContractId: "quiet_watch",
        challengeDayKey: "2026-07-25"
    ))
    let future = MasteryProgressRecord(schemaVersion: 99, progress: rich)
    let futureData = try JSONEncoder().encode(future)
    defaults.set(futureData, forKey: MasteryProgressStore.storageKey)
    let store = MasteryProgressStore(defaults: defaults)
    #expect(store.progress == .initial)
    #expect(store.lastLoadDiagnostic == "unsupported-future-schema-99")
    #expect(store.shouldPreserveStoredPayload)

    var sim = Simulation(seed: 7, district: .wichita)
    _ = sim.step(input: .init(autoFireEnabled: false))
    _ = store.recordReceipt(sim.runReceipt(), finishedAt: "2026-07-26T12:00:00Z")
    #expect(defaults.data(forKey: MasteryProgressStore.storageKey) == futureData)
    #expect(store.progress.totalRuns == 1)
}

@Test func masteryProgressStorePreservesStructurallyIncompatibleFuturePayload() {
    let suiteName = "MasteryProgressStoreFutureUnreadable-\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let futureData = Data("{\"schemaVersion\":99,\"progress\":{\"futureRequiredField\":true}}".utf8)
    defaults.set(futureData, forKey: MasteryProgressStore.storageKey)

    let store = MasteryProgressStore(defaults: defaults)
    #expect(store.progress == .initial)
    #expect(store.lastLoadDiagnostic == "unsupported-future-schema-99")
    #expect(store.shouldPreserveStoredPayload)

    var sim = Simulation(seed: 8, district: .wichita)
    _ = sim.step(input: .init(autoFireEnabled: false))
    _ = store.recordReceipt(sim.runReceipt(), finishedAt: "2026-07-27T12:00:00Z")
    #expect(defaults.data(forKey: MasteryProgressStore.storageKey) == futureData)
    #expect(store.progress.totalRuns == 1)
}
