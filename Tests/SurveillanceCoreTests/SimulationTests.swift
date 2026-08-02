import Foundation
import Testing
@testable import SurveillanceCore

@Test func fixedStepValidationAcceptsSupportedCadencesAndRejectsInvalidValues() {
    for value in [1.0 / 60.0, 1.0 / 30.0, 0.001, 0.1] {
        #expect(Simulation.isValidFixedStep(value))
    }
    for value in [0.0, -0.001, Double.nan, .infinity, -.infinity, 0.100_000_1] {
        #expect(!Simulation.isValidFixedStep(value))
    }
}

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

@Test func draftedRepairsAreTheOnlyWayIntegrityComesBack() {
    // The game shipped with no healing of any kind: nothing restored integrity and
    // none of the draft answered survival, so damage was permanent across a run and
    // taking a hit had no counterplay at all.
    func damagedRun(offering choice: UpgradeChoice? = nil) -> Simulation {
        var state = RunState(seed: 44, district: .wichita)
        state.activeWeapons = []
        state.entities.removeAll { $0.kind == .cameraPole }
        if let player = state.entities.firstIndex(where: { $0.kind == EntityKind.player }) {
            state.entities[player].health = 30
        }
        if let choice { state.pendingUpgradeChoices = [choice] }
        return Simulation(state: state, rngSeed: 44)
    }

    func integrity(_ simulation: Simulation) -> Double {
        simulation.state.entities.first { $0.kind == EntityKind.player }?.health ?? 0
    }

    // Immediate repair, clamped to the authored maximum.
    var repaired = damagedRun(offering: .emergencyRepair)
    _ = repaired.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: false))
    #expect(integrity(repaired) == 70, "expected 30 + 40, got \(integrity(repaired))")
    for _ in 0..<5 {
        var working = repaired.state
        working.pendingUpgradeChoices = [.emergencyRepair]
        repaired = Simulation(state: working, rngSeed: 44)
        _ = repaired.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: false))
    }
    #expect(integrity(repaired) == BossCatalog.bundled.playerHealth,
            "repair must clamp to the authored maximum, got \(integrity(repaired))")

    // Regeneration accrues only while nothing has contact.
    var regenerating = damagedRun(offering: .redundantSystems)
    _ = regenerating.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: false))
    for _ in 0..<600 { _ = regenerating.step(input: .init(autoFireEnabled: false, suppressThreatContact: true)) }
    #expect(integrity(regenerating) > 30, "redundancy must recover integrity over time, got \(integrity(regenerating))")

    // Without a drafted repair nothing recovers, which is the state the game was in.
    var untouched = damagedRun()
    for _ in 0..<600 { _ = untouched.step(input: .init(autoFireEnabled: false, suppressThreatContact: true)) }
    #expect(integrity(untouched) == 30, "integrity must not recover on its own, got \(integrity(untouched))")
}

@Test func aFullyIntactPlayerIsNotOfferedARepairThatWouldDoNothing() {
    var state = RunState(seed: 45, district: .wichita)
    state.activeWeapons = []
    let simulation = Simulation(state: state, rngSeed: 45)
    #expect(!simulation.isUpgradeEligible(.emergencyRepair),
            "a repair card at full integrity burns one of three draft slots")
    state.entities = state.entities.map { entity in
        var copy = entity
        if copy.kind == .player { copy.health = 10 }
        return copy
    }
    let hurt = Simulation(state: state, rngSeed: 45)
    #expect(hurt.isUpgradeEligible(.emergencyRepair))
}

@Test func countermeasuresLeadMovingTargetsInsteadOfShootingWhereTheyStood() {
    // Countermeasures fired straight at a target's position at the instant of the
    // shot. A projectile crossing 400 units takes about two thirds of a second, so
    // anything moving across the line of fire had left before it arrived: direct aim
    // missed a crossing target at every speed and every range tested. The player has
    // no aim in this game, only positioning, so that reads as the character shooting
    // at nothing — and it hit the orbiting archetype hardest, the one most often in
    // contact.
    func hits(leading: Bool, targetSpeed: Double, range: Double) -> Bool {
        let target = Entity(
            id: 9, kind: .securityGuard, position: .init(x: range, y: 0),
            velocity: .init(x: 0, y: targetSpeed), health: 100, radius: 14
        )
        let direction = leading
            ? Simulation.interceptDirection(from: .init(), target: target, projectileSpeed: 600)
            : target.position.normalized()
        var projectile = Vector2()
        var position = target.position
        for _ in 0..<180 {
            projectile = projectile + direction * 600 * (1.0 / 60.0)
            position = position + target.velocity * (1.0 / 60.0)
            if (projectile - position).magnitude <= 14 + 5 { return true }
        }
        return false
    }

    for range in stride(from: 150.0, through: 400.0, by: 50.0) {
        // A stationary pole must behave exactly as before — leading reduces to direct aim.
        #expect(hits(leading: true, targetSpeed: 0, range: range))
        for speed in [88.0, 150.0, 172.0] {
            #expect(hits(leading: true, targetSpeed: speed, range: range),
                    "lead must connect at speed \(speed) range \(range)")
            #expect(!hits(leading: false, targetSpeed: speed, range: range),
                    "guard against this test silently passing if aiming stops mattering")
        }
    }

    // A target at or above projectile speed has no intercept; aim must stay finite.
    let ungettable = Entity(
        id: 10, kind: .securityGuard, position: .init(x: 200, y: 0),
        velocity: .init(x: 0, y: 900), health: 100, radius: 14
    )
    let fallback = Simulation.interceptDirection(from: .init(), target: ungettable, projectileSpeed: 600)
    #expect(fallback.magnitude > 0.99 && fallback.magnitude < 1.01)
}

@Test func aCrowdCannotDealMoreContactDamageThanTheAuthoredCap() {
    // Contact damage once summed every overlapping guard, so walking into a tier-5
    // crowd removed the player in a fraction of a second with no counterplay. Damage
    // is capped to the authored number of simultaneous attackers; without that cap a
    // crowd scales linearly and the cap is the only thing standing between the player
    // and instant death.
    func survivalTicks(attackers: Int) -> Int {
        var state = RunState(seed: 88, district: .wichita)
        state.activeWeapons = []
        state.entities.removeAll { $0.kind == .cameraPole }
        if let player = state.entities.firstIndex(where: { $0.kind == EntityKind.player }) {
            state.entities[player].position = .init()
            state.entities[player].health = BossCatalog.bundled.playerHealth
        }
        for index in 0..<attackers {
            state.entities.append(Entity(
                id: UInt64(500 + index), kind: .securityGuard,
                guardArchetype: .tacticalPolo,
                position: .init(x: Double(index) * 2, y: 0),
                health: 100_000, radius: 14
            ))
        }
        var simulation = Simulation(state: state, rngSeed: 88)
        for tick in 0..<36_000 {
            _ = simulation.step(input: .init(autoFireEnabled: false))
            if simulation.state.playerDefeated { return tick }
        }
        return 36_000
    }

    let cap = BossCatalog.bundled.maximumSimultaneousContactThreats
    let atCap = survivalTicks(attackers: cap)
    let swarm = survivalTicks(attackers: cap * 5)
    #expect(atCap < 36_000, "the capped crowd should still be lethal, or this proves nothing")
    // A crowd five times the cap must not kill five times faster.
    #expect(Double(swarm) >= Double(atCap) * 0.8,
            "\(cap * 5) attackers killed in \(swarm) ticks against \(atCap) at the cap of \(cap); damage is scaling with the crowd")
}

@Test func theRosterMustContainAThreatThePlayerCannotOutrun() {
    // What player speed actually binds. Combat having teeth no longer depends on it —
    // deploying contract security around the player rather than the map centre does
    // that work, and raising the player back to 210 leaves the campaign just as
    // dangerous. What collapses at 210 is the roster's shape: every archetype becomes
    // slower than the player, so "the sprinter you cannot outrun" stops existing and
    // disengaging is always free.
    let player = BossCatalog.bundled.playerSpeed
    let faster = GuardArchetype.allCases.filter { $0.definition.speed > player }
    #expect(!faster.isEmpty,
            "no archetype exceeds player speed \(player); every threat can be walked away from")
    // And it must stay answerable: a threat that cannot be escaped has to be fragile.
    for archetype in faster {
        #expect(archetype.definition.health <= 30,
                "\(archetype) outruns the player at \(archetype.definition.health) health; unescapable and durable is unanswerable")
    }
}

@Test func draftsStaySpacedEvenWhenNothingIsQueued() {
    // The interval is enforced in two places: draining the queue, and opening a fresh
    // draft. A test covering only the queue leaves the second path free to reopen a
    // draft the instant the next camera dies, which is the clustering this spacing
    // exists to stop.
    //
    // Runs one simulation and lets auto-fire take two poles in its own time; the
    // interval is remembered on the simulation, as weapon target commitment is, so
    // rebuilding one mid-scenario would silently reset what is under test.
    var state = RunState(seed: 7_007)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: 120, y: 0), health: 1, radius: 16),
        Entity(id: 3, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: -140, y: 0), health: 1, radius: 16)
    ]
    var simulation = Simulation(state: state, rngSeed: 7_007)

    var offerTicks: [Int] = []
    for tick in 0..<1_800 {
        // Take every draft the moment it is offered, so any spacing observed is the
        // simulation's own and not the player sitting on an open card.
        let events = simulation.step(input: .init(upgradeChoiceIndex: 0))
        if events.contains(where: { $0.kind == .upgradeOffered }) { offerTicks.append(tick) }
    }

    #expect(offerTicks.count >= 2, "expected both poles to be destroyed, got \(offerTicks.count) offers")
    let gaps = zip(offerTicks.dropFirst(), offerTicks).map { $0 - $1 }
    let interval = Int(UpgradeCatalog.bundled.minimumDraftIntervalTicks)
    for gap in gaps {
        #expect(gap >= interval,
                "drafts came \(gap) ticks apart, closer than the authored \(interval)")
    }
}

@Test func stickTravelControlsSpeedInsteadOfBeingDiscarded() {
    // Movement used to be normalized, so a barely-tilted stick and a fully-pushed one
    // produced identical full-speed motion. There was no way to make a small
    // adjustment, and near the stick's centre a couple of pixels of thumb travel
    // still dashed at full speed in a direction that jittered with the touch.
    func distanceTravelled(pushing movement: Vector2) -> Double {
        var simulation = Simulation(seed: 31)
        let start = simulation.state.entities.first { $0.kind == EntityKind.player }?.position ?? .init()
        for _ in 0..<30 {
            _ = simulation.step(input: .init(movement: movement, autoFireEnabled: false))
        }
        let end = simulation.state.entities.first { $0.kind == EntityKind.player }?.position ?? .init()
        return (end - start).magnitude
    }

    let full = distanceTravelled(pushing: .init(x: 1, y: 0))
    let half = distanceTravelled(pushing: .init(x: 0.5, y: 0))
    #expect(full > 0)
    #expect(half < full * 0.75, "a half-pushed stick must not move as far as a full one: half=\(half) full=\(full)")
    #expect(half > full * 0.25, "a half-pushed stick must still move: half=\(half) full=\(full)")

    // An over-unit vector must not outrun the authored speed.
    let overdriven = distanceTravelled(pushing: .init(x: 40, y: 0))
    #expect(abs(overdriven - full) < 0.001, "clamped, not scaled: overdriven=\(overdriven) full=\(full)")
}

