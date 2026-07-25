import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledInteractablesMeetWichitaProofFloor() throws {
    let catalog = try InteractableCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    let wichita = catalog.interactables(for: .wichita)
    #expect(wichita.count >= 6)
    #expect(wichita.allSatisfy { !$0.opportunity.isEmpty && !$0.cost.isEmpty })
    try catalog.validate()
}

@Test func interactableActivationStressesLinkedNode() {
    let catalog = InteractableCatalog.bundled
    let def = catalog.interactables(for: .wichita)[0]
    var states = InteractableEngine.initialStates(district: .wichita)
    let district = CityStateEngine.initialState(district: .wichita)
    let result = InteractableEngine.tryActivate(
        district: .wichita,
        playerPosition: def.position,
        elapsed: 1,
        tick: 60,
        utilityPressed: true,
        states: states,
        districtState: district
    )
    #expect(!result.samples.isEmpty)
    #expect(result.samples[0].interactableId == def.id)
    #expect(result.districtState.node(id: def.linkedInfrastructureNodeId)?.integrity ?? 1 < 1)
    #expect(!result.cityStateEvents.isEmpty)
    // Cooldown engaged
    states = result.states
    let blocked = InteractableEngine.tryActivate(
        district: .wichita,
        playerPosition: def.position,
        elapsed: 1.1,
        tick: 61,
        utilityPressed: true,
        states: states,
        districtState: result.districtState
    )
    #expect(blocked.samples.isEmpty)
}

@Test func simulationUtilityActivatesNearestInteractable() {
    var state = RunState(seed: 11, district: .wichita)
    let def = InteractableCatalog.bundled.interactables(for: .wichita)[0]
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].position = def.position
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 11)
    _ = simulation.step(input: .init(activateUtility: true, autoFireEnabled: false))
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 9)
    #expect(!receipt.interactableActivations.isEmpty)
    #expect(
        receipt.eventSequence.contains { $0.event.kind == .interactableActivated }
    )
}

@Test func interactableActivationIsSeedDeterministic() {
    func run() -> RunReceipt {
        var state = RunState(seed: 22, district: .wichita)
        let def = InteractableCatalog.bundled.interactables(for: .wichita)[1]
        if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
            state.entities[playerIndex].position = def.position
            state.entities[playerIndex].health = 1_000_000
        }
        var simulation = Simulation(state: state, rngSeed: 22)
        _ = simulation.step(input: .init(activateUtility: true, autoFireEnabled: false))
        for _ in 0..<30 {
            _ = simulation.step(input: .init(autoFireEnabled: false))
        }
        return simulation.runReceipt()
    }
    #expect(run() == run())
}
