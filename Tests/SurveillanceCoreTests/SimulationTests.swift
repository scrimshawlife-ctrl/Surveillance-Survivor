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
        spawnEvents += simulation.step(input: .init()).filter { $0.kind == .entitySpawned && $0.message.contains("Contract security dispatched") }.count
    }

    let guards = simulation.state.entities.filter { $0.kind == .securityGuard }
    #expect(spawnEvents == 2)
    #expect(guards.count == 2)
}

@Test func contractSecuritySpawnsCycleThroughTheAuthoredRoster() {
    var state = RunState(seed: 38)
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 38)

    for _ in 0..<1_260 {
        _ = simulation.step(input: .init())
    }

    let spawned = simulation.state.entities.compactMap(\.guardArchetype)
    #expect(spawned == Array(GuardArchetype.allCases))
}

@Test func supervisorOnBreakRemainsDormantUntilThePlayerIsNearby() {
    var distantState = RunState(seed: 39)
    distantState.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .securityGuard, guardArchetype: .supervisorOnBreak, position: .init(x: 300, y: 0), health: 70, radius: 21)
    ]
    var distantSimulation = Simulation(state: distantState, rngSeed: 39)
    _ = distantSimulation.step(input: .init())

    var nearbyState = distantState
    nearbyState.entities[1].position = .init(x: 100, y: 0)
    var nearbySimulation = Simulation(state: nearbyState, rngSeed: 39)
    _ = nearbySimulation.step(input: .init())

    #expect(distantSimulation.state.entities[1].velocity == .init())
    #expect(nearbySimulation.state.entities[1].velocity.magnitude > 0)
}

@Test func automatedSurveillanceSpawnsCycleThroughTheAuthoredRoster() {
    var state = RunState(seed: 40)
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 40)

    for _ in 0..<5_400 { _ = simulation.step(input: .init()) }

    let deployed = simulation.state.entities.compactMap(\.sensorArchetype).filter { $0 != .lprCameraPole }
    #expect(deployed == Array(SensorArchetype.allCases.dropFirst()))
}

@Test func parkingLotDroneMovesWhileStaticSensorsRemainStationary() {
    var state = RunState(seed: 41)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .parkingLotDrone, position: .init(x: 300, y: 0), health: 35, radius: 12),
        Entity(id: 3, kind: .cameraPole, sensorArchetype: .predictivePatrolNode, position: .init(x: -300, y: 0), health: 55, radius: 18)
    ]
    var simulation = Simulation(state: state, rngSeed: 41)
    _ = simulation.step(input: .init())

    let drone = simulation.state.entities.first { $0.id == 2 }!
    let patrolNode = simulation.state.entities.first { $0.id == 3 }!
    #expect(drone.velocity.magnitude > 0)
    #expect(patrolNode.velocity == .init())
}

@Test func acousticGunshotDetectorOnlyContactsActiveCountermeasures() {
    var state = RunState(seed: 42)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .acousticGunshotDetector, position: .init(x: 100, y: 0), health: 40, radius: 16)
    ]
    state.activeWeapons = []
    var quiet = Simulation(state: state, rngSeed: 42)
    _ = quiet.step(input: .init())
    let quietSuspicion = quiet.state.suspicion

    state.entities.append(Entity(id: 3, kind: .projectile, position: .init(x: 50, y: 0), health: 1, radius: 4))
    var loud = Simulation(state: state, rngSeed: 42)
    _ = loud.step(input: .init())
    #expect(loud.state.suspicion > quietSuspicion)
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

@Test func canonicalUpgradeCatalogContainsTwelveBaseUpgradesAndFourEvolutions() {
    let evolutions: Set<UpgradeChoice> = [.indictmentProtocol, .blackoutField, .ghostProtocol, .paperStorm]
    #expect(UpgradeChoice.allCases.count - evolutions.count == 12)
    #expect(WeaponEvolution.allCases.count == 4)
}