@Test func suspicionEscalatesFromBeingSeenRatherThanFromTimePassing() {
    // Previously suspicion rose on wall-clock because guard population grew on a timer,
    // so simply existing escalated the run. Visibility is now the source: a player who
    // stands still out of every scan cone is not noticed, and one who breaks the
    // surveillance grid is. Idling to the top tier is no longer a strategy.
    var idle = Simulation(seed: 9)
    var idlePeak = 0.0
    for _ in 0..<3600 {
        _ = idle.step(input: .init(autoFireEnabled: false))
        idlePeak = max(idlePeak, idle.state.suspicion)
    }
    #expect(idlePeak == 0, "standing unseen for a minute must not raise suspicion, got \(idlePeak)")

    // Destroying a pole is the loud, deliberate act that escalates.
    var active = Simulation(state: RunState(seed: 9), rngSeed: 9)
    var working = active.state
    guard let pole = working.entities.firstIndex(where: { $0.kind == .cameraPole }) else {
        Issue.record("seed 9 authored no camera poles to destroy")
        return
    }
    working.entities[pole].health = 0
    active = Simulation(state: working, rngSeed: 9)
    _ = active.step(input: .init(autoFireEnabled: false))
    #expect(active.state.suspicion >= SuspicionCatalog.bundled.cameraDestroyedSuspicionSpike,
            "breaking the grid must register, got \(active.state.suspicion)")
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

@Test func lprCameraPolesStayStationaryWithRevolvingScanCone() {
    // Design law: LPR *bodies* stay fixed at spawn; red LOS cones revolve (rotationSpeed > 0).
    // Authored headings are starting LOS only — never chase the player.
    var simulation = Simulation(seed: 12)
    let poles = simulation.state.entities.filter {
        $0.kind == .cameraPole && ($0.sensorArchetype ?? .lprCameraPole) == .lprCameraPole
    }
    #expect(!poles.isEmpty)
    let initialHeadings = Dictionary(uniqueKeysWithValues: poles.map { ($0.id, $0.heading) })
    let initialPositions = Dictionary(uniqueKeysWithValues: poles.map { ($0.id, $0.position) })
    for _ in 0..<120 { _ = simulation.step(input: .init()) }
    for pole in simulation.state.entities where pole.kind == .cameraPole
        && (pole.sensorArchetype ?? .lprCameraPole) == .lprCameraPole
    {
        #expect(pole.heading != initialHeadings[pole.id], "LPR LOS cone should revolve")
        #expect(pole.position == initialPositions[pole.id])
        #expect(pole.velocity == .init())
    }
}

@Test func panTiltZoomSensorsMayRotateWhileStationaryInPlace() {
    var state = RunState(seed: 121)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .cameraPole,
            sensorArchetype: .panTiltZoomEye,
            position: .init(x: 200, y: 0),
            heading: 0.25,
            health: 48,
            radius: 16
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 121)
    let initial = simulation.state.entities.first { $0.id == 2 }!.heading
    for _ in 0..<60 { _ = simulation.step(input: .init()) }
    let updated = simulation.state.entities.first { $0.id == 2 }!
    #expect(updated.heading != initial)
    #expect(updated.position == .init(x: 200, y: 0))
    #expect(updated.velocity == .init())
}

@Test func guardSpawnsUseOneSecondTickCadence() {
    var state = RunState(seed: 13)
    // Survive contact damage so spawn cadence can be observed.
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 13)
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
    // Population now follows suspicion rather than the clock, so the district must
    // actually be alarmed for the full roster to be dispatched.
    state.suspicion = 100
    state.suspicionTier = .totalVisibility
    // Survive contact while the roster cycles — sliding movement lets guards
    // reach the player more reliably than frozen wall-sticks.
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 10_000
    }
    var simulation = Simulation(state: state, rngSeed: 38)

    for _ in 0..<1_260 {
        _ = simulation.step(input: .init())
    }

    let spawned = simulation.state.entities.compactMap(\.guardArchetype)
    let roster = Array(GuardArchetype.allCases)
    // An alarmed district cycles the roster repeatedly, so assert the cyclic order
    // rather than a single pass.
    #expect(spawned.count >= roster.count)
    for (index, archetype) in spawned.enumerated() {
        #expect(archetype == roster[index % roster.count])
    }
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
    // Long spawn cadence must not end early from contract-security contact damage.
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 40)

    // Allow headroom when director sensorCadenceMultiplier stretches the interval.
    for _ in 0..<12_000 { _ = simulation.step(input: .init()) }

    let deployed = simulation.state.entities.compactMap(\.sensorArchetype).filter { $0 != .lprCameraPole }
    #expect(deployed == Array(SensorArchetype.allCases.dropFirst()))
}

@Test func cameraPolesStayStationaryAndConeHeadingRevolves() {
    var state = RunState(seed: 41)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        // Formerly chase/orbit archetypes — bodies must never pursue the player.
        Entity(
            id: 2,
            kind: .cameraPole,
            sensorArchetype: .parkingLotDrone,
            position: .init(x: 300, y: 0),
            heading: 0,
            health: 35,
            radius: 12
        ),
        Entity(
            id: 3,
            kind: .cameraPole,
            sensorArchetype: .smartDoorbellSwarm,
            position: .init(x: -300, y: 0),
            heading: 1,
            health: 30,
            radius: 15
        ),
        Entity(
            id: 4,
            kind: .cameraPole,
            sensorArchetype: .lprCameraPole,
            position: .init(x: 0, y: 280),
            heading: 0.5,
            health: 60,
            radius: 20
        )
    ]
    var simulation = Simulation(state: state, rngSeed: 41)
    let startPositions = Dictionary(uniqueKeysWithValues: simulation.state.entities.map { ($0.id, $0.position) })
    let startHeadings = Dictionary(uniqueKeysWithValues: simulation.state.entities.map { ($0.id, $0.heading) })
    for _ in 0..<30 {
        _ = simulation.step(input: .init(movement: .init(x: 1, y: 0)))
    }

    for camera in simulation.state.entities where camera.kind == .cameraPole {
        #expect(camera.velocity == .init(), "camera \(camera.sensorArchetype?.rawValue ?? "?") must not move")
        #expect(camera.position.x == startPositions[camera.id]?.x)
        #expect(camera.position.y == startPositions[camera.id]?.y)
        let speed = camera.sensorArchetype?.rotationSpeed ?? 0
        if speed > 0 {
            #expect(camera.heading != startHeadings[camera.id], "LOS cone should revolve for \(camera.sensorArchetype?.rawValue ?? "?")")
        }
    }
}

@Test func sensorContactRequiresPlayerInsideRevolvingCone() {
    // Player sits east of a stationary LPR.
    var outsideState = RunState(seed: 42)
    outsideState.entities = [
        Entity(id: 1, kind: .player, position: .init(x: 200, y: 0), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .cameraPole,
            sensorArchetype: .lprCameraPole,
            position: .init(),
            heading: .pi / 2, // north — player is outside half-angle
            health: 60,
            radius: 20
        )
    ]
    outsideState.activeWeapons = []
    var outside = Simulation(state: outsideState, rngSeed: 42)
    _ = outside.step(input: .init())

    var insideState = outsideState
    insideState.entities = [
        Entity(id: 1, kind: .player, position: .init(x: 200, y: 0), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .cameraPole,
            sensorArchetype: .lprCameraPole,
            position: .init(),
            heading: 0, // east — LOS faces the player
            health: 60,
            radius: 20
        )
    ]
    var inside = Simulation(state: insideState, rngSeed: 42)
    _ = inside.step(input: .init())
    #expect(inside.state.suspicion > outside.state.suspicion)
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

@Test func acousticGunshotDetectorIgnoresSpentProjectiles() {
    var state = RunState(seed: 42)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .acousticGunshotDetector, position: .init(x: 100, y: 0), health: 40, radius: 16),
        // Spent projectile still present before death cleanup must not count as contact.
        Entity(id: 3, kind: .projectile, position: .init(x: 50, y: 0), health: 0, radius: 4)
    ]
    state.activeWeapons = []
    var spent = Simulation(state: state, rngSeed: 42)
    _ = spent.step(input: .init())

    state.entities = state.entities.filter { $0.kind != .projectile }
    var quiet = Simulation(state: state, rngSeed: 42)
    _ = quiet.step(input: .init())
    #expect(spent.state.suspicion == quiet.state.suspicion)
}

@Test func cameraHeadingsRemainNormalized() {
    var state = RunState(seed: 14)
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 14)

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

@Test func playerSlidesAlongObstacleInsteadOfStickingOnDiagonalInput() {
    // Seed a player moving into a tall wall with combined +x/+y input.
    // Axis-separated resolution must still allow travel along the free axis.
    var state = RunState(seed: 42)
    // Wall taller than the travel window so the player cannot slip around the top.
    let wall = WorldObstacle(id: 99, center: .init(x: 80, y: 0), halfSize: .init(x: 40, y: 2_000))
    state.world = WorldLayout(bounds: state.world.bounds, obstacles: [wall])
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: 0, y: -40), health: 100, radius: 18)
    ]
    var simulation = Simulation(state: state, rngSeed: 42)
    let start = simulation.state.entities.first { $0.kind == .player }!.position
    for _ in 0..<120 {
        _ = simulation.step(input: .init(movement: .init(x: 1, y: 1)))
    }
    let player = simulation.state.entities.first { $0.kind == .player }!
    // Must not tunnel into the wall's x slab.
    #expect(player.position.x + player.radius <= wall.center.x - wall.halfSize.x + 0.5)
    // Must still gain y from the free axis (slide), not freeze at the contact point.
    #expect(player.position.y > start.y + 20)
}

@Test func automaticFireDestroysACameraPoleDeterministically() {
    var state = RunState(seed: 16)
    // Place the player in kinetic range of one LPR; baseline range is local.
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -700, y: -360), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole, position: .init(x: -720, y: -360), heading: 0, health: 60, radius: 22)
    ]
    var simulation = Simulation(state: state, rngSeed: 16)
    for _ in 0..<600 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .cameraPole }.count < 1 || simulation.state.dataShards > 0)
    #expect(simulation.state.dataShards > 0)
    #expect(simulation.state.pendingUpgradeChoices.count == 3)
}

@Test func standingStillDoesNotFarmDistantCameras() {
    var simulation = Simulation(seed: 160)
    for _ in 0..<900 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .cameraPole }.count == 4)
    #expect(simulation.state.dataShards == 0)
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func upgradeOfferClearsInFlightProjectiles() {
    var state = RunState(seed: 1610)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 40, y: 0), health: 1, radius: 16),
        Entity(
            id: 3,
            kind: .projectile,
            position: .init(x: 30, y: 0),
            velocity: .init(x: 600, y: 0),
            health: 1,
            radius: 5,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(15)
        ),
        Entity(
            id: 4,
            kind: .projectile,
            position: .init(x: -80, y: 0),
            velocity: .init(x: 600, y: 0),
            health: 1,
            radius: 5,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(15)
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 1610)
    _ = simulation.step(input: .init())
    #expect(simulation.state.pendingUpgradeChoices.count == 3)
    #expect(simulation.state.entities.filter { $0.kind == .projectile }.isEmpty)
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

