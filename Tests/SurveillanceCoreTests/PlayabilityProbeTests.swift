import Foundation
import Testing
@testable import SurveillanceCore

/// Balance probe. Plays every district with a deliberately simple but *competent*
/// bot — walk to the nearest live camera, back off when a threat is on top of you,
/// always take an upgrade — and asserts the run is actually playable.
///
/// This exists because "it plays like shit" is not something unit tests catch.
/// Individual mechanics can each be correct while the composed run is a death
/// march or a walkover. These probes measure the composed result.
struct PlayabilityProbeTests {
    struct Outcome {
        var district: DistrictID
        var seed: UInt64
        var survivedSeconds: Double
        var camerasDestroyed: Int
        var finalHealth: Double
        var reachedBoss: Bool
        var extractionOpened: Bool
        var defeated: Bool
        var completed: Bool
        var lowestHealth: Double
    }

    /// Walk toward the objective; retreat from anything close enough to be hitting you.
    static func botInput(for state: RunState) -> PlayerInput {
        guard let player = state.entities.first(where: { $0.kind == EntityKind.player }) else {
            return .init()
        }
        var input = PlayerInput()
        // Always take the first option; harmless when no draft is open.
        input.upgradeChoiceIndex = 0

        // Leaving beats kiting. A human eats a hit to reach the exit rather than
        // circling a crowded district forever, so the bot must too.
        if state.extractionOpen,
           let exit = state.entities.first(where: { $0.kind == EntityKind.extraction }) {
            input.movement = (exit.position - player.position).normalized()
            return input
        }
        // The authority has to be fought, not fled. Running from it forever outpaces
        // it (155 against 120) and drifts past weapon range, so neither side ever lands
        // a hit and the run cannot end — that is the bot being a coward, not the game
        // being unwinnable. Hold near the edge of the primary weapon's reach.
        if let authority = state.entities.first(where: { $0.kind == EntityKind.boss && $0.health > 0 }) {
            let offset = authority.position - player.position
            let distance = offset.magnitude
            if distance > 300 {
                input.movement = offset.normalized()
            } else if distance < 140 {
                input.movement = (player.position - authority.position).normalized()
            } else {
                // In range and not in contact: strafe rather than close.
                input.movement = Vector2(x: -offset.normalized().y, y: offset.normalized().x)
            }
            return input
        }
        let threats = state.entities.filter {
            ($0.kind == EntityKind.securityGuard || $0.kind == EntityKind.boss) && $0.health > 0
                && ($0.position - player.position).magnitude < 90
        }
        if let closest = threats.min(by: {
            ($0.position - player.position).magnitude < ($1.position - player.position).magnitude
        }) {
            // Kite: move directly away from whatever is on top of us.
            input.movement = (player.position - closest.position).normalized()
            return input
        }
        let cameras = state.entities.filter { $0.kind == EntityKind.cameraPole && $0.health > 0 }
        if let target = cameras.min(by: {
            ($0.position - player.position).magnitude < ($1.position - player.position).magnitude
        }) {
            input.movement = (target.position - player.position).normalized()
        }
        return input
    }

    /// Steer a desired heading around solid geometry.
    ///
    /// The bot walks straight lines, so a box between it and its target pins it
    /// against a wall. That reads as "the run never resolved" when the real cause is
    /// that the probe cannot path. Rotating the heading until a short look-ahead is
    /// clear is enough to round the district's rectangular obstacles.
    static func steerAround(_ desired: Vector2, from position: Vector2, world: WorldLayout) -> Vector2 {
        guard desired.magnitude > 0 else { return desired }
        let lookAhead = 70.0
        func blocked(_ heading: Vector2) -> Bool {
            let probe = position + heading.normalized() * lookAhead
            return world.obstacles.contains { obstacle in
                abs(probe.x - obstacle.center.x) <= obstacle.halfSize.x + 20
                    && abs(probe.y - obstacle.center.y) <= obstacle.halfSize.y + 20
            }
        }
        guard blocked(desired) else { return desired }
        let base = atan2(desired.y, desired.x)
        for step in 1...18 {
            // Sweep both ways so the nearest clear heading wins.
            for sign in [1.0, -1.0] {
                let angle = base + sign * Double(step) * (.pi / 18)
                let candidate = Vector2(x: cos(angle), y: sin(angle))
                if !blocked(candidate) { return candidate }
            }
        }
        return desired
    }

