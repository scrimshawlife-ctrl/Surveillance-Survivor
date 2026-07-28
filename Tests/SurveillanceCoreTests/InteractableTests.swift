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
    #expect(receipt.schemaVersion == 12)
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

@Test func allTenCitiesDeclareDistinctExplicitMechanics() {
    let catalog = InteractableCatalog.bundled
    let expected: [DistrictID: String] = [
        .wichita: "Progressive airspace reveal",
        .louisville: "Map redaction blackout",
        .tulsa: "Behavioral crude pressure redirect",
        .dayton: "Forward gateway chain",
        .oakland: "Borrowed jurisdiction handoff",
        .sanFrancisco: "Fog warrant policy phase",
        .columbus: "Jurisdiction split and share reroute",
        .newYorkCity: "Borough phase desynchronization",
        .losAngeles: "Accountability handoff and network persistence",
        .atlanta: "Nationwide convergence severance",
    ]

    for (district, label) in expected {
        let definitions = catalog.interactables(for: district)
        #expect(definitions.count >= 6)
        #expect(definitions.allSatisfy { $0.activation.mechanicLabel == label })
        #expect(definitions.allSatisfy { $0.activation.cascadeHits?.count == 1 })
    }
    #expect(Set(expected.values).count == expected.count)
}

@Test func allTenCityMechanicsApplyAuthoredCascadeHits() {
    for district in DistrictID.allCases {
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

@Test func everyAuthoredInteractableActivatesExpectedTargetsAndEventsDeterministically() {
    let catalog = InteractableCatalog.bundled
    let cityCatalog = CityStateCatalog.bundled
    var coveredDistricts = Set<DistrictID>()

    for district in DistrictID.allCases {
        let definitions = catalog.interactables(for: district)
        #expect(definitions.count >= 6, "\(district.rawValue) should keep its authored proof floor")
        coveredDistricts.insert(district)

        for (offset, definition) in definitions.enumerated() {
            let tick = UInt64(1_000 + offset)
            let elapsed = Double(offset + 1)
            let initialDistrict = CityStateEngine.initialState(catalog: cityCatalog, district: district)
            let targetState = [InteractableRuntimeState(id: definition.id)]
            let expectedAffectedNodeIds = [definition.linkedInfrastructureNodeId]
                + (definition.activation.cascadeHits ?? []).map(\.nodeId)

            func activate() -> InteractableStepResult {
                InteractableEngine.tryActivate(
                    catalog: catalog,
                    cityCatalog: cityCatalog,
                    district: district,
                    playerPosition: definition.position,
                    elapsed: elapsed,
                    tick: tick,
                    utilityPressed: true,
                    states: targetState,
                    districtState: initialDistrict
                )
            }

            let result = activate()
            #expect(result == activate(), "\(definition.id) activation must be deterministic")
            #expect(result.samples.count == 1, "\(definition.id) should emit one receipt sample")

            guard let sample = result.samples.first else {
                Issue.record("\(definition.id) did not emit an activation sample")
                continue
            }
            #expect(sample.tick == tick)
            #expect(sample.interactableId == definition.id)
            #expect(sample.label == definition.label)
            #expect(sample.linkedNodeId == definition.linkedInfrastructureNodeId)
            #expect(sample.opportunity == definition.opportunity)
            #expect(sample.cost == definition.cost)
            #expect(sample.integrityHit == definition.activation.integrityHit)
            #expect(sample.mechanicLabel == definition.activation.mechanicLabel)
            #expect(sample.affectedNodeIds == expectedAffectedNodeIds)

            guard let runtime = result.states.first(where: { $0.id == definition.id }) else {
                Issue.record("\(definition.id) missing runtime state after activation")
                continue
            }
            #expect(runtime.activationCount == 1)
            #expect(runtime.availableAtElapsed == elapsed + definition.cooldownSeconds)

            for (nodeId, expectedHit, reasonFragment) in authoredHits(for: definition) {
                let before = initialDistrict.node(id: nodeId)?.integrity
                let after = result.districtState.node(id: nodeId)?.integrity
                #expect(before != nil, "\(definition.id) target \(nodeId) should exist before activation")
                #expect(after != nil, "\(definition.id) target \(nodeId) should exist after activation")
                if let before, let after {
                    #expect(after <= max(0, before - expectedHit) + 0.000_001)
                }
                #expect(result.cityStateEvents.contains {
                    $0.tick == tick
                        && $0.nodeId == nodeId
                        && $0.reason.contains(reasonFragment)
                }, "\(definition.id) should emit a city-state event for \(nodeId)")
            }
        }
    }

    #expect(coveredDistricts == Set(DistrictID.allCases))
}

@Test func simulationReceiptPreservesInteractablePresentationTransitionPayload() {
    let catalog = InteractableCatalog.bundled
    for district in DistrictID.allCases {
        let definition = catalog.interactables(for: district)[0]
        var state = RunState(seed: 900, district: district)
        if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
            state.entities[playerIndex].position = definition.position
            state.entities[playerIndex].health = 1_000_000
        }

        var simulation = Simulation(state: state, rngSeed: 900)
        let events = simulation.step(input: .init(activateUtility: true, autoFireEnabled: false))
        let receipt = simulation.runReceipt()
        let expectedAffectedNodeIds = [definition.linkedInfrastructureNodeId]
            + (definition.activation.cascadeHits ?? []).map(\.nodeId)

        #expect(events.contains { $0.kind == .interactableActivated })
        #expect(receipt.eventSequence.contains { $0.event.kind == .interactableActivated })
        #expect(receipt.interactableActivations.first?.interactableId == definition.id)
        #expect(receipt.interactableActivations.first?.affectedNodeIds == expectedAffectedNodeIds)
        #expect(receipt.interactableActivations.first?.mechanicLabel == definition.activation.mechanicLabel)
    }
}

private func authoredHits(for definition: InteractableDefinition) -> [(nodeId: String, hit: Double, reasonFragment: String)] {
    [(definition.linkedInfrastructureNodeId, definition.activation.integrityHit, "interactable \(definition.id)")]
        + (definition.activation.cascadeHits ?? []).map { cascade in
            (cascade.nodeId, cascade.integrityHit, cascade.reason)
        }
}