@Test func multiCameraKillsQueueUpgradeDraftsOneToOneWithShards() {
    // Two camera poles die in the same tick → two shard opportunities (draft + queue).
    var state = RunState(seed: 4242)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole, position: .init(x: 40, y: 0), health: 1, radius: 16),
        Entity(id: 3, kind: .cameraPole, sensorArchetype: .parkingLotDrone, position: .init(x: -40, y: 0), health: 1, radius: 16),
        Entity(
            id: 4,
            kind: .projectile,
            position: .init(x: 20, y: 0),
            velocity: .init(x: 400, y: 0),
            health: 1,
            radius: 5,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(50)
        ),
        Entity(
            id: 5,
            kind: .projectile,
            position: .init(x: -20, y: 0),
            velocity: .init(x: -400, y: 0),
            health: 1,
            radius: 5,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(50)
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 4242)
    let events = simulation.step(input: .init())
    #expect(simulation.state.dataShards == 2)
    #expect(simulation.state.pendingUpgradeChoices.count == 3)
    #expect(simulation.state.queuedUpgradeOffers == 1)
    #expect(events.contains { $0.kind == .upgradeOffered && $0.message.contains("Camera data shard") })

    // The first pick drains the live draft, but the queued one is now deferred rather
    // than opening back to back: cameras cluster spatially, so clearing them stacked
    // full-screen modals (four inside the opening nine seconds of Dayton).
    _ = simulation.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: false))
    #expect(simulation.state.pendingUpgradeChoices.isEmpty,
            "a queued draft must not open on the very next tick")
    #expect(simulation.state.queuedUpgradeOffers == 1, "the shard opportunity is deferred, never dropped")

    // It is owed, so it must still arrive once the interval elapses.
    for _ in 0..<UpgradeCatalog.bundled.minimumDraftIntervalTicks {
        _ = simulation.step(input: .init(autoFireEnabled: false))
        if !simulation.state.pendingUpgradeChoices.isEmpty { break }
    }
    #expect(simulation.state.queuedUpgradeOffers == 0)
    #expect(simulation.state.pendingUpgradeChoices.count == 3,
            "every camera still owes exactly one draft")
}

@Test func staleIneligibleUpgradeSelectionStillConsumesDraftAndOpensQueuedOffer() {
    // Defense-in-depth: a pending addsWeapon choice that no longer fits the loadout
    // must not early-return and leave the draft/queue stuck.
    var state = RunState(seed: 4243)
    state.activeWeapons = [
        .baselineKinetic,
        .redactionOrdinance,
        .identityTransponder,
        .foiaSwarm
    ]
    state.pendingUpgradeChoices = [.mirrorArray, .rapidCountermeasure, .lowProfileRouting]
    state.queuedUpgradeOffers = 2
    var simulation = Simulation(state: state, rngSeed: 4243)
    let events = simulation.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: false))

    #expect(!simulation.state.activeWeapons.contains { $0.id == .mirrorArray })
    // One queued draft opened; one remains for the next pick.
    #expect(simulation.state.queuedUpgradeOffers == 1)
    #expect(simulation.state.pendingUpgradeChoices.count == 3)
    // Stale choice must not pollute selected upgrades / build engine / receipts.
    #expect(!simulation.runReceipt().selectedUpgrades.contains(.mirrorArray))
    #expect(events.contains { $0.kind == .upgradeSelected && $0.message.contains("Discarded stale") })
}

@Test func canonicalUpgradeCatalogContainsFourteenBaseUpgradesAndFourEvolutions() {
    // Fourteen since emergencyRepair and redundantSystems were added: the game had no
    // way to recover integrity at all, so damage was permanent across a run and none
    // of the draft answered survival.
    let evolutions: Set<UpgradeChoice> = [.indictmentProtocol, .blackoutField, .ghostProtocol, .paperStorm]
    #expect(UpgradeChoice.allCases.count - evolutions.count == 14)
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
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -700, y: -360), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole, position: .init(x: -720, y: -360), health: 60, radius: 22)
    ]
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
    #expect(state.activeWeapons.first?.range == 420)
    #expect(state.activeWeapons.first?.projectileSpeed == 600)
    #expect(state.activeWeapons.first?.payload == .damage(15))
}

@Test func bundledWeaponCatalogIsVersionedCompleteAndTyped() throws {
    let catalog = try ContentCatalog.loadBundled()
    #expect(catalog.schemaVersion == ContentCatalog.currentSchemaVersion)
    #expect(Set(catalog.weapons.map(\.id)) == Set(WeaponID.allCases))
    #expect(catalog.weapon(.kineticCountermeasure).weaponSystem() == .baselineKinetic)
}

@Test func weaponCatalogRejectsNegativeDamagePayload() throws {
    let payload = """
    {
      "schemaVersion": 1,
      "weapons": [
        { "id": "kineticCountermeasure", "cadenceTicks": 15, "range": 420, "projectileSpeed": 600, "projectileRadius": 5, "targetingRule": "nearestCameraThenThreat", "payload": { "kind": "damage", "amount": -15 } },
        { "id": "redactionOrdinance", "cadenceTicks": 90, "range": 800, "projectileSpeed": 420, "projectileRadius": 10, "targetingRule": "nearestCamera", "payload": { "kind": "disableCameraSensors", "durationTicks": 180 } },
        { "id": "identityTransponder", "cadenceTicks": 120, "range": 700, "projectileSpeed": 360, "projectileRadius": 9, "targetingRule": "nearestCamera", "payload": { "kind": "spoofCameraSensors", "durationTicks": 240, "suspicionMultiplier": 0.25 } },
        { "id": "foiaSwarm", "cadenceTicks": 75, "range": 700, "projectileSpeed": 320, "projectileRadius": 7, "targetingRule": "nearestThreat", "payload": { "kind": "processing", "durationTicks": 180, "slowMultiplier": 0.5, "damagePerTick": 0.12 } },
        { "id": "mirrorArray", "cadenceTicks": 180, "range": 0, "projectileSpeed": 0, "projectileRadius": 34, "targetingRule": "nearestCamera", "payload": { "kind": "reflect", "durationTicks": 360, "damageMultiplier": 1 } },
        { "id": "signalFlood", "cadenceTicks": 300, "range": 360, "projectileSpeed": 0, "projectileRadius": 360, "targetingRule": "nearestCamera", "payload": { "kind": "signalFlood", "radius": 360, "durationTicks": 150, "suspicionSpike": 10 } }
      ]
    }
    """.data(using: .utf8)!
    let catalog = try JSONDecoder().decode(ContentCatalog.self, from: payload)
    #expect(throws: ContentCatalogError.invalidWeaponDefinition) {
        try catalog.validate()
    }
}

@Test func weaponCatalogRejectsMismatchedPayloadKindForWeaponID() throws {
    let payload = """
    {
      "schemaVersion": 1,
      "weapons": [
        { "id": "kineticCountermeasure", "cadenceTicks": 15, "range": 420, "projectileSpeed": 600, "projectileRadius": 5, "targetingRule": "nearestCameraThenThreat", "payload": { "kind": "damage", "amount": 15 } },
        { "id": "redactionOrdinance", "cadenceTicks": 90, "range": 800, "projectileSpeed": 420, "projectileRadius": 10, "targetingRule": "nearestCamera", "payload": { "kind": "disableCameraSensors", "durationTicks": 180 } },
        { "id": "identityTransponder", "cadenceTicks": 120, "range": 700, "projectileSpeed": 360, "projectileRadius": 9, "targetingRule": "nearestCamera", "payload": { "kind": "spoofCameraSensors", "durationTicks": 240, "suspicionMultiplier": 0.25 } },
        { "id": "foiaSwarm", "cadenceTicks": 75, "range": 700, "projectileSpeed": 320, "projectileRadius": 7, "targetingRule": "nearestThreat", "payload": { "kind": "processing", "durationTicks": 180, "slowMultiplier": 0.5, "damagePerTick": 0.12 } },
        { "id": "mirrorArray", "cadenceTicks": 180, "range": 0, "projectileSpeed": 0, "projectileRadius": 34, "targetingRule": "nearestCamera", "payload": { "kind": "damage", "amount": 15 } },
        { "id": "signalFlood", "cadenceTicks": 300, "range": 360, "projectileSpeed": 0, "projectileRadius": 360, "targetingRule": "nearestCamera", "payload": { "kind": "signalFlood", "radius": 360, "durationTicks": 150, "suspicionSpike": 10 } }
      ]
    }
    """.data(using: .utf8)!
    let catalog = try JSONDecoder().decode(ContentCatalog.self, from: payload)
    #expect(throws: ContentCatalogError.invalidWeaponDefinition) {
        try catalog.validate()
    }
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
    #expect(catalog.sensorDefinition(.parkingLotDrone).movementStyle == .stationary)
    #expect(catalog.sensorDefinition(.smartDoorbellSwarm).movementStyle == .stationary)
    #expect(catalog.sensorDefinition(.lprCameraPole).rotationSpeed > 0)
    #expect(catalog.sensors.allSatisfy { $0.movementStyle == .stationary })
}

@Test func bundledWaveCatalogPreservesSpawnCadenceContract() throws {
    let catalog = try WaveCatalog.loadBundled()
    #expect(catalog.schemaVersion == WaveCatalog.currentSchemaVersion)
    #expect(catalog.guardSpawnIntervalTicks == 60)
    #expect(catalog.sensorSpawnIntervalTicks == 1_080)
    // The global ceiling must not clip any district's authored target.
    #expect(DistrictID.allCases.allSatisfy { catalog.guardPopulationCeiling >= $0.profile.guardMaximumTarget })
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
    #expect(catalog.district(.atlanta).bossPreludeName == "The Public–Private Partnership Chimera")
    #expect(catalog.district(.newYorkCity).researchQualification != nil)
    #expect(catalog.district(.losAngeles).researchQualification != nil)
}

@Test func kineticCountermeasureFiresOnExactCadence() {
    var state = RunState(seed: 19)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -700, y: -360), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: -720, y: -360), health: 60, radius: 22)
    ]
    var simulation = Simulation(state: state, rngSeed: 19)
    var fireTicks: [Int] = []

    for tick in 1...45 {
        let events = simulation.step(input: .init())
        if events.contains(where: { $0.kind == .weaponFired }) {
            fireTicks.append(tick)
        }
    }

    #expect(fireTicks == [15, 30, 45])
}

@Test func autoFireDisabledSuppressesWeaponFire() {
    var state = RunState(seed: 19)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -700, y: -360), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: -720, y: -360), health: 60, radius: 22)
    ]
    var simulation = Simulation(state: state, rngSeed: 19)
    var sawWeaponFire = false
    for _ in 1...45 {
        let events = simulation.step(input: .init(autoFireEnabled: false))
        if events.contains(where: { $0.kind == .weaponFired }) {
            sawWeaponFire = true
        }
    }
    #expect(!sawWeaponFire)
    #expect(simulation.state.entities.contains { $0.kind == .projectile } == false)
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
}

@Test func spawnedProjectileCarriesTypedKineticPayload() {
    var state = RunState(seed: 20)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -500, y: -360), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: -720, y: -360), health: 60, radius: 22)
    ]
    var simulation = Simulation(state: state, rngSeed: 20)
    for _ in 0..<15 { _ = simulation.step(input: .init()) }

    let projectile = simulation.state.entities.first { $0.kind == .projectile }
    #expect(projectile?.sourceWeapon == .kineticCountermeasure)
    #expect(projectile?.payload == .damage(15))
}

@Test func countermeasureHitEmitsTypedEvent() {
    var state = RunState(seed: 21)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -700, y: -360), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: -720, y: -360), health: 60, radius: 22)
    ]
    var simulation = Simulation(state: state, rngSeed: 21)
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

@Test func projectileCapDoesNotSkipLaterDeployableWeapons() {
    var state = RunState(seed: 410)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 80, y: 0), health: 60, radius: 16)
    ]
    for offset in 0..<CombatLimits.maximumProjectiles {
        state.entities.append(
            Entity(
                id: UInt64(1_000 + offset),
                kind: .projectile,
                position: .init(x: Double(offset), y: 400),
                velocity: .init(),
                health: 1,
                radius: 5,
                sourceWeapon: .kineticCountermeasure,
                payload: .damage(1)
            )
        )
    }
    var kinetic = WeaponSystem.baselineKinetic
    kinetic.cadenceTicks = 1
    var flood = WeaponSystem.signalFlood
    flood.cadenceTicks = 1
    state.activeWeapons = [kinetic, flood]
    var simulation = Simulation(state: state, rngSeed: 410)
    let events = simulation.step(input: .init())
    #expect(events.contains { $0.kind == .weaponFired && $0.message.contains("signalFlood") })
    #expect(simulation.state.entities.contains { $0.kind == .signalFlood })
}

