import Testing
@testable import SurveillanceCore

@Test func deterministicRunsMatch() {
    var first = Simulation(seed: 42)
    var second = Simulation(seed: 42)
    for _ in 0..<900 {
        _ = first.step(input: .init(movement: .init(x: 1, y: 0.25)))
        _ = second.step(input: .init(movement: .init(x: 1, y: 0.25)))
    }
    #expect(first.state == second.state)
}

@Test func playerMovementIsNormalized() {
    var simulation = Simulation(seed: 7)
    _ = simulation.step(input: .init(movement: .init(x: 10, y: 0)))
    let player = simulation.state.entities.first { $0.kind == .player }
    #expect((player?.position.x ?? 0) > 0)
}

@Test func suspicionEscalatesWithPopulation() {
    var simulation = Simulation(seed: 9)
    var peakSuspicion = 0.0
    for _ in 0..<3600 {
        _ = simulation.step(input: .init())
        peakSuspicion = max(peakSuspicion, simulation.state.suspicion)
    }
    #expect(peakSuspicion > 0)
}

@Test func parkingLotGenerationIsDeterministic() {
    let first = ParkingLotGenerator.generate(seed: 808)
    let second = ParkingLotGenerator.generate(seed: 808)
    #expect(first.layout == second.layout)
    #expect(first.cameras == second.cameras)
    #expect(first.layout.obstacles.count == 5)
    #expect(first.cameras.count == 4)
}

@Test func playerRemainsInsideWorldBounds() {
    var simulation = Simulation(seed: 11)
    for _ in 0..<2_000 {
        _ = simulation.step(input: .init(movement: .init(x: 1, y: 1)))
    }
    let player = simulation.state.entities.first { $0.kind == .player }!
    let bounds = simulation.state.world.bounds
    #expect(player.position.x <= bounds.maxX - player.radius)
    #expect(player.position.y <= bounds.maxY - player.radius)
}

@Test func cameraPolesRotateDeterministically() {
    var simulation = Simulation(seed: 12)
    let initial = simulation.state.entities.first { $0.kind == .cameraPole }!.heading
    for _ in 0..<60 { _ = simulation.step(input: .init()) }
    let updated = simulation.state.entities.first { $0.kind == .cameraPole }!.heading
    #expect(updated != initial)
}

@Test func guardSpawnsUseOneSecondTickCadence() {
    var simulation = Simulation(seed: 13)
    var spawnEvents = 0

    for _ in 0..<120 {
        spawnEvents += simulation.step(input: .init()).filter { $0.message == "Contract security dispatched" }.count
    }

    let guards = simulation.state.entities.filter { $0.kind == .securityGuard }
    #expect(spawnEvents == 2)
    #expect(guards.count == 2)
}

@Test func cameraHeadingsRemainNormalized() {
    var simulation = Simulation(seed: 14)

    for _ in 0..<10_000 { _ = simulation.step(input: .init()) }

    let headings = simulation.state.entities
        .filter { $0.kind == .cameraPole }
        .map(\.heading)
    #expect(headings.allSatisfy { $0 >= 0 && $0 < .pi * 2 })
}

@Test func playerDoesNotEnterCentralObstacle() {
    var simulation = Simulation(seed: 15)

    for _ in 0..<600 {
        _ = simulation.step(input: .init(movement: .init(x: 0, y: 1)))
    }

    let player = simulation.state.entities.first { $0.kind == .player }!
    #expect(player.position.y <= -96)
}

@Test func automaticFireDestroysACameraPoleDeterministically() {
    var simulation = Simulation(seed: 16)
    for _ in 0..<600 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .cameraPole }.count < 4)
    #expect(simulation.state.dataShards > 0)
    #expect(simulation.state.pendingUpgradeChoices.count == 3)
}

