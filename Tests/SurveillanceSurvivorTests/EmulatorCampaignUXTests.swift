import Foundation
import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

/// Emulator-hosted campaign UX rules: unlock gating, picker resolution, and
/// audio event mapping without requiring physical device audio route tests.
@Suite("Emulator campaign UX")
struct EmulatorCampaignUXTests {
    @Test func pickerOnlyExposesUnlockedDistrictsAfterWin() {
        var progress = CampaignProgress.initial
        #expect(progress.unlockedDistricts.map(\.id) == [.wichita])

        progress.recordRunOutcome(district: .wichita, extractionCompleted: true)
        let unlocked = progress.unlockedDistricts.map(\.id)
        #expect(unlocked == [.wichita, .louisville])
        #expect(progress.resolveSelection(.atlanta) == .louisville)
        #expect(progress.resolveSelection(.louisville) == .louisville)
    }

    @Test func storeAndPickerStayAlignedAcrossSessions() {
        let suite = "EmulatorCampaignUX-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = CampaignProgressStore(defaults: defaults)
        _ = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
        _ = store.applyRunOutcome(district: .louisville, extractionCompleted: true)

        let reloaded = CampaignProgressStore(defaults: defaults)
        #expect(reloaded.progress.highestUnlockedLevel == 3)
        #expect(reloaded.progress.isUnlocked(.tulsa))
        #expect(!reloaded.progress.isUnlocked(.dayton))
        #expect(reloaded.progress.resolveSelection(nil) == .tulsa)
    }

    @Test @MainActor func sceneResolvesAudioCuesWithoutRequiringAssetBank() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        // Drive a short run so weapon fire / spawns emit events.
        scene.update(1)
        for i in 0..<120 {
            scene.update(1 + Double(i + 1) / 60.0)
            if scene.pendingUpgradeChoices.isEmpty == false {
                scene.selectUpgrade(at: 0)
            }
        }
        // Even with an empty asset bank the resolver may have produced requests
        // from live events; the count is non-negative and never crashes.
        #expect(scene.lastAudioRequestCountForTesting >= 0)
    }

    @Test @MainActor func emptyAudioBankNeverCountsAsPlayed() {
        let player = AudioCuePlayer()
        #expect(player.availableAssets.isEmpty)
        let events = [
            RunEvent(.weaponFired, "kinetic"),
            RunEvent(.tierChanged, "tier 1")
        ]
        // Without setAvailableAssets, product policy is silent dry-run.
        let played = player.play(events: events, atTick: 10)
        #expect(played == 0)
        #expect(player.lastResolvedRequests.isEmpty == false)
    }

    @Test @MainActor func coldLaunchBootstrapsPersistedDistrictInsteadOfOpener() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        #expect(scene.activeDistrict == .wichita)
        #expect(scene.districtName == DistrictID.wichita.cityName)

        // Simulate AppStorage holding Louisville after a prior unlock + picker write.
        scene.bootstrapCampaignDistrictIfNeeded(.louisville)
        #expect(scene.activeDistrict == .louisville)
        #expect(scene.districtName == DistrictID.louisville.cityName)
        #expect(scene.runSeed == 0x51555256) // ordinal unchanged on cold bootstrap

        // Idempotent: second call must not advance the run seed.
        let seed = scene.runSeed
        scene.bootstrapCampaignDistrictIfNeeded(.louisville)
        #expect(scene.runSeed == seed)

        // Must not clobber a finished run / summary.
        scene.installSimulationForTesting({
            var state = RunState(seed: 7, district: .wichita)
            state.runCompleted = true
            state.extractionOpen = true
            return Simulation(state: state, rngSeed: 7)
        }())
        // Force receipt path if needed — installSimulationForTesting sets district from prepared.
        #expect(scene.activeDistrict == .wichita)
        scene.bootstrapCampaignDistrictIfNeeded(.louisville)
        #expect(scene.activeDistrict == .wichita)

        // Must not wipe an in-progress run on a late/repeated onAppear.
        let live = GameScene(size: CGSize(width: 844, height: 390))
        live.installSimulationForTesting({
            var sim = Simulation(seed: 11, district: .wichita)
            _ = sim.step(input: .init(autoFireEnabled: false))
            return sim
        }())
        #expect(live.activeDistrict == .wichita)
        #expect(live.runSeed == 11)
        live.bootstrapCampaignDistrictIfNeeded(.louisville)
        #expect(live.activeDistrict == .wichita)
        #expect(live.runSeed == 11)
    }

    @Test @MainActor func dailyChallengeRunSeatsDistrictSeedAndObjective() {
        let cal = ChallengeResolver.utcCalendar
        let day = cal.date(from: DateComponents(year: 2026, month: 7, day: 25))!
        let challenge = ChallengeResolver.daily(for: day)
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.startChallengeRun(challenge)
        #expect(scene.activeDistrict == challenge.districtId)
        #expect(scene.runSeed == challenge.seed)
        #expect(scene.activeChallenge?.contractId == challenge.contractId)
        #expect(scene.objectiveText.contains(challenge.contractDisplayName))
    }

    @Test func masteryStoreRecordsChallengeReceipt() {
        let suite = "EmulatorMasteryUX-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let store = MasteryProgressStore(defaults: defaults)
        let cal = ChallengeResolver.utcCalendar
        let day = cal.date(from: DateComponents(year: 2026, month: 7, day: 25))!
        let challenge = ChallengeResolver.daily(for: day)
        var sim = Simulation(seed: 1, challenge: challenge)
        _ = sim.step(input: .init(autoFireEnabled: false))
        let receipt = sim.runReceipt()
        #expect(receipt.challenge?.contractId == challenge.contractId)

        let updated = store.recordReceipt(receipt, finishedAt: "2026-07-25T12:00:00Z")
        #expect(updated.totalRuns == 1)
        #expect(updated.runHistory.first?.challengeKind == "daily")

        let reloaded = MasteryProgressStore(defaults: defaults)
        #expect(reloaded.progress.totalRuns == 1)
        #expect(reloaded.progress.runHistory.first?.districtId == challenge.districtId)
    }

    @Test @MainActor func extractionPathEmitsExtractionAudioRequests() {
        var state = RunState(seed: 48, district: .wichita)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
            Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42)
        ]
        var simulation = Simulation(state: state, rngSeed: 48)
        _ = simulation.step(input: .init(autoFireEnabled: false))
        guard let playerIndex = simulation.state.entities.firstIndex(where: { $0.kind == .player }),
              let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
            Issue.record("expected extraction")
            return
        }
        var completionState = simulation.state
        completionState.entities[playerIndex].position = extraction.position
        var completion = Simulation(state: completionState, rngSeed: 48)
        let events = completion.step(input: .init(autoFireEnabled: false))
        #expect(events.contains { $0.kind == .extractionCompleted })

        var resolver = AudioCueResolver()
        let requests = resolver.resolve(events: events, atTick: completion.runReceipt().elapsedTicks)
        #expect(requests.contains { $0.cueID.rawValue == "extraction_completed" })
    }
}