@Test func overkillProjectileDamageIsClampedInReceiptTotals() {
    var state = RunState(seed: 411)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 10, y: 0), health: 1, radius: 16),
        Entity(
            id: 3,
            kind: .projectile,
            position: .init(x: 10, y: 0),
            velocity: .init(),
            health: 1,
            radius: 5,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(50)
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 411)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.runReceipt().damageDealt == 1)
}

@Test func bossDoesNotActivateAfterPlayerDiesSameTick() {
    var state = RunState(seed: 412)
    state.suspicion = 100
    state.suspicionTier = .totalVisibility
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 0, radius: 18)
    ]
    var simulation = Simulation(state: state, rngSeed: 412)
    let events = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.state.playerDefeated)
    #expect(simulation.state.runCompleted)
    #expect(events.contains { $0.kind == .bossActivated } == false)
    #expect(simulation.state.entities.contains { $0.kind == .boss } == false)
}

@Test func lethalContactSkipsDirectorAndSpawnOnDeathTick() {
    var state = RunState(seed: 413)
    state.suspicion = 50
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 0.01, radius: 18),
        Entity(
            id: 2,
            kind: .securityGuard,
            guardArchetype: .flashlightCadet,
            position: .init(x: 5, y: 0),
            health: 20,
            radius: 14
        )
    ]
    state.activeWeapons = []
    let guardsBefore = state.entities.filter { $0.kind == .securityGuard }.count
    var simulation = Simulation(state: state, rngSeed: 413)
    let events = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.state.playerDefeated)
    #expect(simulation.state.runCompleted)
    #expect(events.contains { $0.kind == .playerDefeated })
    #expect(events.contains { $0.kind == .directorDecision } == false)
    #expect(simulation.state.entities.filter { $0.kind == .securityGuard }.count == guardsBefore)
}

@Test func suppressThreatContactKeepsPlayerAliveUnderUITestingInput() {
    var state = RunState(seed: 4131)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 0.01, radius: 18),
        Entity(
            id: 2,
            kind: .securityGuard,
            guardArchetype: .flashlightCadet,
            position: .init(x: 5, y: 0),
            health: 20,
            radius: 14
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 4131)
    _ = simulation.step(
        input: .init(autoFireEnabled: false, suppressThreatContact: true)
    )
    #expect(simulation.state.playerDefeated == false)
    #expect(simulation.state.runCompleted == false)
    #expect((simulation.state.entities.first { $0.kind == .player }?.health ?? 0) > 0)
}

@Test func landmarkMinimumTierFloorRaisesSuspicionWhileInside() {
    var state = RunState(seed: 414, district: .wichita)
    let encounter = LandmarkEncounterCatalog.bundled.primary(for: .wichita)!
    #expect(encounter.bossHooks.minimumTierRaw == 3)
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].position = encounter.center
        state.entities[playerIndex].health = 1_000_000
    }
    state.suspicion = 0
    state.suspicionTier = .backgroundNoise
    var simulation = Simulation(state: state, rngSeed: 414)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let floor = SuspicionCatalog.bundled.tierThresholds[2]
    #expect(simulation.state.suspicion >= floor)
    #expect(simulation.state.suspicionTier.rawValue >= 3)
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
    // Unlock card effect must apply on first acquisition (not only on a later restack).
    let baselineCadence = ContentCatalog.bundled.weapon(.redactionOrdinance).weaponSystem().cadenceTicks
    let redaction = simulation.state.activeWeapons.first { $0.id == .redactionOrdinance }
    #expect(redaction != nil)
    #expect(redaction!.cadenceTicks < baselineCadence)
    #expect(redaction!.cadenceTicks == max(30, baselineCadence - 10))
}

@Test func highSpeedProjectileCannotTunnelThroughCameraPole() {
    // Thin target between pre-step origin and post-step end so discrete end-point
    // collision would miss (end is past the target), while swept collision hits.
    var state = RunState(seed: 77)
    state.activeWeapons = []
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -200, y: 0), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 50, y: 0), health: 100, radius: 8),
        Entity(
            id: 3,
            kind: .projectile,
            position: .init(x: 0, y: 0),
            velocity: .init(x: 6_000, y: 0),
            health: 1,
            radius: 4,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(25)
        )
    ]
    // fixedStep 1/60 → after move x=100; true origin 0→100 crosses x=50.
    var simulation = Simulation(state: state, rngSeed: 77)
    let events = simulation.step(input: .init(autoFireEnabled: false))

    #expect(events.contains { $0.kind == .countermeasureHit && $0.message.contains("Dealt 25") })
    #expect(simulation.state.entities.contains { $0.id == 2 && $0.health < 100 })
    #expect(!simulation.state.entities.contains { $0.id == 3 && $0.health > 0 })
}

@Test func sameTickFiredProjectileDoesNotInventReversePhantomHit() {
    // Front camera is the intended target; rear camera sits behind the player.
    // Reconstructing previous = current - velocity*dt invents a reverse segment that
    // wrongly damages the rear target on the fire tick. Newly fired projectiles must
    // use a degenerate segment at spawn until they actually move next step.
    var state = RunState(seed: 91)
    var kinetic = ContentCatalog.bundled.weapon(.kineticCountermeasure).weaponSystem()
    kinetic.cadenceTicks = 1
    kinetic.projectileSpeed = 6_000
    kinetic.range = 800
    state.activeWeapons = [kinetic]
    // Front is nearer so kinetic aims +x; rear is farther behind and must never take
    // a reverse phantom hit from velocity reconstruction on the fire tick.
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
        Entity(id: 10, kind: .cameraPole, position: .init(x: 50, y: 0), health: 100, radius: 10),
        Entity(id: 11, kind: .cameraPole, position: .init(x: -120, y: 0), health: 100, radius: 10)
    ]
    var simulation = Simulation(state: state, rngSeed: 91)
    _ = simulation.step(input: .init(autoFireEnabled: true))

    let rear = simulation.state.entities.first { $0.id == 11 }
    #expect(rear?.health == 100, "Rear camera must not take phantom reverse-segment damage on fire tick")
    // Advance one more step so the dart moves along +x and can hit the front pole only.
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let frontAfter = simulation.state.entities.first { $0.id == 10 }
    let rearAfter = simulation.state.entities.first { $0.id == 11 }
    #expect(rearAfter?.health == 100)
    #expect((frontAfter?.health ?? 100) < 100)
}

@Test func sweptProjectileHitsNearestTargetAlongPathNotArrayOrder() {
    // Far camera has a lower entity index; near camera is later in the array.
    // Continuous collision must pick minimum intersection t (near), not first(where:).
    var state = RunState(seed: 92)
    state.activeWeapons = []
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: -200, y: 0), health: 100, radius: 18),
        Entity(id: 20, kind: .cameraPole, position: .init(x: 90, y: 0), health: 100, radius: 8),
        Entity(id: 21, kind: .cameraPole, position: .init(x: 25, y: 0), health: 100, radius: 8),
        Entity(
            id: 30,
            kind: .projectile,
            position: .init(x: 0, y: 0),
            velocity: .init(x: 6_000, y: 0),
            health: 1,
            radius: 4,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(15)
        )
    ]
    var simulation = Simulation(state: state, rngSeed: 92)
    _ = simulation.step(input: .init(autoFireEnabled: false))

    let far = simulation.state.entities.first { $0.id == 20 }
    let near = simulation.state.entities.first { $0.id == 21 }
    #expect(far?.health == 100, "Farther camera must not absorb the hit when nearer intersects first")
    #expect((near?.health ?? 100) < 100)
    #expect(!simulation.state.entities.contains { $0.id == 30 && $0.health > 0 })
}

@Test func signalFloodMarkerExpiresWithPayloadDurationNotHardcoded18() {
    var state = RunState(seed: 93)
    let flood = ContentCatalog.bundled.weapon(.signalFlood).weaponSystem()
    guard case let .signalFlood(_, durationTicks, _) = flood.payload else {
        Issue.record("signalFlood payload missing")
        return
    }
    var weapon = flood
    weapon.cadenceTicks = 1
    state.activeWeapons = [weapon]
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 50, y: 0), health: 100, radius: 16)
    ]
    var simulation = Simulation(state: state, rngSeed: 93)
    _ = simulation.step(input: .init(autoFireEnabled: true))

    let marker = simulation.state.entities.first { $0.kind == .signalFlood }
    #expect(marker != nil)
    let expectedTicks = max(1 as UInt64, min(durationTicks, 180))
    // Fire happens on tick 1 after step increments tick.
    #expect(marker?.effectExpiresAtTick == 1 + expectedTicks)
    #expect(marker?.effectExpiresAtTick != 1 + 18 || expectedTicks == 18)
}

@Test func guardSpawnMaintainsPlayerClearance() {
    // The spawn ring is centred on the player, so ring angles alone always land a
    // full radius away and cannot exercise the push-out repair. Bounds clamping is
    // what brings a spawn in close: with the player tucked into a corner, most of the
    // ring falls outside the world and clamps back toward them. Without the push-out
    // those clamped spawns land inside minClearance (radius + player.radius + 80).
    // Assert only on the spawn tick — guards intentionally chase afterward.
    let minExtra: Double = 80
    var state = RunState(seed: 7)
    let corner = Vector2(x: state.world.bounds.maxX - 20, y: state.world.bounds.maxY - 20)
    state.entities = [
        Entity(id: 1, kind: .player, position: corner, health: 10_000, radius: 18)
    ]
    var simulation = Simulation(state: state, rngSeed: 7)
    var seenIDs: Set<UInt64> = []
    var nearSpawnObserved = false
    var spawnCount = 0
    for _ in 0..<2_400 {
        _ = simulation.step(input: .init(autoFireEnabled: false))
        guard let player = simulation.state.entities.first(where: { $0.kind == .player }) else {
            Issue.record("player missing")
            return
        }
        for guardEntity in simulation.state.entities where guardEntity.kind == .securityGuard {
            if seenIDs.contains(guardEntity.id) { continue }
            seenIDs.insert(guardEntity.id)
            spawnCount += 1
            let clearance = guardEntity.radius + player.radius + minExtra
            let distance = (guardEntity.position - player.position).magnitude
            #expect(
                distance + 1e-6 >= clearance,
                "spawn-tick guard \(guardEntity.id) distance \(distance) < clearance \(clearance)"
            )
            // Chord near the player forces the push branch (not only far-ring luck).
            if distance < clearance + 40 {
                nearSpawnObserved = true
            }
        }
    }
    #expect(spawnCount > 0, "expected at least one contract guard to spawn")
    #expect(
        nearSpawnObserved,
        "expected at least one bounds-clamped spawn close enough to force the clearance push"
    )
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
    // Ongoing FOIA tick damage must appear on the receipt (not only direct hits).
    #expect(simulation.runReceipt().damageDealt > 0)
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

@Test func signalFloodSuspicionTierSyncsOnSameTickDefeat() {
    var state = RunState(seed: 0xF100D)
    state.suspicion = 94
    state.suspicionTier = .narrativeLock
    // Health already lethal so the post-combat early-return skips updateSuspicion;
    // flood must still sync tier when it spikes suspicion.
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 0, radius: 18)
    ]
    var flood = WeaponSystem.signalFlood
    flood.cadenceTicks = 1
    state.activeWeapons = [flood]
    var simulation = Simulation(state: state, rngSeed: 0xF100D)
    let events = simulation.step(input: .init())
    #expect(events.contains { $0.kind == .weaponFired && $0.message.contains("signalFlood") })
    #expect(simulation.state.suspicion >= 100 - 0.001)
    #expect(simulation.state.suspicionTier == SuspicionCatalog.bundled.tier(for: simulation.state.suspicion))
    #expect(simulation.state.suspicionTier == .totalVisibility)
    #expect(events.contains { $0.kind == .tierChanged })
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

