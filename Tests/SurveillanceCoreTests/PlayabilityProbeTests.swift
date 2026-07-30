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

    /// The bot walks straight lines and districts have solid obstacles. Without this
    /// it can wedge against a wall and read as "the win path is broken" when the real
    /// cause is that the probe cannot path around a box.
    ///
    /// The detour has to be committed to for a stretch. Recomputing a perpendicular
    /// every tick just oscillates against the same corner, which left runs pinned for
    /// ten minutes at full health with the exit already open.
    static func unstick(_ input: PlayerInput, detourTicksRemaining: Int) -> PlayerInput {
        guard detourTicksRemaining > 0 else { return input }
        var nudged = input
        nudged.movement = Vector2(x: -input.movement.y, y: input.movement.x)
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
        for tick in 0..<maxTicks {
            ticks = tick
            let before = simulation.state.entities.first { $0.kind == EntityKind.player }?.position ?? .init()
            let events = simulation.step(input: Self.unstick(botInput(for: simulation.state), detourTicksRemaining: detour))
            let after = simulation.state.entities.first { $0.kind == EntityKind.player }?.position ?? .init()
            stalled = (after - before).magnitude < 0.5 ? stalled + 1 : 0
            if detour > 0 {
                detour -= 1
            } else if stalled > 20 {
                detour = 90
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

    @Test func everyDistrictIsWinnableAndReachesItsAuthority() {
        var stalled: [String] = []
        for (index, district) in DistrictID.allCases.enumerated() {
            let outcome = Self.play(district: district, seed: UInt64(9_000 + index * 17))
            // A district that never summons its authority can never open the Blind Spot,
            // so the run has no ending at all — the player just walks an empty map until
            // they quit. That is the single worst thing a district can do.
            if !outcome.reachedBoss {
                stalled.append("\(district): no authority after \(String(format: "%.0f", outcome.survivedSeconds))s")
            } else if !outcome.completed && !outcome.defeated {
                stalled.append("\(district): authority appeared but the run never resolved")
            }
        }
        #expect(stalled.isEmpty, "districts with no reachable ending: \(stalled.joined(separator: " | "))")
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