@Test func selectingUpgradeAppliesItOnceAndClearsDraft() {
    var state = RunState(seed: 16)
    state.pendingUpgradeChoices = [.rapidCountermeasure]
    var simulation = Simulation(state: state, rngSeed: 16)
    let level = simulation.state.activeWeapons[0].level
    _ = simulation.step(input: .init(upgradeChoiceIndex: 0))
    #expect(simulation.state.activeWeapons[0].level == level + 1)
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func projectilesDoNotAccumulateAtWorldEdges() {
    var simulation = Simulation(seed: 17)
    for _ in 0..<3_600 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .projectile }.count < 20)
}

@Test func baselineLoadoutUsesCanonicalKineticProfile() {
    let state = RunState(seed: 18)
    #expect(state.activeWeapons == [.baselineKinetic])
    #expect(state.activeWeapons.first?.cadenceTicks == 15)
    #expect(state.activeWeapons.first?.projectileSpeed == 600)
    #expect(state.activeWeapons.first?.payload == .damage(15))
}

@Test func kineticCountermeasureFiresOnExactCadence() {
    var simulation = Simulation(seed: 19)
    var fireTicks: [Int] = []

    for tick in 1...45 {
        let events = simulation.step(input: .init())
        if events.contains(where: { $0.kind == .weaponFired }) {
            fireTicks.append(tick)
        }
    }

    #expect(fireTicks == [15, 30, 45])
}

@Test func spawnedProjectileCarriesTypedKineticPayload() {
    var simulation = Simulation(seed: 20)
    for _ in 0..<15 { _ = simulation.step(input: .init()) }

    let projectile = simulation.state.entities.first { $0.kind == .projectile }
    #expect(projectile?.sourceWeapon == .kineticCountermeasure)
    #expect(projectile?.payload == .damage(15))
}

@Test func countermeasureHitEmitsTypedEvent() {
    var simulation = Simulation(seed: 21)
    var hitEvents = 0

    for _ in 0..<600 {
        hitEvents += simulation.step(input: .init()).filter { $0.kind == .countermeasureHit }.count
    }

    #expect(hitEvents > 0)
}

@Test func deterministicRunsMatchWeaponEvents() {
    var first = Simulation(seed: 22)
    var second = Simulation(seed: 22)
    var firstEvents: [RunEvent] = []
    var secondEvents: [RunEvent] = []

    for _ in 0..<900 {
        firstEvents += first.step(input: .init(movement: .init(x: 0.4, y: -0.2)))
        secondEvents += second.step(input: .init(movement: .init(x: 0.4, y: -0.2)))
    }

    #expect(first.state == second.state)
    #expect(firstEvents == secondEvents)
}

@Test func projectileCountRemainsBelowDeterministicCap() {
    var simulation = Simulation(seed: 23)
    for _ in 0..<20_000 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .projectile }.count <= CombatLimits.maximumProjectiles)
}

@Test func redactionOrdinanceDisablesCameraSensorsForItsConfiguredDuration() {
    var state = RunState(seed: 24)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 100, y: 0), health: 100, radius: 16)
    ]
    state.activeWeapons = [.redactionOrdinance]
    var simulation = Simulation(state: state, rngSeed: 24)
    var events: [RunEvent] = []

    for _ in 0..<120 { events += simulation.step(input: .init()) }

    let camera = simulation.state.entities.first { $0.id == 2 }
    #expect(events.contains { $0.kind == .countermeasureHit && $0.message.contains("Redacted camera sensors") })
    #expect((camera?.sensorDisabledUntilTick ?? 0) > 120)
}