@Test func defeatingBossAtTotalVisibilityDoesNotRespawnReplacement() {
    // Regression: activate-before-deaths respawned a live boss on the kill tick.
    var state = RunState(seed: 311)
    state.suspicion = 100
    state.suspicionTier = .totalVisibility
    state.entities.append(Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42))
    var simulation = Simulation(state: state, rngSeed: 311)

    let events = simulation.step(input: .init())

    #expect(simulation.state.bossDefeated)
    #expect(simulation.state.extractionOpen)
    #expect(events.contains { $0.kind == .extractionOpened })
    #expect(events.contains { $0.kind == .bossActivated } == false)
    #expect(simulation.state.entities.filter { $0.kind == .boss }.isEmpty)
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
    #expect(simulation.state.playerDefeated == false)
    #expect(firstEvents.contains { $0.kind == .extractionCompleted })
    #expect(secondEvents.contains { $0.kind == .extractionCompleted } == false)
    #expect(simulation.runReceipt().extractionCompleted)
}

@Test func guardContactDamagesThePlayerDeterministically() {
    var state = RunState(seed: 45)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .securityGuard,
            guardArchetype: .flashlightCadet,
            position: .init(x: 10, y: 0),
            health: 20,
            radius: 14
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 45)

    for _ in 0..<60 { _ = simulation.step(input: .init()) }

    let player = simulation.state.entities.first { $0.kind == .player }!
    #expect(player.health < 100)
    #expect(simulation.runReceipt().damageTaken > 0)
}

@Test func disruptedGuardsDoNotDealContactDamage() {
    var state = RunState(seed: 46)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .securityGuard,
            guardArchetype: .flashlightCadet,
            position: .init(x: 10, y: 0),
            health: 20,
            radius: 14,
            disruptedUntilTick: 10_000
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 46)

    for _ in 0..<60 { _ = simulation.step(input: .init()) }

    let player = simulation.state.entities.first { $0.kind == .player }!
    #expect(player.health == 100)
    #expect(simulation.runReceipt().damageTaken == 0)
}

@Test func playerDefeatEndsTheRunWithoutExtraction() {
    var state = RunState(seed: 47)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1, radius: 18),
        Entity(
            id: 2,
            kind: .securityGuard,
            guardArchetype: .tacticalPolo,
            position: .init(x: 5, y: 0),
            health: 18,
            radius: 14
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 47)
    var events: [RunEvent] = []

    for _ in 0..<180 {
        events += simulation.step(input: .init())
        if simulation.state.runCompleted { break }
    }

    #expect(simulation.state.playerDefeated)
    #expect(simulation.state.runCompleted)
    #expect(events.contains { $0.kind == .playerDefeated })
    #expect(simulation.runReceipt().extractionCompleted == false)
    #expect(simulation.runReceipt().damageTaken > 0)
}

@Test func forcedBossDefeatOpensBlindSpotAndExtractionCompletesReceipt() {
    var state = RunState(seed: 48)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
        Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42)
    ]
    var simulation = Simulation(state: state, rngSeed: 48)
    let openEvents = simulation.step(input: .init())

    #expect(simulation.state.bossDefeated)
    #expect(simulation.state.extractionOpen)
    #expect(openEvents.contains { $0.kind == .extractionOpened })
    #expect(simulation.state.playerDefeated == false)

    guard let playerIndex = simulation.state.entities.firstIndex(where: { $0.kind == .player }),
          let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
        Issue.record("Expected player and extraction entities after boss defeat")
        return
    }

    var completionState = simulation.state
    completionState.entities[playerIndex].position = extraction.position
    var completion = Simulation(state: completionState, rngSeed: 48)
    let finishEvents = completion.step(input: .init())

    #expect(completion.state.runCompleted)
    #expect(finishEvents.contains { $0.kind == .extractionCompleted })
    #expect(completion.runReceipt().extractionCompleted)
    #expect(completion.runReceipt().damageTaken == 0)
}

// MARK: - District simulation profiles

@Test func wichitaPreservesTheVerticalSliceLayout() {
    let generated = DistrictGenerator.generate(seed: 808, district: .wichita)

    #expect(generated.layout.bounds == WorldBounds(minX: -1350, maxX: 1350, minY: -810, maxY: 810))
    #expect(generated.layout.obstacles.map(\.center) == [
        .init(x: -630, y: -375),
        .init(x: 630, y: -375),
        .init(x: -630, y: 375),
        .init(x: 630, y: 375),
        .init(x: 0, y: 0)
    ])
    #expect(generated.sensors.count == 4)
    #expect(generated.sensors.allSatisfy { $0.sensorArchetype == .lprCameraPole })
}

@Test func everyDistrictAuthorsATraversableWorld() {
    for district in DistrictID.allCases {
        let profile = district.profile
        let generated = DistrictGenerator.generate(seed: 99, district: district)

        func isBlocked(_ point: Vector2) -> Bool {
            generated.layout.obstacles.contains { obstacle in
                abs(point.x - obstacle.center.x) <= obstacle.halfSize.x
                    && abs(point.y - obstacle.center.y) <= obstacle.halfSize.y
            }
        }

        #expect(generated.layout.bounds.contains(profile.playerSpawn), "\(district.rawValue) spawns the player outside its bounds")
        #expect(isBlocked(profile.playerSpawn) == false, "\(district.rawValue) spawns the player inside an obstacle")
        #expect(isBlocked(profile.bossSpawn) == false, "\(district.rawValue) spawns its authority inside an obstacle")
        #expect(isBlocked(profile.extractionPosition) == false, "\(district.rawValue) buries its Blind Spot inside an obstacle")
        #expect(generated.sensors.allSatisfy { generated.layout.bounds.contains($0.position) }, "\(district.rawValue) places a sensor outside its bounds")
        #expect(generated.sensors.allSatisfy { isBlocked($0.position) == false }, "\(district.rawValue) places a sensor inside an obstacle")
    }
}

@Test func oaklandDefersTheOpeningDroneUntilDeployment() {
    let generated = DistrictGenerator.generate(seed: 99, district: .oakland)
    #expect(generated.sensors.count == 4)
    #expect(generated.sensors.allSatisfy { $0.sensorArchetype == .lprCameraPole })
    #expect(DistrictID.oakland.profile.sensorDeploymentOrder.first == .parkingLotDrone)
}

@Test func sanFranciscoDefersTheOpeningDroneUntilDeployment() {
    let generated = DistrictGenerator.generate(seed: 99, district: .sanFrancisco)
    #expect(generated.sensors.count == 3)
    #expect(generated.sensors.allSatisfy { $0.sensorArchetype != .parkingLotDrone })
    #expect(DistrictID.sanFrancisco.profile.sensorDeploymentOrder.first == .parkingLotDrone)
}

@Test func sanFranciscoPolicyPhasesUseFourDistinctExpandingObservationBands() {
    let maximumHealth = 180.0
    let resolved = [
        SanFranciscoPolicyPhase.resolve(health: 180, maximumHealth: maximumHealth),
        SanFranciscoPolicyPhase.resolve(health: 120, maximumHealth: maximumHealth),
        SanFranciscoPolicyPhase.resolve(health: 70, maximumHealth: maximumHealth),
        SanFranciscoPolicyPhase.resolve(health: 20, maximumHealth: maximumHealth),
    ]

    #expect(resolved == [.publicSafety, .civilLiberties, .temporarySafeguard, .independentReview])
    #expect(Set(resolved.map(\.movementSpeedMultiplier)).count == 4)
    #expect(Set(resolved.map(\.contactDamageMultiplier)).count == 4)
    #expect(resolved.allSatisfy { $0.observationMultiplier > 1 })
    #expect(zip(resolved, resolved.dropFirst()).allSatisfy { $0.observationMultiplier < $1.observationMultiplier })
}

@Test func columbusDefersTheOpeningPredictiveNodeUntilDeployment() {
    let generated = DistrictGenerator.generate(seed: 99, district: .columbus)
    #expect(generated.sensors.count == 4)
    #expect(generated.sensors.allSatisfy { $0.sensorArchetype == .lprCameraPole })
    #expect(DistrictID.columbus.profile.sensorDeploymentOrder.first == .predictivePatrolNode)
}

@Test func columbusReviewPhasesUseFourDistinctExpandingObservationBands() {
    let maximumHealth = 200.0
    let resolved = [
        ColumbusReviewPhase.resolve(health: 200, maximumHealth: maximumHealth),
        ColumbusReviewPhase.resolve(health: 130, maximumHealth: maximumHealth),
        ColumbusReviewPhase.resolve(health: 80, maximumHealth: maximumHealth),
        ColumbusReviewPhase.resolve(health: 20, maximumHealth: maximumHealth),
    ]

    #expect(resolved == [.publicComment, .meaningfulReview, .rescheduled, .routeTransfer])
    #expect(Set(resolved.map(\.movementSpeedMultiplier)).count == 4)
    #expect(Set(resolved.map(\.contactDamageMultiplier)).count == 4)
    #expect(resolved.allSatisfy { $0.observationMultiplier > 1 })
    #expect(zip(resolved, resolved.dropFirst()).allSatisfy { $0.observationMultiplier < $1.observationMultiplier })
}

@Test func newYorkDefersAdvancedOpeningSensorsUntilDeployment() {
    let generated = DistrictGenerator.generate(seed: 99, district: .newYorkCity)
    #expect(generated.sensors.count == 4)
    #expect(generated.sensors.allSatisfy { $0.sensorArchetype == .lprCameraPole })
    #expect(DistrictID.newYorkCity.profile.sensorDeploymentOrder.prefix(2) == [.panTiltZoomEye, .smartDoorbellSwarm])
}

@Test func newYorkBoroughPhasesUseSixDistinctExpandingObservationBands() {
    let maximumHealth = 230.0
    let resolved = [230.0, 180, 140, 100, 60, 20].map {
        NewYorkBoroughPhase.resolve(health: $0, maximumHealth: maximumHealth)
    }

    #expect(resolved == [.manhattan, .brooklyn, .queens, .bronx, .statenIsland, .realTimeCity])
    #expect(Set(resolved.map(\.movementSpeedMultiplier)).count == 6)
    #expect(Set(resolved.map(\.contactDamageMultiplier)).count == 6)
    #expect(resolved.allSatisfy { $0.observationMultiplier > 1 })
    #expect(zip(resolved, resolved.dropFirst()).allSatisfy { $0.observationMultiplier < $1.observationMultiplier })
}

@Test func losAngelesDefersTheOpeningDroneUntilDeployment() {
    let generated = DistrictGenerator.generate(seed: 99, district: .losAngeles)
    #expect(generated.sensors.count == 5)
    #expect(generated.sensors.filter { $0.sensorArchetype == .lprCameraPole }.count == 4)
    #expect(generated.sensors.filter { $0.sensorArchetype == .smartDoorbellSwarm }.count == 1)
    #expect(generated.sensors.allSatisfy { $0.sensorArchetype != .parkingLotDrone })
    #expect(DistrictID.losAngeles.profile.sensorDeploymentOrder.first == .parkingLotDrone)
}

@Test func losAngelesLiabilityPhasesUseFiveDistinctExpandingObservationBands() {
    let maximumHealth = 260.0
    let resolved = [260.0, 190, 140, 80, 20].map {
        LosAngelesLiabilityPhase.resolve(health: $0, maximumHealth: maximumHealth)
    }

    #expect(resolved == [.cityStatement, .privateOperator, .vendor, .subcontractor, .noResponsibleParty])
    #expect(Set(resolved.map(\.movementSpeedMultiplier)).count == 5)
    #expect(Set(resolved.map(\.contactDamageMultiplier)).count == 5)
    #expect(resolved.allSatisfy { $0.observationMultiplier > 1 })
    #expect(zip(resolved, resolved.dropFirst()).allSatisfy { $0.observationMultiplier < $1.observationMultiplier })
}

