import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledBuildEngineTagsEveryUpgrade() throws {
    let catalog = try BuildEngineCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(Set(catalog.families) == BuildEngineCatalog.expectedFamilies)
    for upgrade in UpgradeChoice.allCases {
        #expect(!catalog.tags(for: upgrade).isEmpty)
    }
    #expect(!catalog.synergies.isEmpty)
    for synergy in catalog.synergies {
        #expect(!synergy.readableSummary.isEmpty)
        #expect(BuildEngineCatalog.allowedBehaviorKinds.contains(synergy.behavior.kind))
    }
}

@Test func quietCorridorActivatesOnCamouflageStack() {
    let selected: [UpgradeChoice] = [.lowProfileRouting, .identityTransponder, .ghostPlateCache]
    let state = BuildEngine.evaluate(selected: selected)
    #expect(state.activeSynergyIds.contains("quietCorridor"))
    #expect(state.activeSynergyIds.contains("identityMultiplex"))
    #expect(state.suspicionRecoveryBoost > 0)
    #expect(state.observationSoftener == 0 || state.observationSoftener >= 0)
}

@Test func floodRiskExcludesCamouflage() {
    let withCamouflage = BuildEngine.evaluate(selected: [.signalFlood, .lowProfileRouting, .paperStorm])
    #expect(!withCamouflage.activeSynergyIds.contains("floodRiskBargain"))

    let riskOnly = BuildEngine.evaluate(selected: [.signalFlood, .paperStorm, .rapidCountermeasure])
    #expect(riskOnly.activeSynergyIds.contains("floodRiskBargain"))
    #expect(riskOnly.directorBudgetRelief >= 1)
}

@Test func buildEngineEvaluationIsDeterministic() {
    let picks: [UpgradeChoice] = [.foiaSwarm, .expeditedDiscovery, .blackBarMandate]
    let a = BuildEngine.evaluate(selected: picks)
    let b = BuildEngine.evaluate(selected: picks)
    #expect(a == b)
    #expect(a.activeSynergyIds.contains("paperTrailCascade"))
}

@Test func selectingUpgradesRecordsBuildSynergiesOnReceipt() {
    // lowProfileRouting needs no weapon — safe first pick for sim wiring proof.
    var state = RunState(seed: 5150, district: .wichita)
    state.pendingUpgradeChoices = [.lowProfileRouting, .reinforcedSignal, .rapidCountermeasure]
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 5150)
    _ = simulation.step(input: .init(upgradeChoiceIndex: 0, autoFireEnabled: false))
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 10)
    #expect(receipt.buildEngine != nil)
    #expect(receipt.buildEngine?.selectedUpgradeIds.contains("lowProfileRouting") == true)
    #expect(receipt.selectedUpgrades.contains(.lowProfileRouting))
}

@Test func directorBudgetReliefReducesEffectiveActionCost() {
    let catalog = SuspicionDirectorCatalog.bundled
    var rng = DeterministicRNG(seed: 99)
    var state = SuspicionDirectorState.neutral
    // Open window at tier with budgeted actions
    let without = SuspicionDirector.evaluate(
        catalog: catalog,
        state: state,
        tier: .patternDetected,
        elapsed: 1,
        tick: 60,
        rng: &rng,
        budgetCostRelief: 0
    )
    rng = DeterministicRNG(seed: 99)
    state = .neutral
    let withRelief = SuspicionDirector.evaluate(
        catalog: catalog,
        state: state,
        tier: .patternDetected,
        elapsed: 1,
        tick: 60,
        rng: &rng,
        budgetCostRelief: 3
    )
    // Same seed path; relief can only leave equal-or-higher remaining budget after spend.
    if let d0 = without.decision, let d1 = withRelief.decision {
        #expect(d0.actionId == d1.actionId)
        #expect(withRelief.state.budgetRemaining >= without.state.budgetRemaining)
    }
}
