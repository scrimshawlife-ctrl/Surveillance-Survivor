import Foundation
import SpriteKit
import Testing
@testable import SurveillanceCore
@testable import SurveillanceSurvivor

/// Emulator-hosted vertical-slice smoke: force boss defeat → enter Blind Spot →
/// campaign unlocks Louisville. No physical device required.
@Suite("Emulator extraction smoke")
struct EmulatorExtractionSmokeTests {
    @Test @MainActor func forcedExtractionCompletesReceiptAndUnlocksNextCity() {
        var state = RunState(seed: 48, district: .wichita)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
            Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42)
        ]
        var simulation = Simulation(state: state, rngSeed: 48)
        _ = simulation.step(input: .init(autoFireEnabled: false))

        #expect(simulation.state.extractionOpen)
        guard let playerIndex = simulation.state.entities.firstIndex(where: { $0.kind == .player }),
              let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
            Issue.record("Blind Spot did not open after boss defeat")
            return
        }

        var completionState = simulation.state
        completionState.entities[playerIndex].position = extraction.position
        var completion = Simulation(state: completionState, rngSeed: 48)
        _ = completion.step(input: .init(autoFireEnabled: false))
        #expect(completion.state.runCompleted)
        #expect(completion.runReceipt().extractionCompleted)

        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(completion)
        #expect(scene.runCompleted)
        #expect(scene.playerDefeated == false)
        #expect(scene.completedRunReceipt?.core.extractionCompleted == true)
        #expect(scene.completedRunReceipt?.core.district == .wichita)

        let suite = "EmulatorExtractionSmoke-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CampaignProgressStore(defaults: defaults)
        let updated = store.applyRunOutcome(
            district: scene.completedRunReceipt!.core.district,
            extractionCompleted: true
        )
        #expect(updated.isUnlocked(.louisville))
        #expect(updated.nextDistrict(after: .wichita) == .louisville)
        #expect(updated.completedDistricts == [.wichita])
    }

    @Test @MainActor func defeatReceiptDoesNotUnlockNextCity() {
        var state = RunState(seed: 47, district: .wichita)
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
        for _ in 0..<180 {
            _ = simulation.step(input: .init(autoFireEnabled: false))
            if simulation.state.runCompleted { break }
        }
        #expect(simulation.state.playerDefeated)
        #expect(simulation.runReceipt().extractionCompleted == false)

        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(simulation)
        #expect(scene.runCompleted)
        #expect(scene.playerDefeated)

        let suite = "EmulatorDefeatSmoke-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CampaignProgressStore(defaults: defaults)
        let updated = store.applyRunOutcome(
            district: .wichita,
            extractionCompleted: scene.completedRunReceipt?.core.extractionCompleted ?? false
        )
        #expect(!updated.isUnlocked(.louisville))
        #expect(updated.highestUnlockedLevel == 1)
    }

    @Test @MainActor func districtSelectionSurvivesNextRunOnEmulatorHost() {
        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.selectDistrict(.louisville)
        scene.startNextRun()
        #expect(scene.districtName == DistrictID.louisville.cityName)
        #expect(scene.districtTitle == DistrictID.louisville.definition.title)
        scene.update(1)
        scene.update(1.1)
        #expect(scene.elapsedTicksForTesting > 0)
        #expect(scene.runCompleted == false)
    }

    /// Second-city extract path: Louisville Blind Spot completion unlocks Tulsa.
    @Test @MainActor func louisvilleExtractionUnlocksTulsaOnEmulatorHost() {
        var state = RunState(seed: 48, district: .louisville)
        state.entities = [
            Entity(id: 1, kind: .player, position: .init(x: 0, y: 0), health: 100, radius: 18),
            Entity(id: 99, kind: .boss, position: .init(x: 100, y: 0), health: 0, radius: 42)
        ]
        var simulation = Simulation(state: state, rngSeed: 48)
        _ = simulation.step(input: .init(autoFireEnabled: false))
        #expect(simulation.state.extractionOpen)
        #expect(simulation.state.district == .louisville)

        guard let playerIndex = simulation.state.entities.firstIndex(where: { $0.kind == .player }),
              let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
            Issue.record("Blind Spot did not open for Louisville after boss defeat")
            return
        }

        var completionState = simulation.state
        completionState.entities[playerIndex].position = extraction.position
        var completion = Simulation(state: completionState, rngSeed: 48)
        _ = completion.step(input: .init(autoFireEnabled: false))
        #expect(completion.state.runCompleted)
        #expect(completion.runReceipt().district == .louisville)
        #expect(completion.runReceipt().extractionCompleted)

        let scene = GameScene(size: CGSize(width: 844, height: 390))
        scene.installSimulationForTesting(completion)
        #expect(scene.districtName == DistrictID.louisville.cityName)
        #expect(scene.completedRunReceipt?.core.district == .louisville)

        let suite = "EmulatorLouisvilleExtract-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CampaignProgressStore(defaults: defaults)
        // Pretend Wichita already cleared so Louisville is the active win.
        _ = store.applyRunOutcome(district: .wichita, extractionCompleted: true)
        let updated = store.applyRunOutcome(
            district: .louisville,
            extractionCompleted: true
        )
        #expect(updated.isUnlocked(.tulsa))
        #expect(updated.nextDistrict(after: .louisville) == .tulsa)
        #expect(updated.completedDistricts.contains(.louisville))
    }
}