@Test func atlantaStagesAdvancedFinaleSensorsAfterThePredictiveOpening() {
    let generated = DistrictGenerator.generate(seed: 99, district: .atlanta)
    #expect(generated.sensors.count == 5)
    #expect(generated.sensors.filter { $0.sensorArchetype == .lprCameraPole }.count == 4)
    #expect(generated.sensors.filter { $0.sensorArchetype == .predictivePatrolNode }.count == 1)
    #expect(generated.sensors.allSatisfy { ![SensorArchetype.panTiltZoomEye, .acousticGunshotDetector].contains($0.sensorArchetype) })
    #expect(DistrictID.atlanta.profile.sensorDeploymentOrder.prefix(2) == [.acousticGunshotDetector, .panTiltZoomEye])
}

@Test func atlantaConvergencePhasesUseSixDistinctExpandingObservationBands() {
    let maximumHealth = 300.0
    let resolved = [300.0, 230, 180, 130, 70, 20].map {
        AtlantaConvergencePhase.resolve(health: $0, maximumHealth: maximumHealth)
    }

    #expect(resolved == [.localNode, .regionalPartner, .nationalSearch, .partnershipChimera, .objectiveEvidence, .safetyEvangelist])
    #expect(Set(resolved.map(\.movementSpeedMultiplier)).count == 6)
    #expect(Set(resolved.map(\.contactDamageMultiplier)).count == 6)
    #expect(resolved.allSatisfy { $0.observationMultiplier > 1 })
    #expect(zip(resolved, resolved.dropFirst()).allSatisfy { $0.observationMultiplier < $1.observationMultiplier })
    #expect(DistrictID.atlanta.definition.researchQualification != nil)
}

@Test func districtProfilesEscalateAcrossTheCampaign() {
    let ordered = DistrictCatalog.bundled.districts.sorted { $0.level < $1.level }

    for (earlier, later) in zip(ordered, ordered.dropFirst()) {
        #expect(later.simulation.guardMaximumTarget >= earlier.simulation.guardMaximumTarget)
        #expect(later.simulation.suspicionPressureMultiplier >= earlier.simulation.suspicionPressureMultiplier)
        #expect(later.simulation.bossHealthMultiplier >= earlier.simulation.bossHealthMultiplier)
        #expect(later.simulation.bossContactDamageMultiplier >= earlier.simulation.bossContactDamageMultiplier)
    }
    #expect(ordered.first?.simulation.suspicionPressureMultiplier == 1)
    #expect(ordered.last?.simulation.bossHealthMultiplier ?? 0 > 1)
}

@Test func districtSelectionChangesTheGeneratedWorld() {
    let plains = RunState(seed: 60, district: .wichita)
    let boroughs = RunState(seed: 60, district: .newYorkCity)

    #expect(plains.district == .wichita)
    #expect(boroughs.district == .newYorkCity)
    #expect(plains.world.bounds != boroughs.world.bounds)
    #expect(plains.world.obstacles.count != boroughs.world.obstacles.count)
    #expect(plains.entities.first { $0.kind == .player }?.position == DistrictID.wichita.profile.playerSpawn)
    #expect(boroughs.entities.first { $0.kind == .player }?.position == DistrictID.newYorkCity.profile.playerSpawn)
}

@Test func districtRunsRemainDeterministic() {
    var first = Simulation(seed: 71, district: .oakland)
    var second = Simulation(seed: 71, district: .oakland)

    for _ in 0..<900 {
        _ = first.step(input: .init(movement: .init(x: 1, y: 0)))
        _ = second.step(input: .init(movement: .init(x: 1, y: 0)))
    }

    #expect(first.state == second.state)
    #expect(first.runReceipt() == second.runReceipt())
}

@Test func districtSuspicionMultiplierScalesObservationPressure() {
    func observedSuspicion(in district: DistrictID) -> Double {
        var state = RunState(seed: 61, district: district)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
            Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole, position: .init(x: 100, y: 0), heading: .pi, health: 60, radius: 20)
        ]
        state.activeWeapons = []
        var simulation = Simulation(state: state, rngSeed: 61)
        for _ in 0..<30 { _ = simulation.step(input: .init()) }
        return simulation.state.suspicion
    }

    let plains = observedSuspicion(in: .wichita)
    let nest = observedSuspicion(in: .atlanta)

    #expect(plains > 0)
    #expect(nest > plains)
    #expect(abs(nest - plains * DistrictID.atlanta.profile.suspicionPressureMultiplier) < 0.000_1)
}

@Test func districtGuardRosterDrivesContractSecurityOrder() {
    var state = RunState(seed: 63, district: .louisville)
    state.activeWeapons = []
    // Tier-driven population: alarm the district so the roster cycles.
    state.suspicion = 100
    state.suspicionTier = .totalVisibility
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 63)

    for _ in 0..<1_260 { _ = simulation.step(input: .init()) }

    let roster = DistrictID.louisville.profile.guardRoster
    let spawned = simulation.state.entities.compactMap(\.guardArchetype)
    // Director may raise the population target, so assert cyclic roster order rather
    // than exact one-pass length.
    #expect(spawned.count >= roster.count)
    #expect(Array(spawned.prefix(roster.count)) == roster)
    for (index, archetype) in spawned.enumerated() {
        #expect(archetype == roster[index % roster.count])
    }
    #expect(spawned != DistrictID.wichita.profile.guardRoster)
}

@Test func districtSensorDeploymentOrderDrivesEscalation() {
    var state = RunState(seed: 64, district: .louisville)
    state.activeWeapons = []
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 64)

    let order = DistrictID.louisville.profile.sensorDeploymentOrder
    for _ in 0..<(1_080 * order.count) { _ = simulation.step(input: .init()) }

    let deployed = simulation.state.entities
        .compactMap(\.sensorArchetype)
        .dropFirst(DistrictID.louisville.profile.startingSensors.count)
    #expect(Array(deployed) == order)
}

@Test func destroyingSensorsDoesNotReopenDeploymentBudget() {
    // Start without authored cameras so live-count budgeting cannot hide behind the
    // startingSensors offset. Lifetime ordinal must still cap at deploymentOrder.count.
    var state = RunState(seed: 0x5E45, district: .louisville)
    state.activeWeapons = []
    state.entities.removeAll { $0.kind == .cameraPole }
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    let order = DistrictID.louisville.profile.sensorDeploymentOrder
    let interval = WaveCatalog.bundled.sensorSpawnIntervalTicks
    var simulation = Simulation(state: state, rngSeed: 0x5E45)

    for _ in 0..<(Int(interval) * order.count) {
        _ = simulation.step(input: .init(autoFireEnabled: false))
    }
    #expect(simulation.state.entities.filter { $0.kind == .cameraPole }.count == order.count)

    // Continue well past another full cadence cycle — no replacements.
    for _ in 0..<(Int(interval) * order.count * 2) {
        _ = simulation.step(input: .init(autoFireEnabled: false))
    }
    #expect(simulation.state.entities.filter { $0.kind == .cameraPole }.count == order.count)

    // Prepared wipe must also honor lifetime deployments restored from run state.
    var wiped = simulation.state
    wiped.entities.removeAll { $0.kind == .cameraPole }
    wiped.escalationSensorsDeployed = UInt64(order.count)
    var resumed = Simulation(state: wiped, rngSeed: 0x5E45)
    for _ in 0..<Int(interval) * 2 {
        _ = resumed.step(input: .init(autoFireEnabled: false))
    }
    #expect(resumed.state.entities.filter { $0.kind == .cameraPole }.isEmpty)
}

@Test func districtBossScalingAppliesAuthoredMultipliers() {
    var state = RunState(seed: 62, district: .atlanta)
    state.suspicion = 100
    var simulation = Simulation(state: state, rngSeed: 62)

    let events = simulation.step(input: .init())

    guard let boss = simulation.state.entities.first(where: { $0.kind == .boss }) else {
        Issue.record("Expected the district authority to activate at total visibility")
        return
    }
    let profile = DistrictID.atlanta.profile
    #expect(boss.health == BossCatalog.bundled.shiftManagerHealth * profile.bossHealthMultiplier)
    #expect(boss.position == state.world.bounds.clamped(profile.bossSpawn, margin: BossCatalog.bundled.shiftManagerRadius))
    #expect(events.contains { $0.kind == .bossActivated && $0.message.contains(DistrictID.atlanta.bossName) })
}

@Test func districtExtractionOpensAtTheAuthoredBlindSpot() {
    var state = RunState(seed: 65, district: .columbus)
    state.entities.append(Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42))
    var simulation = Simulation(state: state, rngSeed: 65)

    _ = simulation.step(input: .init())

    let extraction = simulation.state.entities.first { $0.kind == .extraction }
    #expect(simulation.state.extractionOpen)
    #expect(extraction?.position == DistrictID.columbus.profile.extractionPosition)
}

@Test func runReceiptRecordsItsDistrict() {
    var simulation = Simulation(seed: 66, district: .tulsa)
    for _ in 0..<60 { _ = simulation.step(input: .init()) }

    let receipt = simulation.runReceipt()
    #expect(receipt.district == .tulsa)
    #expect(receipt.schemaVersion == RunReceipt.schemaVersion)
    #expect(Simulation(seed: 66).runReceipt().district == .wichita)
}

@Test func bundledDistrictCatalogValidatesEverySimulationProfile() throws {
    let catalog = try DistrictCatalog.loadBundled()
    #expect(catalog.districts.allSatisfy { $0.simulation.isValid })
    #expect(catalog.districts.allSatisfy { !$0.simulation.startingSensors.isEmpty })
    #expect(catalog.districts.allSatisfy { Set($0.simulation.guardRoster).count == $0.simulation.guardRoster.count })
}

@Test func signalFloodWithoutTargetsDoesNotEmitCountermeasureHit() {
    var state = RunState(seed: 900)
    var flood = WeaponSystem.signalFlood
    flood.cadenceTicks = 1
    state.activeWeapons = [flood]
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18)
    ]
    var simulation = Simulation(state: state, rngSeed: 900)
    let events = simulation.step(input: .init(autoFireEnabled: true))
    #expect(events.contains { $0.kind == .weaponFired && $0.message.contains("signalFlood") })
    #expect(!events.contains { $0.kind == .countermeasureHit })
}

@Test func signalFloodEmitsCoordinationSignalsOnlyForHitKinds() {
    // Active chain link interrupts only on guardDisrupted; camera-only flood must not interrupt.
    var cameraOnly = RunState(seed: 901, district: .wichita)
    let started = CoordinationEngine.startIfNeeded(
        state: .idle,
        district: .wichita,
        elapsed: 0,
        tick: 1,
        signal: "sensorContact"
    )
    cameraOnly.coordination = started.state
    // Advance to patrolReroute (guardDisrupted interrupt).
    cameraOnly.coordination.activeLinkIndex = 2
    cameraOnly.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 40, y: 0), health: 60, radius: 16)
    ]
    var flood = WeaponSystem.signalFlood
    flood.cadenceTicks = 1
    cameraOnly.activeWeapons = [flood]
    var cameraSim = Simulation(state: cameraOnly, rngSeed: 901)
    _ = cameraSim.step(input: .init(autoFireEnabled: true))
    #expect(cameraSim.state.coordination.chainId != nil)
    #expect(cameraSim.state.coordination.interruptedCount == 0)

    // Guard-only flood must not interrupt a sensorDisabled link (sensorDetect).
    var guardOnly = RunState(seed: 902, district: .wichita)
    guardOnly.coordination = started.state
    guardOnly.coordination.activeLinkIndex = 0
    guardOnly.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .securityGuard, guardArchetype: .flashlightCadet, position: .init(x: 40, y: 0), health: 40, radius: 16)
    ]
    guardOnly.activeWeapons = [flood]
    var guardSim = Simulation(state: guardOnly, rngSeed: 902)
    _ = guardSim.step(input: .init(autoFireEnabled: true))
    #expect(guardSim.state.coordination.chainId != nil)
    #expect(guardSim.state.coordination.interruptedCount == 0)

    // Camera flood on sensorDetect must interrupt via sensorDisabled.
    var cameraInterrupt = RunState(seed: 903, district: .wichita)
    cameraInterrupt.coordination = started.state
    cameraInterrupt.coordination.activeLinkIndex = 0
    cameraInterrupt.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 40, y: 0), health: 60, radius: 16)
    ]
    cameraInterrupt.activeWeapons = [flood]
    var interruptSim = Simulation(state: cameraInterrupt, rngSeed: 903)
    _ = interruptSim.step(input: .init(autoFireEnabled: true))
    #expect(interruptSim.state.coordination.chainId == nil)
    #expect(interruptSim.state.coordination.interruptedCount >= 1)
}