    /// The bot walks straight lines and districts have solid obstacles. Without this
    /// it can wedge against a wall and read as "the win path is broken" when the real
    /// cause is that the probe cannot path around a box.
    ///
    /// The detour has to be committed to for a stretch. Recomputing a perpendicular
    /// every tick just oscillates against the same corner, which left runs pinned for
    /// ten minutes at full health with the exit already open.
    /// - Parameter sign: alternates between successive detours. Always turning the
    ///   same way can orbit the same corner forever, which left a run circling with
    ///   the boss already dead and the exit open.
    static func unstick(_ input: PlayerInput, detourTicksRemaining: Int, sign: Double = 1) -> PlayerInput {
        guard detourTicksRemaining > 0 else { return input }
        var nudged = input
        nudged.movement = Vector2(x: -input.movement.y * sign, y: input.movement.x * sign)
        return nudged
    }

    static func play(district: DistrictID, seed: UInt64, maxTicks: Int = 36_000) -> Outcome {
        var simulation = Simulation(state: RunState(seed: seed, district: district), rngSeed: seed)
        var reachedBoss = false
        var extractionOpened = false
        var ticks = 0
        var lowestHealth = BossCatalog.bundled.playerHealth
        var stalled = 0
        var detour = 0
        var detourSign = 1.0
        for tick in 0..<maxTicks {
            ticks = tick
            let before = simulation.state.entities.first { $0.kind == EntityKind.player }?.position ?? .init()
            var chosen = Self.unstick(
                botInput(for: simulation.state), detourTicksRemaining: detour, sign: detourSign)
            if let position = simulation.state.entities.first(where: { $0.kind == EntityKind.player })?.position {
                chosen.movement = Self.steerAround(chosen.movement, from: position, world: simulation.state.world)
            }
            let events = simulation.step(input: chosen)
            let after = simulation.state.entities.first { $0.kind == EntityKind.player }?.position ?? .init()
            stalled = (after - before).magnitude < 0.5 ? stalled + 1 : 0
            if detour > 0 {
                detour -= 1
            } else if stalled > 20 {
                detour = 90
                detourSign = -detourSign
                stalled = 0
            }
            if events.contains(where: { $0.kind == RunEvent.Kind.bossActivated }) { reachedBoss = true }
            if simulation.state.extractionOpen { extractionOpened = true }
            if let hp = simulation.state.entities.first(where: { $0.kind == EntityKind.player })?.health {
                lowestHealth = min(lowestHealth, hp)
            }
            if simulation.state.playerDefeated || simulation.state.runCompleted { break }
        }
        let player = simulation.state.entities.first { $0.kind == EntityKind.player }
        return Outcome(
            district: district,
            seed: seed,
            survivedSeconds: Double(ticks) / 60.0,
            camerasDestroyed: simulation.state.dataShards,
            finalHealth: player?.health ?? 0,
            reachedBoss: reachedBoss,
            extractionOpened: extractionOpened,
            defeated: simulation.state.playerDefeated,
            completed: simulation.state.runCompleted,
            lowestHealth: lowestHealth
        )
    }

