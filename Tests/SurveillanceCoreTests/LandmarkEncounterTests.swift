import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledLandmarkEncountersValidate() throws {
    let catalog = try LandmarkEncounterCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(catalog.primary(for: .wichita) != nil)
    try catalog.validate()
}

@Test func landmarkEnterExitAppliesPressureLevers() {
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    var state = LandmarkEncounterState.idle
    let enter = LandmarkEncounterEngine.evaluate(
        district: .wichita,
        playerPosition: encounter.center,
        elapsed: 1,
        tick: 60,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(enter.state.isPlayerInside)
    #expect(enter.state.appliedGuardTargetDelta == encounter.whileInside.guardTargetDelta)
    #expect(enter.state.appliedObservationBonus == encounter.whileInside.observationPressureBonus)
    #expect(enter.events.contains { $0.kind == "entered" })
    #expect(enter.suspicionNudgePerSecond > 0)

    state = enter.state
    let exit = LandmarkEncounterEngine.evaluate(
        district: .wichita,
        playerPosition: encounter.center + Vector2(x: encounter.radius + 40, y: 0),
        elapsed: 2,
        tick: 120,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(!exit.state.isPlayerInside)
    #expect(exit.state.appliedGuardTargetDelta == 0)
    #expect(exit.state.appliedSpawnIntervalMultiplier == 1)
    #expect(exit.events.contains { $0.kind == "exited" })
    #expect(exit.suspicionNudgePerSecond == 0)
}

@Test func landmarkHazardFiresAfterDwellTime() {
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    let firstHazard = encounter.hazardSchedule[0]
    var state = LandmarkEncounterState.idle
    // Already inside with dwell just under the first hazard threshold.
    state.isPlayerInside = true
    state.activeEncounterId = encounter.id
    state.enteredElapsed = 0
    state.timeInsideSeconds = max(0, firstHazard.atElapsedSeconds - 1.0)
    state.appliedGuardTargetDelta = encounter.whileInside.guardTargetDelta
    state.appliedObservationBonus = encounter.whileInside.observationPressureBonus
    state.appliedSpawnIntervalMultiplier = encounter.whileInside.spawnIntervalMultiplier

    let before = LandmarkEncounterEngine.evaluate(
        district: .wichita,
        playerPosition: encounter.center,
        elapsed: state.timeInsideSeconds,
        tick: 1,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(before.events.filter { $0.kind == "hazard" }.isEmpty)
    #expect(before.state.timeInsideSeconds < firstHazard.atElapsedSeconds)

    // Jump dwell past the hazard gate without relying on fixed-step accumulation alone.
    state = before.state
    state.timeInsideSeconds = firstHazard.atElapsedSeconds
    let after = LandmarkEncounterEngine.evaluate(
        district: .wichita,
        playerPosition: encounter.center,
        elapsed: firstHazard.atElapsedSeconds + 1,
        tick: 2,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(after.events.contains { $0.kind == "hazard" })
    #expect(after.state.appliedObservationBonus >= encounter.whileInside.observationPressureBonus)
}

@Test func landmarkDoesNotCoverDefaultPlayerSpawn() {
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    let spawn = DistrictID.wichita.profile.playerSpawn
    let distance = (spawn - encounter.center).magnitude
    #expect(distance > encounter.radius)
}

@Test func simulationLandmarkEmitsReceiptEvents() {
    var state = RunState(seed: 33, district: .wichita)
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].position = encounter.center
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 33)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 9)
    #expect(!receipt.landmarkEvents.isEmpty)
    #expect(receipt.landmarkEvents.contains { $0.kind == "entered" })
    #expect(receipt.landmarkEncounter?.isPlayerInside == true)
    #expect(
        receipt.eventSequence.contains { $0.event.kind == .landmarkEncounterChanged }
    )
}

@Test func landmarkEvaluationIsSeedDeterministic() {
    func run() -> RunReceipt {
        var state = RunState(seed: 44, district: .wichita)
        let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
        if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
            state.entities[playerIndex].position = encounter.center
            state.entities[playerIndex].health = 1_000_000
        }
        var simulation = Simulation(state: state, rngSeed: 44)
        for _ in 0..<120 {
            _ = simulation.step(input: .init(autoFireEnabled: false))
        }
        return simulation.runReceipt()
    }
    #expect(run() == run())
}