@Test func redactionProjectileIgnoresGuardsAndKeepsFlying() {
    var state = RunState(seed: 904)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .securityGuard, guardArchetype: .flashlightCadet, position: .init(x: 20, y: 0), health: 40, radius: 16),
        Entity(
            id: 3,
            kind: .projectile,
            position: .init(x: 20, y: 0),
            velocity: .init(x: 40, y: 0),
            health: 1,
            radius: 6,
            sourceWeapon: .redactionOrdinance,
            payload: .disableCameraSensors(durationTicks: 120)
        )
    ]
    var simulation = Simulation(state: state, rngSeed: 904)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let projectile = simulation.state.entities.first { $0.id == 3 }
    let threat = simulation.state.entities.first { $0.id == 2 }
    #expect(projectile?.health == 1)
    #expect(threat?.health == 40)
    #expect(threat?.disruptedUntilTick == nil)
}

@Test func foiaProjectileIgnoresCamerasAndKeepsFlying() {
    var state = RunState(seed: 905)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 20, y: 0), health: 60, radius: 16),
        Entity(
            id: 3,
            kind: .projectile,
            position: .init(x: 20, y: 0),
            velocity: .init(x: 40, y: 0),
            health: 1,
            radius: 6,
            sourceWeapon: .foiaSwarm,
            payload: .processing(durationTicks: 90, slowMultiplier: 0.5, damagePerTick: 1)
        )
    ]
    var simulation = Simulation(state: state, rngSeed: 905)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let projectile = simulation.state.entities.first { $0.id == 3 }
    let camera = simulation.state.entities.first { $0.id == 2 }
    #expect(projectile?.health == 1)
    #expect(camera?.health == 60)
    #expect(camera?.processing == nil)
}

@Test func disruptedRadioGuyDoesNotSpeedBuffNearbyGuards() {
    var state = RunState(seed: 906)
    let radioSpeed = GuardArchetype.radioGuy.speed
    let cadetSpeed = GuardArchetype.flashlightCadet.speed
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(x: 400, y: 0), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .securityGuard,
            guardArchetype: .radioGuy,
            position: .init(),
            health: 40,
            radius: 16,
            disruptedUntilTick: 10_000
        ),
        Entity(
            id: 3,
            kind: .securityGuard,
            guardArchetype: .flashlightCadet,
            position: .init(x: 40, y: 0),
            health: 40,
            radius: 16
        )
    ]
    var simulation = Simulation(state: state, rngSeed: 906)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let cadet = simulation.state.entities.first { $0.id == 3 }
    let speed = (cadet?.velocity.magnitude ?? 0)
    #expect(abs(speed - cadetSpeed) < 0.01)
    #expect(abs(speed - cadetSpeed * 1.15) > 1)
    #expect(radioSpeed > 0)
}

@Test func spawnedGuardsAvoidSolidObstacles() {
    var state = RunState(seed: 1, district: .wichita)
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 1)
    for _ in 0..<(60 * 12) {
        _ = simulation.step(input: .init(autoFireEnabled: false))
    }
    let obstacles = simulation.state.world.obstacles
    let spawned = simulation.state.entities.filter { $0.kind == .securityGuard }
    #expect(!spawned.isEmpty)
    for entity in spawned {
        let collides = obstacles.contains { obstacle in
            let x = min(max(entity.position.x, obstacle.center.x - obstacle.halfSize.x), obstacle.center.x + obstacle.halfSize.x)
            let y = min(max(entity.position.y, obstacle.center.y - obstacle.halfSize.y), obstacle.center.y + obstacle.halfSize.y)
            let dx = entity.position.x - x
            let dy = entity.position.y - y
            return dx * dx + dy * dy < entity.radius * entity.radius
        }
        #expect(!collides)
    }
}

@Test func deadGuardsDoNotInflateSuspicionOrBlockSpawns() {
    var state = RunState(seed: 930, district: .wichita)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .securityGuard, guardArchetype: .flashlightCadet, position: .init(x: 80, y: 0), health: 0, radius: 16),
        Entity(id: 3, kind: .securityGuard, guardArchetype: .flashlightCadet, position: .init(x: 120, y: 0), health: 0, radius: 16)
    ]
    // Far sensors so contact pressure is zero; dead guards must not add pressure.
    for index in state.entities.indices where state.entities[index].kind == .cameraPole {
        state.entities[index].position = .init(x: 10_000, y: 10_000)
    }
    state.suspicion = 10
    var simulation = Simulation(state: state, rngSeed: 930)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.state.suspicion <= 10)
    var spawnedLive = false
    for _ in 0..<180 {
        _ = simulation.step(input: .init(autoFireEnabled: false))
        if simulation.state.entities.contains(where: { $0.kind == .securityGuard && $0.health > 0 }) {
            spawnedLive = true
            break
        }
    }
    #expect(spawnedLive)
}

@Test func shortLivedSuspicionSpikeIsCapturedInReceiptPeak() {
    var state = RunState(seed: 931)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18)
    ]
    var flood = WeaponSystem.signalFlood
    flood.cadenceTicks = 1
    state.activeWeapons = [flood]
    state.suspicion = 12
    var simulation = Simulation(state: state, rngSeed: 931)
    _ = simulation.step(input: .init(autoFireEnabled: true))
    let peak = simulation.runReceipt().suspicionTimeline.map(\.value).max() ?? 0
    #expect(peak >= simulation.state.suspicion)
    #expect(peak > 12)
}

@Test func suspicionTierDecreaseDoesNotEmitTierChanged() {
    var state = RunState(seed: 932)
    state.suspicion = 40
    state.suspicionTier = SuspicionCatalog.bundled.tier(for: 40)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18)
    ]
    for index in state.entities.indices where state.entities[index].kind == .cameraPole {
        state.entities[index].position = .init(x: 10_000, y: 10_000)
    }
    var simulation = Simulation(state: state, rngSeed: 932)
    var sawDecreaseWithoutEvent = false
    for _ in 0..<(60 * 8) {
        let prior = simulation.state.suspicionTier
        let events = simulation.step(input: .init(autoFireEnabled: false))
        if simulation.state.suspicionTier.rawValue < prior.rawValue {
            #expect(!events.contains { $0.kind == .tierChanged })
            sawDecreaseWithoutEvent = true
            break
        }
    }
    #expect(sawDecreaseWithoutEvent)
}

@Test func expiredMirrorDoesNotBlockReplacementDeploy() {
    var state = RunState(seed: 940)
    let cap = CombatLimits.maximumPersistentDeployables
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18)
    ]
    for offset in 0..<cap {
        state.entities.append(
            Entity(
                id: UInt64(100 + offset),
                kind: .mirrorArray,
                position: .init(x: Double(offset), y: 0),
                health: 1,
                radius: 20,
                sourceWeapon: .mirrorArray,
                payload: .reflect(durationTicks: 1, damageMultiplier: 1),
                effectExpiresAtTick: 1 // expires on the fire tick
            )
        )
    }
    var mirror = WeaponSystem.mirrorArray
    mirror.cadenceTicks = 1
    state.activeWeapons = [mirror]
    var simulation = Simulation(state: state, rngSeed: 940)
    let events = simulation.step(input: .init(autoFireEnabled: true))
    #expect(events.contains { $0.kind == .weaponFired && $0.message.contains("mirrorArray") })
    let liveMirrors = simulation.state.entities.filter {
        $0.kind == .mirrorArray && (($0.effectExpiresAtTick ?? 0) > 1)
    }
    #expect(!liveMirrors.isEmpty)
}

@Test func mirrorArrayDisableSignalsCoordinationSensorDisabled() {
    var state = RunState(seed: 941, district: .wichita)
    let started = CoordinationEngine.startIfNeeded(
        state: .idle,
        district: .wichita,
        elapsed: 0,
        tick: 1,
        signal: "sensorContact"
    )
    state.coordination = started.state
    state.coordination.activeLinkIndex = 0
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 40, y: 0), health: 60, radius: 16),
        Entity(
            id: 3,
            kind: .mirrorArray,
            position: .init(x: 40, y: 0),
            health: 1,
            radius: 28,
            sourceWeapon: .mirrorArray,
            payload: .reflect(durationTicks: 300, damageMultiplier: 1),
            effectExpiresAtTick: 10_000
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 941)
    // Mirror pulse is every 30 ticks; advance until it fires.
    for _ in 0..<30 {
        _ = simulation.step(input: .init(autoFireEnabled: false))
        if simulation.state.coordination.interruptedCount > 0 { break }
    }
    #expect(simulation.state.coordination.interruptedCount >= 1)
    #expect(simulation.state.coordination.chainId == nil)
}

@Test func simultaneousPlayerAndCameraDeathSkipsShardAndUpgradeProgress() {
    var state = RunState(seed: 920)
    state.dataShards = 0
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 0, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 40, y: 0), health: 0, radius: 16)
    ]
    var simulation = Simulation(state: state, rngSeed: 920)
    let events = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.state.playerDefeated)
    #expect(simulation.state.dataShards == 0)
    #expect(simulation.state.pendingUpgradeChoices.isEmpty)
    #expect(events.contains { $0.kind == .playerDefeated })
    #expect(events.contains { $0.kind == .entityDestroyed && $0.message.contains("cameraPole") })
    #expect(!events.contains { $0.kind == .upgradeOffered })
}

@Test func spentProjectileCleanupIsNotCountedAsEntityDeath() {
    var state = RunState(seed: 921)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .cameraPole, position: .init(x: 10, y: 0), health: 100, radius: 16),
        Entity(
            id: 3,
            kind: .projectile,
            position: .init(x: 10, y: 0),
            velocity: .init(),
            health: 1,
            radius: 5,
            sourceWeapon: .kineticCountermeasure,
            payload: .damage(10)
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 921)
    let events = simulation.step(input: .init(autoFireEnabled: false))
    let receipt = simulation.runReceipt()
    #expect(receipt.deathsByArchetype[.projectile] == nil)
    #expect(!events.contains { $0.kind == .entityDestroyed && $0.message.contains("projectile") })
    #expect(events.contains { $0.kind == .countermeasureHit })
}

@Test func statusProjectileMergeKeepsStrongerEffectValues() {
    var state = RunState(seed: 922)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(
            id: 2,
            kind: .cameraPole,
            position: .init(x: 10, y: 0),
            health: 100,
            radius: 16,
            sensorSpoof: .init(untilTick: 200, suspicionMultiplier: 0.2)
        ),
        Entity(
            id: 3,
            kind: .securityGuard,
            guardArchetype: .flashlightCadet,
            position: .init(x: 0, y: 10),
            health: 40,
            radius: 16,
            processing: .init(untilTick: 200, slowMultiplier: 0.4, damagePerTick: 3)
        ),
        Entity(
            id: 4,
            kind: .projectile,
            position: .init(x: 10, y: 0),
            velocity: .init(),
            health: 1,
            radius: 5,
            sourceWeapon: .identityTransponder,
            payload: .spoofCameraSensors(durationTicks: 40, suspicionMultiplier: 0.8)
        ),
        Entity(
            id: 5,
            kind: .projectile,
            position: .init(x: 0, y: 10),
            velocity: .init(),
            health: 1,
            radius: 5,
            sourceWeapon: .foiaSwarm,
            payload: .processing(durationTicks: 40, slowMultiplier: 0.9, damagePerTick: 1)
        )
    ]
    state.activeWeapons = []
    var simulation = Simulation(state: state, rngSeed: 922)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    let camera = simulation.state.entities.first { $0.id == 2 }
    let threat = simulation.state.entities.first { $0.id == 3 }
    #expect(camera?.sensorSpoof?.suspicionMultiplier == 0.2)
    #expect((camera?.sensorSpoof?.untilTick ?? 0) >= 200)
    #expect(threat?.processing?.slowMultiplier == 0.4)
    #expect(threat?.processing?.damagePerTick == 3)
    #expect((threat?.processing?.untilTick ?? 0) >= 200)
}

