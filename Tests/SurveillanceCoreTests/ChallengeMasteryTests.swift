import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledChallengeContractsValidate() throws {
    let catalog = try ChallengeContractCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(catalog.contracts.count >= 3)
    #expect(!catalog.contracts(kind: "daily").isEmpty)
    #expect(!catalog.contracts(kind: "weekly").isEmpty)
    try catalog.validate()
    // Label-only mutators must appear on at least one contract.
    let kinds = Set(catalog.contracts.flatMap { $0.mutators.map(\.kind) })
    #expect(kinds.contains("radioLanguageOverride") || kinds.contains("weatherLightingOverride"))
}

@Test func challengePresentationOverridesResolveFromContracts() {
    let catalog = ChallengeContractCatalog.bundled
    #expect(catalog.contract(id: "quiet_watch")?.radioLanguageOverride == "zoning_corridor_dispatch")
    #expect(catalog.contract(id: "paper_mandate")?.weatherLightingOverride == "civic_plaza_fluorescent")
    #expect(catalog.contract(id: "signal_storm")?.audioMotifOverride == "wichita_lot_hum")
    let cal = ChallengeResolver.utcCalendar
    let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 25))!
    let daily = ChallengeResolver.daily(for: date)
    // Instance carries whatever contract the day resolved to — overrides optional.
    if let contract = catalog.contract(id: daily.contractId) {
        #expect(daily.radioLanguageOverride == contract.radioLanguageOverride)
        #expect(daily.weatherLightingOverride == contract.weatherLightingOverride)
        #expect(daily.audioMotifOverride == contract.audioMotifOverride)
    }
}

@Test func dailyChallengeIsDeterministicForDayKey() {
    let cal = ChallengeResolver.utcCalendar
    let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 25))!
    let a = ChallengeResolver.daily(for: date)
    let b = ChallengeResolver.daily(for: date)
    #expect(a == b)
    #expect(a.kind == "daily")
    #expect(a.dayKey == "2026-07-25")
    #expect(a.seed != 0)
    #expect(ChallengeContractCatalog.bundled.contract(id: a.contractId) != nil)
}

@Test func weeklyChallengeDiffersFromDailyAndIsStable() {
    let cal = ChallengeResolver.utcCalendar
    let date = cal.date(from: DateComponents(year: 2026, month: 7, day: 25))!
    let daily = ChallengeResolver.daily(for: date)
    let weekly = ChallengeResolver.weekly(for: date)
    #expect(weekly.kind == "weekly")
    #expect(weekly.dayKey.contains("W"))
    #expect(weekly.seed != daily.seed || weekly.contractId != daily.contractId || weekly.districtId != daily.districtId)
    #expect(ChallengeResolver.weekly(for: date) == weekly)
}

@Test func challengeSimulationRecordsContextOnReceipt() {
    let cal = ChallengeResolver.utcCalendar
    let date = cal.date(from: DateComponents(year: 2026, month: 3, day: 1))!
    let challenge = ChallengeResolver.daily(for: date)
    var simulation = Simulation(seed: 1, district: .wichita, challenge: challenge)
    for _ in 0..<30 {
        _ = simulation.step(input: .init(autoFireEnabled: false))
    }
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 11)
    #expect(receipt.challenge == challenge)
    #expect(receipt.district == challenge.districtId)
    #expect(receipt.seed == challenge.seed)
}

@Test func masteryRecordsHistoryAndDailyStreak() {
    var mastery = MasteryProgress.initial
    let entry1 = RunHistoryEntry(
        finishedAt: "2026-07-24T12:00:00Z",
        seed: 1,
        districtId: .wichita,
        extractionCompleted: true,
        elapsedSeconds: 100,
        selectedUpgrades: ["signalFlood"],
        challengeKind: "daily",
        challengeContractId: "quiet_watch",
        challengeDayKey: "2026-07-24"
    )
    let entry2 = RunHistoryEntry(
        finishedAt: "2026-07-25T12:00:00Z",
        seed: 2,
        districtId: .louisville,
        extractionCompleted: true,
        elapsedSeconds: 110,
        selectedUpgrades: ["mirrorArray"],
        challengeKind: "daily",
        challengeContractId: "signal_storm",
        challengeDayKey: "2026-07-25"
    )
    mastery.record(entry: entry1)
    mastery.record(entry: entry2)
    #expect(mastery.totalRuns == 2)
    #expect(mastery.totalExtractions == 2)
    #expect(mastery.currentDailyStreak == 2)
    #expect(mastery.dailyBestStreak == 2)
    #expect(mastery.challengeCompletions["quiet_watch"] == 1)
    #expect(mastery.runHistory.count == 2)
    #expect(MasteryProgress.isConsecutiveDay(previous: "2026-07-24", current: "2026-07-25"))
}

@Test func masteryHistoryCapIsEnforced() {
    var mastery = MasteryProgress.initial
    for i in 0..<50 {
        mastery.record(
            entry: RunHistoryEntry(
                finishedAt: "t\(i)",
                seed: UInt64(i),
                districtId: .wichita,
                extractionCompleted: false,
                elapsedSeconds: 1,
                selectedUpgrades: []
            ),
            historyCap: 10
        )
    }
    #expect(mastery.runHistory.count == 10)
    #expect(mastery.totalRuns == 50)
}

@Test func runHistoryEntryFromReceiptCarriesChallenge() {
    let cal = ChallengeResolver.utcCalendar
    let date = cal.date(from: DateComponents(year: 2026, month: 1, day: 15))!
    let challenge = ChallengeResolver.weekly(for: date)
    var simulation = Simulation(seed: 9, challenge: challenge)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let entry = RunHistoryEntry.fromReceipt(simulation.runReceipt(), finishedAt: "now")
    #expect(entry.challengeKind == "weekly")
    #expect(entry.challengeContractId == challenge.contractId)
    #expect(entry.challengeDayKey == challenge.dayKey)
    #expect(entry.districtId == challenge.districtId)
}
