import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledDirectorRulesLoadAndForbidHiddenScaling() throws {
    let catalog = try SuspicionDirectorCatalog.loadBundled()
    #expect(catalog.schemaVersion == SuspicionDirectorCatalog.currentSchemaVersion)
    #expect(catalog.schemaId == SuspicionDirectorCatalog.expectedSchemaId)
    #expect(catalog.forbidHiddenStatScaling)
    #expect(catalog.tiers.count == 6)
    #expect(Set(catalog.tiers.map(\.tier)) == Set(0...5))
    #expect(!catalog.actions.isEmpty)
    #expect(catalog.forbiddenLeverKeys.contains("playerDamageScale"))
    #expect(catalog.forbiddenLeverKeys.contains("enemyHealthScale"))
}

@Test func directorEvaluationIsSeedDeterministic() {
    let catalog = SuspicionDirectorCatalog.bundled
    var rngA = DeterministicRNG(seed: 0xD1_5EC_701)
    var rngB = DeterministicRNG(seed: 0xD1_5EC_701)
    var stateA = SuspicionDirectorState.neutral
    var stateB = SuspicionDirectorState.neutral
    var decisionsA: [String] = []
    var decisionsB: [String] = []

    for step in 0..<12 {
        let elapsed = Double(step) * 5
        let tick = UInt64(step + 1) * catalog.evaluationIntervalTicks
        let resultA = SuspicionDirector.evaluate(
            catalog: catalog,
            state: stateA,
            tier: .patternDetected,
            elapsed: elapsed,
            tick: tick,
            rng: &rngA
        )
        let resultB = SuspicionDirector.evaluate(
            catalog: catalog,
            state: stateB,
            tier: .patternDetected,
            elapsed: elapsed,
            tick: tick,
            rng: &rngB
        )
        stateA = resultA.state
        stateB = resultB.state
        if let d = resultA.decision { decisionsA.append(d.actionId) }
        if let d = resultB.decision { decisionsB.append(d.actionId) }
        #expect(resultA.state == resultB.state)
        #expect(resultA.decision == resultB.decision)
    }
    #expect(!decisionsA.isEmpty)
    #expect(decisionsA == decisionsB)
}

@Test func directorNeverAppliesForbiddenStatLevers() throws {
    let catalog = try SuspicionDirectorCatalog.loadBundled()
    for action in catalog.actions {
        #expect(action.levers.spawnIntervalMultiplier > 0)
        #expect(action.levers.sensorCadenceMultiplier > 0)
        // Contract: only explicit encounter cadence/population levers exist.
        let encoded = try JSONEncoder().encode(action.levers)
        let object = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
        let keys = Set(object?.keys.map { $0 } ?? [])
        #expect(keys.isSubset(of: [
            "guardTargetDelta",
            "spawnIntervalMultiplier",
            "sensorCadenceMultiplier"
        ]))
        for forbidden in catalog.forbiddenLeverKeys {
            #expect(!keys.contains(forbidden))
        }
    }
}

@Test func simulationRecordsDirectorDecisionsOnReceipt() {
    var simulation = Simulation(seed: 4242)
    for _ in 0..<(60 * 8) {
        _ = simulation.step(input: .init(movement: .init(x: 1, y: 0), autoFireEnabled: false))
    }
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == RunReceipt.schemaVersion)
    #expect(receipt.schemaVersion == 4)
    #expect(!receipt.directorDecisions.isEmpty)
    #expect(simulation.state.suspicionDirector.activeActionId != nil)
    #expect(
        receipt.eventSequence.contains(where: { $0.event.kind == .directorDecision })
    )
    // Decisions must match event messages (no invented narrative).
    for decision in receipt.directorDecisions {
        #expect(
            receipt.eventSequence.contains(where: {
                $0.event.kind == .directorDecision && $0.event.message.contains(decision.actionId)
            })
        )
    }
}

@Test func identicalSeedReplaysDirectorTrace() {
    func run() -> (RunReceipt, SuspicionDirectorState) {
        var simulation = Simulation(seed: 777_001)
        for _ in 0..<(60 * 10) {
            _ = simulation.step(input: .init(movement: .init(x: 0.5, y: 0.2), autoFireEnabled: true))
        }
        return (simulation.runReceipt(), simulation.state.suspicionDirector)
    }
    let a = run()
    let b = run()
    #expect(a.0 == b.0)
    #expect(a.1 == b.1)
    #expect(a.0.directorDecisions.map(\.actionId) == b.0.directorDecisions.map(\.actionId))
}

@Test func directorCatalogRejectsHiddenScalingFlag() throws {
    let catalog = try SuspicionDirectorCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    try catalog.validate()
}
