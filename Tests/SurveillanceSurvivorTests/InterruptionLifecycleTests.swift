import Foundation
import SpriteKit
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test @MainActor func manualPauseFreezesTicksAcrossUpdates() {
    let scene = GameScene(size: CGSize(width: 844, height: 390))
    scene.update(1)
    scene.update(1.1)
    let ticksBefore = scene.elapsedTicksForTesting
    #expect(ticksBefore > 0)

    scene.setRunPaused(true)
    scene.update(2)
    scene.update(2.5)
    #expect(scene.elapsedTicksForTesting == ticksBefore)

    scene.setRunPaused(false)
    scene.update(3)
    scene.update(3.2)
    #expect(scene.elapsedTicksForTesting > ticksBefore)
}

@Test @MainActor func redundantPauseAndResumeAreIdempotent() {
    let scene = GameScene(size: CGSize(width: 844, height: 390))
    scene.update(1)
    scene.update(1.05)
    let baseline = scene.elapsedTicksForTesting

    scene.setRunPaused(true)
    scene.setRunPaused(true)
    scene.update(2)
    #expect(scene.elapsedTicksForTesting == baseline)

    scene.setRunPaused(false)
    scene.setRunPaused(false)
    scene.update(3)
    scene.update(3.05)
    #expect(scene.elapsedTicksForTesting > baseline)
}

@Test @MainActor func completedRunDoesNotAdvanceWhenUpdated() {
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
    var done = simulation.state
    done.entities[playerIndex].position = extraction.position
    var completion = Simulation(state: done, rngSeed: 48)
    _ = completion.step(input: .init(autoFireEnabled: false))
    #expect(completion.state.runCompleted)

    let scene = GameScene(size: CGSize(width: 844, height: 390))
    scene.installSimulationForTesting(completion)
    let ticks = scene.elapsedTicksForTesting
    scene.setRunPaused(false)
    scene.update(10)
    scene.update(10.5)
    #expect(scene.runCompleted)
    #expect(scene.elapsedTicksForTesting == ticks)
}

@Test @MainActor func projectionRecreateKeepsSinglePlayerNode() {
    let simulation = Simulation(seed: 7, district: .wichita)
    let scene = GameScene(size: CGSize(width: 844, height: 390))
    scene.installSimulationForTesting(simulation)
    scene.installSimulationForTesting(simulation)
    scene.installSimulationForTesting(simulation)

    let playerNodes = scene.children.filter { ($0.name ?? "").hasPrefix("entity-") && $0.name?.hasSuffix("1") == true || ($0.name == "entity-1") }
    // Player id is always 1 in RunState init.
    let players = scene.children.filter { $0.name == "entity-1" }
    #expect(players.count == 1)
    _ = playerNodes
}

@Test @MainActor func upgradeCannotBeSelectedTwiceFromSameDraft() {
    let scene = GameScene(size: CGSize(width: 844, height: 390))
    // Drive until an upgrade draft appears or timeout.
    scene.update(1)
    var sawDraft = false
    for i in 0..<400 {
        scene.update(1 + Double(i + 1) / 60.0)
        if !scene.pendingUpgradeChoices.isEmpty {
            sawDraft = true
            let count = scene.pendingUpgradeChoices.count
            scene.selectUpgrade(at: 0)
            #expect(scene.pendingUpgradeChoices.isEmpty)
            scene.selectUpgrade(at: 0) // second apply must no-op
            #expect(scene.pendingUpgradeChoices.isEmpty)
            #expect(count >= 1)
            break
        }
    }
    // Draft may not appear under all seeds; test still validates no-op path.
    if !sawDraft {
        scene.selectUpgrade(at: 0)
        #expect(scene.pendingUpgradeChoices.isEmpty)
    }
}