@Test func evolutionRequiresItsWeaponAtLevelThreeAndAppliesOnce() {
    var state = RunState(seed: 161)
    state.activeWeapons[0].level = 3
    state.pendingUpgradeChoices = [.indictmentProtocol]
    var simulation = Simulation(state: state, rngSeed: 161)
    _ = simulation.step(input: .init(upgradeChoiceIndex: 0))

    #expect(simulation.state.evolutions == [.indictmentProtocol])
    #expect(simulation.state.activeWeapons[0].level == 4)
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func ineligibleEvolutionIsNotOfferedBeforeItsPrerequisiteLevel() {
    var state = RunState(seed: 162)
    state.activeWeapons = [.baselineKinetic]
    var simulation = Simulation(state: state, rngSeed: 162)
    for _ in 0..<600 { _ = simulation.step(input: .init()) }

    #expect(!simulation.state.pendingUpgradeChoices.contains(.indictmentProtocol))
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

@Test func bundledWeaponCatalogIsVersionedCompleteAndTyped() throws {
    let catalog = try ContentCatalog.loadBundled()
    #expect(catalog.schemaVersion == ContentCatalog.currentSchemaVersion)
    #expect(Set(catalog.weapons.map(\.id)) == Set(WeaponID.allCases))
    #expect(catalog.weapon(.kineticCountermeasure).weaponSystem() == .baselineKinetic)
}

@Test func bundledUpgradeCatalogIsVersionedCompleteAndTyped() throws {
    let catalog = try UpgradeCatalog.loadBundled()
    #expect(catalog.schemaVersion == UpgradeCatalog.currentSchemaVersion)
    #expect(Set(catalog.upgrades.map(\.id)) == Set(UpgradeChoice.allCases))
    #expect(catalog.upgrade(.indictmentProtocol).evolution == .indictmentProtocol)
    #expect(catalog.upgrade(.lowProfileRouting).effect.suspicionReduction == 10)
}

@Test func bundledEnemyCatalogIsVersionedCompleteAndTyped() throws {
    let catalog = try EnemyCatalog.loadBundled()
    #expect(catalog.schemaVersion == EnemyCatalog.currentSchemaVersion)
    #expect(Set(catalog.guards.map(\.id)) == Set(GuardArchetype.allCases))
    #expect(Set(catalog.sensors.map(\.id)) == Set(SensorArchetype.allCases))
    #expect(catalog.sensorDefinition(.parkingLotDrone).movementStyle == .orbit)
}

@Test func bundledWaveCatalogPreservesSpawnCadenceContract() throws {
    let catalog = try WaveCatalog.loadBundled()
    #expect(catalog.schemaVersion == WaveCatalog.currentSchemaVersion)
    #expect(catalog.guardSpawnIntervalTicks == 60)
    #expect(catalog.sensorSpawnIntervalTicks == 1_080)
}

@Test func bundledSuspicionCatalogPreservesTierContract() throws {
    let catalog = try SuspicionCatalog.loadBundled()
    #expect(catalog.schemaVersion == SuspicionCatalog.currentSchemaVersion)
    #expect(catalog.tier(for: 19.9) == .backgroundNoise)
    #expect(catalog.tier(for: 95) == .totalVisibility)
}

@Test func bundledDistrictCatalogPreservesCanonicalCampaignOrder() throws {
    let catalog = try DistrictCatalog.loadBundled()
    #expect(catalog.schemaVersion == DistrictCatalog.currentSchemaVersion)
    #expect(catalog.districts.map(\.id) == [.wichita, .louisville, .tulsa, .dayton, .oakland, .sanFrancisco, .columbus, .newYorkCity, .losAngeles, .atlanta])
    #expect(catalog.district(.atlanta).midBossName == "The Public–Private Partnership Chimera")
    #expect(catalog.district(.newYorkCity).researchQualification != nil)
    #expect(catalog.district(.losAngeles).researchQualification != nil)
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

@Test func deterministicRunsProduceEquivalentStructuredReceipts() {
    var first = Simulation(seed: 37)
    var second = Simulation(seed: 37)

    for _ in 0..<900 {
        _ = first.step(input: .init(movement: .init(x: 0.4, y: -0.2)))
        _ = second.step(input: .init(movement: .init(x: 0.4, y: -0.2)))
    }

    let receipt = first.runReceipt()
    #expect(receipt == second.runReceipt())
    #expect(receipt.schemaVersion == RunReceipt.schemaVersion)
    #expect(receipt.elapsedTicks == 900)
    #expect(receipt.eventSequence.enumerated().allSatisfy { index, event in event.sequence == UInt64(index) })
    #expect(receipt.suspicionTimeline.isEmpty == false)
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

@Test func disabledCameraSensorsStopRotatingAndMoving() {
    var state = RunState(seed: 241)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .cameraPole,
            sensorArchetype: .lprCameraPole,
            position: .init(x: 120, y: 0),
            heading: 0.4,
            health: 100,
            radius: 16,
            sensorDisabledUntilTick: 10_000
        ),
        Entity(
            id: 3,
            kind: .cameraPole,
            sensorArchetype: .parkingLotDrone,
            position: .init(x: 220, y: 0),
            heading: 1.1,
            health: 35,
            radius: 12,
            sensorDisabledUntilTick: 10_000
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 241)

    for _ in 0..<60 { _ = simulation.step(input: .init()) }

    let pole = simulation.state.entities.first { $0.id == 2 }!
    let drone = simulation.state.entities.first { $0.id == 3 }!
    #expect(pole.heading == 0.4)
    #expect(drone.heading == 1.1)
    #expect(drone.velocity == .init())
    #expect(drone.position == .init(x: 220, y: 0))
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

@Test func mirrorArrayDeploysBoundedSensorDisruption() {
    var state = RunState(seed: 33)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 100, y: 0), health: 60, radius: 16)
    ]
    state.activeWeapons = [.mirrorArray]
    var simulation = Simulation(state: state, rngSeed: 33)
    var events: [RunEvent] = []

    for _ in 0..<210 { events += simulation.step(input: .init()) }

    let camera = simulation.state.entities.first { $0.id == 2 }
    #expect(simulation.state.entities.contains { $0.kind == .mirrorArray })
    #expect(simulation.state.entities.filter { $0.kind == .mirrorArray }.count <= CombatLimits.maximumPersistentDeployables)
    #expect((camera?.health ?? 60) < 60)
    #expect(events.contains { $0.kind == .countermeasureHit && $0.message.contains("Mirror array") })
}

@Test func signalFloodDisruptsNearbyCamerasAndBossWithSuspicionCost() {
    var state = RunState(seed: 34)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 100, y: 0), health: 60, radius: 16),
        Entity(id: 3, kind: .boss, position: .init(x: 140, y: 0), health: 450, radius: 42)
    ]
    state.activeWeapons = [.signalFlood]
    var simulation = Simulation(state: state, rngSeed: 34)
    var events: [RunEvent] = []

    for _ in 0..<300 { events += simulation.step(input: .init()) }

    let camera = simulation.state.entities.first { $0.id == 2 }
    let boss = simulation.state.entities.first { $0.id == 3 }
    #expect((camera?.sensorDisabledUntilTick ?? 0) > 300)
    #expect((boss?.disruptedUntilTick ?? 0) > 300)
    #expect(simulation.state.suspicion > 9.9)
    #expect(events.contains { $0.kind == .countermeasureHit && $0.message.contains("Signal flood") })
}

@Test func selectingMirrorArrayAndSignalFloodRespectsTheLoadoutCap() {
    var state = RunState(seed: 35)
    state.pendingUpgradeChoices = [.mirrorArray]
    var simulation = Simulation(state: state, rngSeed: 35)
    _ = simulation.step(input: .init(upgradeChoiceIndex: 0))

    var signalState = RunState(seed: 36)
    signalState.pendingUpgradeChoices = [.signalFlood]
    var signalSimulation = Simulation(state: signalState, rngSeed: 36)
    _ = signalSimulation.step(input: .init(upgradeChoiceIndex: 0))

    #expect(simulation.state.activeWeapons.map(\.id) == [.kineticCountermeasure, .mirrorArray])
    #expect(signalSimulation.state.activeWeapons.map(\.id) == [.kineticCountermeasure, .signalFlood])
    #expect(simulation.state.activeWeapons.count <= CombatLimits.maximumActiveWeapons)
    #expect(signalSimulation.state.activeWeapons.count <= CombatLimits.maximumActiveWeapons)
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
