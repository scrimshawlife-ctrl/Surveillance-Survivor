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
    #expect(receipt.schemaVersion == 11)
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

@Test func firstFiveCitiesDeclareDistinctExplicitMechanics() {
    let catalog = InteractableCatalog.bundled
    let expected: [DistrictID: String] = [
        .wichita: "Progressive airspace reveal",
        .louisville: "Map redaction blackout",
        .tulsa: "Behavioral crude pressure redirect",
        .dayton: "Forward gateway chain",
        .oakland: "Borrowed jurisdiction handoff",
    ]

    for (district, label) in expected {
        let definitions = catalog.interactables(for: district)
        #expect(definitions.count >= 6)
        #expect(definitions.allSatisfy { $0.activation.mechanicLabel == label })
        #expect(definitions.allSatisfy { $0.activation.cascadeHits?.count == 1 })
    }
    #expect(Set(expected.values).count == expected.count)
}

@Test func firstFiveCityMechanicsApplyAuthoredCascadeHits() {
    for district in [DistrictID.wichita, .louisville, .tulsa, .dayton, .oakland] {
        let definition = InteractableCatalog.bundled.interactables(for: district)[0]
        guard let cascade = definition.activation.cascadeHits?.first else {
            Issue.record("\(district.rawValue) requires an explicit cascade")
            continue
        }
        let initial = CityStateEngine.initialState(district: district)
        let beforeSecondary = initial.node(id: cascade.nodeId)?.integrity
        let result = InteractableEngine.tryActivate(
            district: district,
            playerPosition: definition.position,
            elapsed: 1,
            tick: 90,
            utilityPressed: true,
            states: InteractableEngine.initialStates(district: district),
            districtState: initial
        )

        #expect(result.samples.first?.mechanicLabel == definition.activation.mechanicLabel)
        #expect(result.samples.first?.affectedNodeIds?.contains(cascade.nodeId) == true)
        #expect((result.districtState.node(id: cascade.nodeId)?.integrity ?? 1) < (beforeSecondary ?? 1))
        #expect(result.cityStateEvents.contains {
            $0.nodeId == cascade.nodeId
                && $0.reason.contains(definition.activation.mechanicLabel ?? "")
        })
    }
}