    @Test func aCompetentPlayerCanSurviveLongEnoughToAccomplishSomething() {
        var report: [String] = []
        var starved: [String] = []
        for (index, district) in DistrictID.allCases.enumerated() {
            let outcome = Self.play(district: district, seed: UInt64(9_000 + index * 17))
            report.append("""
                \(district) seed=\(outcome.seed) \
                survived=\(String(format: "%.1f", outcome.survivedSeconds))s \
                shards=\(outcome.camerasDestroyed) \
                hp=\(String(format: "%.0f", outcome.finalHealth)) \
                boss=\(outcome.reachedBoss) extract=\(outcome.extractionOpened) \
                lowHp=\(String(format: "%.0f", outcome.lowestHealth)) \
                dead=\(outcome.defeated) done=\(outcome.completed)
                """)
            // A bot that walks the objective and kites should not be wiped out before
            // it can destroy anything. If it is, no human is having a good time either.
            if outcome.defeated && outcome.camerasDestroyed < 3 {
                starved.append("\(district): died at \(String(format: "%.1f", outcome.survivedSeconds))s with only \(outcome.camerasDestroyed) shards")
            }
        }
        print("PLAYABILITY PROBE\n" + report.joined(separator: "\n"))
        #expect(starved.isEmpty, "districts kill a competent player before the loop engages: \(starved.joined(separator: " | "))")
    }

    @Test func everyDistrictSummonsItsAuthorityAndOpensTheBlindSpot() {
        // The failure this guards against is a district with no ending: clearing every
        // camera once left suspicion with no source, so the authority never activated
        // and the Blind Spot never opened — playing the objective well made the run
        // impossible to finish.
        //
        // Deliberately does not assert the bot physically reaches the exit. The probe
        // walks straight lines with local obstacle avoidance and no pathfinder, so it
        // can pin itself against a large block; that measures the probe, not the game.
        // Whether the exit is walkable needs a pathfinder to establish honestly.
        var broken: [String] = []
        for (index, district) in DistrictID.allCases.enumerated() {
            let outcome = Self.play(district: district, seed: UInt64(9_000 + index * 17))
            if !outcome.reachedBoss {
                broken.append("\(district): no authority after \(String(format: "%.0f", outcome.survivedSeconds))s")
            } else if !outcome.extractionOpened && !outcome.defeated {
                broken.append("\(district): authority appeared but the Blind Spot never opened")
            }
        }
        #expect(broken.isEmpty, "districts with no reachable ending: \(broken.joined(separator: " | "))")
    }

    @Test func combatIsNotAWalkoverAcrossTheCampaign() {
        // The player used to move 210 while the fastest enemy moved 130 and every enemy
        // was melee-only, so nothing in the game could ever touch you: ten minutes of
        // active play ended at full health in all ten districts. Auto-fire read as
        // random drifting because there was never anything at stake. Threats must be
        // able to land hits on someone who is actively avoiding them.
        var touched = 0
        for (index, district) in DistrictID.allCases.enumerated() {
            let outcome = Self.play(district: district, seed: UInt64(4_100 + index * 29))
            if outcome.lowestHealth < BossCatalog.bundled.playerHealth { touched += 1 }
        }
        #expect(touched >= 3,
                "only \(touched)/10 districts landed a single hit on a kiting player; enemies cannot pressure the player at all")
    }
}

extension PlayabilityProbeTests {
    @Test func noDistrictAuthorityCanOutrunThePlayer() {
        // Player speed dropped from 210 to 155 to make combat threatening, which put
        // the last two districts' authorities (158 and 168 after their multipliers)
        // above the player. With no healing in the game and contact damage up to 2x,
        // an authority that cannot be outrun is unanswerable rather than hard.
        let boss = BossCatalog.bundled
        var offenders: [String] = []
        for district in DistrictID.allCases {
            let authored = boss.shiftManagerSpeed * district.profile.bossSpeedMultiplier
            let effective = min(authored, boss.playerSpeed * boss.bossSpeedCeilingFractionOfPlayer)
            if effective >= boss.playerSpeed {
                offenders.append("\(district): \(effective) vs player \(boss.playerSpeed)")
            }
        }
        #expect(offenders.isEmpty, "authorities the player cannot disengage from: \(offenders.joined(separator: " | "))")
    }
}
