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
    #expect(exit.state.timeInsideSeconds == 0)
    #expect(exit.state.firedHazardKinds.isEmpty)
    #expect(exit.events.contains { $0.kind == "exited" })
    #expect(exit.suspicionNudgePerSecond == 0)
}

@Test func landmarkDwellResetsAcrossSeparateVisits() {
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    let firstHazard = encounter.hazardSchedule[0]
    var state = LandmarkEncounterState.idle
    state.isPlayerInside = true
    state.activeEncounterId = encounter.id
    state.timeInsideSeconds = max(0, firstHazard.atElapsedSeconds - 0.5)
    state.firedHazardKinds = []

    let exit = LandmarkEncounterEngine.evaluate(
        district: .wichita,
        playerPosition: encounter.center + Vector2(x: encounter.radius + 40, y: 0),
        elapsed: 10,
        tick: 1,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(!exit.state.isPlayerInside)
    #expect(exit.state.timeInsideSeconds == 0)

    let reenter = LandmarkEncounterEngine.evaluate(
        district: .wichita,
        playerPosition: encounter.center,
        elapsed: 11,
        tick: 2,
        fixedStep: 1.0 / 60.0,
        state: exit.state
    )
    #expect(reenter.state.isPlayerInside)
    #expect(reenter.state.timeInsideSeconds < 1)
    #expect(reenter.events.filter { $0.kind == "hazard" }.isEmpty)
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

@Test func landmarkSameKindHazardsInSameIntegerSecondBothFire() throws {
    // Former Int(atElapsedSeconds) keys would collide for 10.1 and 10.9.
    let payload = """
    {
      "schemaVersion": 1,
      "schemaId": "surveillance-survivor/landmark_encounters",
      "forbidHiddenStatScaling": true,
      "encounters": [
        {
          "id": "wichita_big_box_anchor",
          "districtId": "wichita",
          "displayName": "Big-Box Anchor Lot",
          "center": { "x": 0, "y": 0 },
          "radius": 160,
          "topologyGrammar": "radial_lots_with_anchor",
          "linkedInteractableIds": [
            "wichita_lot_transformer",
            "wichita_sensor_junction",
            "wichita_exit_boom"
          ],
          "hazardSchedule": [
            {
              "atElapsedSeconds": 10.1,
              "kind": "pressurePulse",
              "observationPressureBonus": 0.05,
              "guardTargetDelta": 0
            },
            {
              "atElapsedSeconds": 10.9,
              "kind": "pressurePulse",
              "observationPressureBonus": 0.04,
              "guardTargetDelta": 1
            }
          ],
          "whileInside": {
            "guardTargetDelta": 1,
            "observationPressureBonus": 0.08,
            "spawnIntervalMultiplier": 0.92
          },
          "bossHooks": {
            "nudgeSuspicionPerSecondWhileInside": 0.15,
            "minimumTierRaw": 3
          },
          "audioMotifId": "wichita_lot_hum",
          "artPackageId": "wichita_foundation",
          "opportunity": "anchor_cover_lanes",
          "cost": "concentrated_lpr_coverage"
        }
      ]
    }
    """.data(using: .utf8)!
    let catalog = try JSONDecoder().decode(LandmarkEncounterCatalog.self, from: payload)
    try catalog.validate()
    let encounter = try #require(catalog.primary(for: .wichita))

    var state = LandmarkEncounterState.idle
    state.isPlayerInside = true
    state.activeEncounterId = encounter.id
    state.timeInsideSeconds = 10.1 - (1.0 / 60.0)
    state.appliedGuardTargetDelta = encounter.whileInside.guardTargetDelta
    state.appliedObservationBonus = encounter.whileInside.observationPressureBonus

    let mid = LandmarkEncounterEngine.evaluate(
        catalog: catalog,
        district: .wichita,
        playerPosition: encounter.center,
        elapsed: 11,
        tick: 1,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(mid.events.filter { $0.kind == "hazard" }.count == 1)

    state = mid.state
    state.timeInsideSeconds = 10.9 - (1.0 / 60.0)
    let both = LandmarkEncounterEngine.evaluate(
        catalog: catalog,
        district: .wichita,
        playerPosition: encounter.center,
        elapsed: 12,
        tick: 2,
        fixedStep: 1.0 / 60.0,
        state: state
    )
    #expect(both.events.filter { $0.kind == "hazard" }.count == 1)
    #expect(both.state.firedHazardKinds.count == 2)
    #expect(both.state.appliedGuardTargetDelta == encounter.whileInside.guardTargetDelta + 1)
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
    #expect(receipt.schemaVersion == 11)
    #expect(!receipt.landmarkEvents.isEmpty)
    #expect(receipt.landmarkEvents.contains { $0.kind == "entered" })
    #expect(receipt.landmarkEncounter?.isPlayerInside == true)
    #expect(
        receipt.eventSequence.contains { $0.event.kind == .landmarkEncounterChanged }
    )
}

@Test func landmarkSuspicionFloorEmitsTierChangedEvent() {
    var state = RunState(seed: 55, district: .wichita)
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    #expect(encounter.bossHooks.minimumTierRaw > 0)
    state.suspicion = 0
    state.suspicionTier = .backgroundNoise
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].position = encounter.center
        state.entities[playerIndex].health = 1_000_000
    }
    // Keep cameras far so updateSuspicion cannot escalate before the floor.
    for index in state.entities.indices where state.entities[index].kind == .cameraPole {
        state.entities[index].position = .init(x: 10_000, y: 10_000)
    }
    var simulation = Simulation(state: state, rngSeed: 55)
    let events = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.state.suspicionTier.rawValue >= encounter.bossHooks.minimumTierRaw)
    #expect(events.contains { $0.kind == .tierChanged })
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