// MARK: - Combat feel and evasion viability

@Test func autoFirePrioritisesAThreatInContactOverADistantCamera() {
    var state = RunState(seed: 300, district: .wichita)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        // Camera is nearer than the guard was under the old rule's flat "nearest
        // camera first", yet the guard is the thing actually killing the player.
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: 200, y: 0), health: 60, radius: 20),
        Entity(id: 3, kind: .securityGuard, guardArchetype: .flashlightCadet,
               position: .init(x: 60, y: 0), health: 20, radius: 14)
    ]
    var simulation = Simulation(state: state, rngSeed: 300)
    for _ in 0..<15 { _ = simulation.step(input: .init()) }

    let projectile = simulation.state.entities.first { $0.kind == .projectile }
    #expect(projectile != nil, "baseline weapon should have fired")
    // Fired toward the guard (+x, nearer) rather than past it at the camera.
    #expect((projectile?.velocity.x ?? 0) > 0)
}

@Test func autoFireHoldsItsTargetInsteadOfReaimingEveryShot() {
    var state = RunState(seed: 301, district: .wichita)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: 150, y: 0), health: 10_000, radius: 20),
        Entity(id: 3, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: 155, y: 0), health: 10_000, radius: 20)
    ]
    var simulation = Simulation(state: state, rngSeed: 301)
    var fired: [String] = []
    for _ in 0..<120 {
        fired += simulation.step(input: .init())
            .filter { $0.kind == .weaponFired }
            .map(\.message)
    }
    // Two near-identical targets must not cause the weapon to alternate.
    #expect(fired.count > 2, "expected repeated fire")
    #expect(Set(fired).count == 1, "weapon re-aimed between shots: \(Set(fired))")
}

@Test func breakingLineOfSightLetsSuspicionRecoverEvenWithManyGuards() {
    var state = RunState(seed: 302, district: .wichita)
    state.activeWeapons = []
    state.suspicion = 60
    // A crowd far away: survival pressure, but nothing can see the player.
    var entities: [Entity] = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18)
    ]
    for index in 0..<20 {
        entities.append(Entity(id: UInt64(100 + index), kind: .securityGuard,
                               guardArchetype: .supervisorOnBreak,
                               position: .init(x: 2_000, y: Double(index) * 10),
                               health: 70, radius: 21))
    }
    state.entities = entities
    var simulation = Simulation(state: state, rngSeed: 302)
    let before = simulation.state.suspicion
    for _ in 0..<120 { _ = simulation.step(input: .init()) }

    // Previously 20 guards produced +2.05/sec regardless of concealment, so this
    // could only ever climb. Unseen means unobserved.
    #expect(simulation.state.suspicion < before,
            "suspicion rose while completely unobserved: \(before) -> \(simulation.state.suspicion)")
}

@Test func guardsAreTheCitysResponseToSuspicionNotASourceOfIt() {
    // Guards used to add suspicion whenever they were near the player. That made the
    // system self-driving: guards raised suspicion, suspicion raised the tier, and the
    // tier spawned more guards, which ran away to total visibility regardless of how
    // the player behaved. It also stopped contract security from being deployable to
    // where the player actually is. Being stood next to is not the same as being seen
    // by the grid — only sensors accuse.
    func suspicion(afterGuardsAt distance: Double) -> Double {
        var state = RunState(seed: 303, district: .wichita)
        state.activeWeapons = []
        state.suspicion = 50
        var entities: [Entity] = [
            Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18)
        ]
        for index in 0..<8 {
            entities.append(Entity(id: UInt64(200 + index), kind: .securityGuard,
                                   guardArchetype: .supervisorOnBreak,
                                   position: .init(x: distance, y: Double(index) * 8),
                                   health: 70, radius: 21))
        }
        state.entities = entities
        var simulation = Simulation(state: state, rngSeed: 303)
        for _ in 0..<120 { _ = simulation.step(input: .init()) }
        return simulation.state.suspicion
    }

    let swarmed = suspicion(afterGuardsAt: 120)
    let alone = suspicion(afterGuardsAt: 2_000)
    #expect(swarmed == alone,
            "a crowd on top of the player must not accuse them: \(swarmed) vs \(alone)")
    // With no sensor watching, both cases must be recovering rather than holding.
    #expect(swarmed < 50, "out of every scan cone, suspicion must decay: \(swarmed)")
}

@Test func guardPopulationFollowsSuspicionRatherThanTheClock() {
    func guardsAfterTwoMinutes(tier: SuspicionTier, suspicion: Double) -> Int {
        var state = RunState(seed: 310, district: .wichita)
        state.activeWeapons = []
        state.suspicion = suspicion
        state.suspicionTier = tier
        if let player = state.entities.firstIndex(where: { $0.kind == .player }) {
            state.entities[player].health = 1_000_000
        }
        // Suspicion must be governed by the seeded tier, not by contact. Removing the
        // authored poles once is not enough — escalation sensors keep deploying during
        // the run, and an unarmed idle player cannot shoot them, so one eventually
        // points at the player and drives suspicion through contact instead. Keep the
        // district free of sensors for the whole window.
        state.entities.removeAll { $0.kind == .cameraPole }
        var simulation = Simulation(state: state, rngSeed: 310)
        for _ in 0..<7_200 {
            _ = simulation.step(input: .init())
            if simulation.state.entities.contains(where: { $0.kind == .cameraPole }) {
                var working = simulation.state
                working.entities.removeAll { $0.kind == .cameraPole }
                simulation = Simulation(state: working, rngSeed: 310)
            }
        }
        return simulation.state.entities.filter { $0.kind == .securityGuard && $0.health > 0 }.count
    }

    // Two full minutes at background noise must not conjure a crowd: under the old
    // wall-clock growth this reached roughly 26 guards regardless of play.
    let quiet = guardsAfterTwoMinutes(tier: .backgroundNoise, suspicion: 0)
    let alarmed = guardsAfterTwoMinutes(tier: .totalVisibility, suspicion: 100)
    // Explicit director / coordination levers may still add a little on top of the
    // tier base, so assert the shape rather than an exact floor.
    #expect(quiet <= 6, "staying unseen should keep the district thin, got \(quiet)")
    #expect(alarmed >= quiet * 3,
            "an alarmed district should be far denser: \(alarmed) vs \(quiet)")
}

@Test func committedTargetsAreExposedForPresentation() {
    var state = RunState(seed: 320, district: .wichita)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: 150, y: 0), health: 10_000, radius: 20)
    ]
    var simulation = Simulation(state: state, rngSeed: 320)
    #expect(simulation.committedTargetIDs.isEmpty, "nothing acquired before firing")

    for _ in 0..<20 { _ = simulation.step(input: .init()) }
    // Presentation draws a reticle from this, so an acquired target must be visible
    // to the app layer — otherwise automatic attacks have no on-screen explanation.
    #expect(simulation.committedTargetIDs.contains(2))
}

@Test func committedTargetClearsWhenNothingIsInRange() {
    var state = RunState(seed: 321, district: .wichita)
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 1_000_000, radius: 18),
        Entity(id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole,
               position: .init(x: 150, y: 0), health: 10_000, radius: 20)
    ]
    var simulation = Simulation(state: state, rngSeed: 321)
    for _ in 0..<20 { _ = simulation.step(input: .init()) }
    #expect(!simulation.committedTargetIDs.isEmpty)

    // Move the camera far outside every weapon's range.
    var cleared = simulation.state
    if let index = cleared.entities.firstIndex(where: { $0.id == 2 }) {
        cleared.entities[index].position = .init(x: 5_000, y: 0)
    }
    var after = Simulation(state: cleared, rngSeed: 321)
    for _ in 0..<20 { _ = after.step(input: .init()) }
    #expect(after.committedTargetIDs.isEmpty, "stale reticle would point at nothing")
}

@Test func aCrowdCannotDeleteThePlayerInASingleInstant() {
    func healthAfterOneSecond(guards: Int) -> Double {
        var state = RunState(seed: 330, district: .wichita)
        state.activeWeapons = []
        var entities: [Entity] = [
            Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18)
        ]
        // Every guard overlapping the player at once.
        for index in 0..<guards {
            entities.append(Entity(id: UInt64(400 + index), kind: .securityGuard,
                                   guardArchetype: .clipboardEnforcer,
                                   position: .init(x: 5, y: 0), health: 30, radius: 14))
        }
        state.entities = entities
        var simulation = Simulation(state: state, rngSeed: 330)
        for _ in 0..<60 { _ = simulation.step(input: .init()) }
        return simulation.state.entities.first { $0.kind == .player }?.health ?? 0
    }

    // The grace window means damage is gated by time, not by crowd size, so a
    // swarm can no longer stack simultaneous contact into an instant kill.
    let few = healthAfterOneSecond(guards: 2)
    let many = healthAfterOneSecond(guards: 12)
    #expect(many > 0, "a 12-guard pile should not delete a full-health player in one second")
    #expect(abs(few - many) < 40,
            "crowd size should not scale damage linearly: \(few) vs \(many)")
}

@Test func graceWindowStillLetsSustainedContactKill() {
    var state = RunState(seed: 331, district: .wichita)
    state.activeWeapons = []
    state.entities = [
        Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
        Entity(id: 2, kind: .securityGuard, guardArchetype: .clipboardEnforcer,
               position: .init(x: 5, y: 0), health: 100_000, radius: 14)
    ]
    var simulation = Simulation(state: state, rngSeed: 331)
    for _ in 0..<3_600 {
        _ = simulation.step(input: .init())
        if simulation.state.playerDefeated { break }
    }
    // Grace must soften burst, not grant immortality.
    #expect(simulation.state.playerDefeated, "standing in contact indefinitely must still kill")
}

@Test func destroyingEveryCameraMustNotMakeTheRunUnwinnable() {
    var state = RunState(seed: 340, district: .wichita)
    state.activeWeapons = []
    if let player = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[player].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 340)

    var bossEverActivated = false
    var destroyed = 0
    for _ in 0..<18_000 {  // five minutes
        // Destroy cameras the way the game does — zero their health and let
        // resolveDeaths award shards and apply the escalation spike. Deleting the
        // entities outright would bypass the very code path under test.
        var working = simulation.state
        var killedThisPass = false
        for index in working.entities.indices
        where working.entities[index].kind == .cameraPole && working.entities[index].health > 0 {
            working.entities[index].health = 0
            killedThisPass = true
            destroyed += 1
        }
        if killedThisPass { simulation = Simulation(state: working, rngSeed: 340) }

        let events = simulation.step(input: .init())
        if events.contains(where: { $0.kind == .bossActivated }) { bossEverActivated = true; break }
        if simulation.state.runCompleted { break }
    }

    #expect(destroyed > 0, "the test must actually destroy cameras")
    #expect(bossEverActivated,
            "clearing the grid must still summon the authority, or the objective starves its own win condition: tier=\(simulation.state.suspicionTier) suspicion=\(simulation.state.suspicion) destroyed=\(destroyed)")
}
