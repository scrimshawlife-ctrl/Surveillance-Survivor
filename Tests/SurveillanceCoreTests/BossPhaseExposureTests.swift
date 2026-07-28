import Foundation
import Testing
@testable import SurveillanceCore

private let phaseDistricts: [DistrictID] = [
    .sanFrancisco, .columbus, .newYorkCity, .losAngeles, .atlanta
]

@Test func authoredBossPhasesResolveEveryHealthBand() {
    let expectedCounts: [DistrictID: Int] = [
        .sanFrancisco: 4, .columbus: 4, .newYorkCity: 6, .losAngeles: 5, .atlanta: 6
    ]
    for district in phaseDistricts {
        let maximum = BossCatalog.bundled.shiftManagerHealth * district.profile.bossHealthMultiplier
        let phases = stride(from: maximum, through: maximum * 0.01, by: -maximum / 120)
            .compactMap { BossPhase.resolve(district: district, health: $0, maximumHealth: maximum) }
        #expect(Set(phases.map(\.id)).count == expectedCounts[district])
        #expect(phases.first?.ordinal == 0)
        #expect(phases.last?.ordinal == (expectedCounts[district] ?? 0) - 1)
    }
}

@Test func bossActivationEmitsAndReceiptsAuthoritativeInitialPhaseForEveryAuthoredCity() {
    for district in phaseDistricts {
        var state = RunState(seed: 0xB055, district: district)
        state.suspicion = 100
        state.suspicionTier = .totalVisibility
        state.activeWeapons = []
        state.entities.removeAll { $0.kind != .player }
        state.entities[0].health = 1_000_000
        var simulation = Simulation(state: state, rngSeed: state.seed)

        let events = simulation.step(input: .init(autoFireEnabled: false))
        let phase = simulation.state.bossPhase
        let receipt = simulation.runReceipt()

        #expect(events.contains { $0.kind == .bossActivated })
        #expect(events.contains { $0.kind == .bossPhaseChanged })
        #expect(phase?.district == district)
        #expect(phase?.ordinal == 0)
        #expect(receipt.bossPhaseEvents == phase.map { [.init(tick: 1, phase: $0)] } ?? [])
        #expect(receipt.eventSequence.contains { $0.event.kind == .bossPhaseChanged })
    }
}

@Test func versionElevenReceiptDecodesWithEmptyBossPhaseSamples() throws {
    let receipt = Simulation(seed: 7).runReceipt()
    var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(receipt)) as? [String: Any])
    object["schemaVersion"] = 11
    object.removeValue(forKey: "bossPhaseEvents")

    let decoded = try JSONDecoder().decode(
        RunReceipt.self,
        from: JSONSerialization.data(withJSONObject: object)
    )

    #expect(decoded.schemaVersion == 12)
    #expect(decoded.bossPhaseEvents.isEmpty)
}