@Test func selectingRedactionOrdinanceAddsItToTheBoundedLoadout() {
    var state = RunState(seed: 25)
    state.pendingUpgradeChoices = [.redactionOrdinance]
    var simulation = Simulation(state: state, rngSeed: 25)

    _ = simulation.step(input: .init(upgradeChoiceIndex: 0))

    #expect(simulation.state.activeWeapons.map(\.id) == [.kineticCountermeasure, .redactionOrdinance])
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func identityTransponderSpoofsCameraSuspicionPressure() {
    var state = RunState(seed: 26)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 100, y: 0), health: 100, radius: 16)
    ]
    state.activeWeapons = [.identityTransponder]
    var simulation = Simulation(state: state, rngSeed: 26)
    var events: [RunEvent] = []

    for _ in 0..<160 { events += simulation.step(input: .init()) }

    let camera = simulation.state.entities.first { $0.id == 2 }
    #expect(events.contains { $0.kind == .countermeasureHit && $0.message.contains("Spoofed camera identity") })
    #expect(camera?.sensorSpoof?.suspicionMultiplier == 0.25)
    #expect((camera?.sensorSpoof?.untilTick ?? 0) > 160)
}

@Test func selectingIdentityTransponderAddsItToTheBoundedLoadout() {
    var state = RunState(seed: 27)
    state.pendingUpgradeChoices = [.identityTransponder]
    var simulation = Simulation(state: state, rngSeed: 27)

    _ = simulation.step(input: .init(upgradeChoiceIndex: 0))

    #expect(simulation.state.activeWeapons.map(\.id) == [.kineticCountermeasure, .identityTransponder])
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func foiaSwarmAppliesProcessingToThreats() {
    var state = RunState(seed: 28)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .securityGuard, position: .init(x: 100, y: 0), health: 20, radius: 14)
    ]
    state.activeWeapons = [.foiaSwarm]
    var simulation = Simulation(state: state, rngSeed: 28)
    var events: [RunEvent] = []

    for _ in 0..<120 { events += simulation.step(input: .init()) }

    let guardEntity = simulation.state.entities.first { $0.id == 2 }
    #expect(events.contains { $0.kind == .countermeasureHit && $0.message.contains("FOIA processing") })
    #expect(guardEntity?.processing?.slowMultiplier == 0.5)
    #expect((guardEntity?.health ?? 20) < 20)
}

@Test func selectingFoiaSwarmAddsItToTheBoundedLoadout() {
    var state = RunState(seed: 29)
    state.pendingUpgradeChoices = [.foiaSwarm]
    var simulation = Simulation(state: state, rngSeed: 29)

    _ = simulation.step(input: .init(upgradeChoiceIndex: 0))

    #expect(simulation.state.activeWeapons.map(\.id) == [.kineticCountermeasure, .foiaSwarm])
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func totalVisibilityActivatesTheShiftManagerOnce() {
    var state = RunState(seed: 30)
    state.suspicion = 100
    var simulation = Simulation(state: state, rngSeed: 30)

    let firstEvents = simulation.step(input: .init())
    let secondEvents = simulation.step(input: .init())

    #expect(firstEvents.contains { $0.kind == .bossActivated })
    #expect(secondEvents.contains { $0.kind == .bossActivated } == false)
    #expect(simulation.state.entities.filter { $0.kind == .boss }.count == 1)
}

@Test func defeatingShiftManagerOpensBlindSpotExtraction() {
    var state = RunState(seed: 31)
    state.entities.append(Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42))
    var simulation = Simulation(state: state, rngSeed: 31)

    let events = simulation.step(input: .init())

    #expect(simulation.state.bossDefeated)
    #expect(simulation.state.extractionOpen)
    #expect(events.contains { $0.kind == .extractionOpened })
    #expect(simulation.state.entities.contains { $0.kind == .extraction })
}

@Test func enteringBlindSpotCompletesTheRunOnce() {
    var state = RunState(seed: 32)
    state.extractionOpen = true
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .extraction, position: .init(), health: 1_000_000, radius: 60)
    ]
    var simulation = Simulation(state: state, rngSeed: 32)

    let firstEvents = simulation.step(input: .init())
    let secondEvents = simulation.step(input: .init())

    #expect(simulation.state.runCompleted)
    #expect(firstEvents.contains { $0.kind == .extractionCompleted })
    #expect(secondEvents.contains { $0.kind == .extractionCompleted } == false)
}
