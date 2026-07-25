import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledCityStateCatalogLoadsWichitaGraph() throws {
    let catalog = try CityStateCatalog.loadBundled()
    #expect(catalog.schemaVersion == CityStateCatalog.currentSchemaVersion)
    #expect(catalog.forbidHiddenStatScaling)
    #expect(Set(catalog.nodeFamilies) == CityStateCatalog.expectedFamilies)
    let graph = try #require(catalog.graph(for: .wichita))
    #expect(graph.nodes.count >= 3)
    #expect(!graph.edges.isEmpty)
    #expect(graph.nodes.contains { $0.family == "surveillanceSensors" })
    #expect(graph.nodes.contains { $0.family == "electricalPower" })
    // Opportunity + cost required on every node
    #expect(graph.nodes.allSatisfy { !$0.opportunityOnOffline.isEmpty && !$0.costOnOffline.isEmpty })
}

@Test func cityStatePropagationIsDeterministic() throws {
    let catalog = CityStateCatalog.bundled
    let start = CityStateEngine.initialState(catalog: catalog, district: .wichita)
    let nodeId = try #require(CityStateEngine.primarySurveillanceNodeId(catalog: catalog, district: .wichita))
    let a = CityStateEngine.applyHit(
        catalog: catalog,
        state: start,
        nodeId: nodeId,
        amount: 0.4,
        tick: 10,
        reason: "test hit"
    )
    let b = CityStateEngine.applyHit(
        catalog: catalog,
        state: start,
        nodeId: nodeId,
        amount: 0.4,
        tick: 10,
        reason: "test hit"
    )
    #expect(a.0 == b.0)
    #expect(a.1 == b.1)
    #expect(!a.1.isEmpty)
    #expect(a.0.nodes.contains { $0.id == nodeId && $0.integrity < 1 })
}

@Test func observationMultiplierSoftensWithoutTouchingHealth() {
    var state = CityStateEngine.initialState(district: .wichita)
    #expect(CityStateEngine.observationPressureMultiplier(state: state) == 1.0)
    if let idx = state.nodes.firstIndex(where: { $0.family == "surveillanceSensors" }) {
        state.nodes[idx].integrity = 0.1
        state.nodes[idx].status = .offline
    }
    #expect(CityStateEngine.observationPressureMultiplier(state: state) == 0.65)
}

@Test func destroyingSensorsRecordsCityStateOnReceipt() {
    var state = RunState(seed: 9090, district: .wichita)
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }),
       let sensor = state.entities.first(where: { $0.kind == .cameraPole }) {
        state.entities[playerIndex].position = sensor.position
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 9090)
    for _ in 0..<(60 * 30) {
        _ = simulation.step(input: .init(autoFireEnabled: true))
        if !simulation.runReceipt().cityStateEvents.isEmpty { break }
    }
    // Force path: zero remaining sensors if combat didn't finish them.
    if simulation.runReceipt().cityStateEvents.isEmpty {
        var forced = simulation.state
        for index in forced.entities.indices where forced.entities[index].kind == .cameraPole {
            forced.entities[index].health = 0
        }
        simulation = Simulation(state: forced, rngSeed: 9091)
        _ = simulation.step(input: .init(autoFireEnabled: false))
    }
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 4)
    #expect(!receipt.cityStateEvents.isEmpty)
    #expect(receipt.districtState != nil)
    #expect(
        receipt.eventSequence.contains(where: { $0.event.kind == .cityStateChanged })
    )
    let catalog = CityStateCatalog.bundled
    if let changed = receipt.cityStateEvents.first {
        let def = catalog.graph(for: .wichita)?.node(id: changed.nodeId)
        #expect(def != nil)
        #expect(def?.opportunityOnOffline.isEmpty == false)
        #expect(def?.costOnOffline.isEmpty == false)
    }
}

@Test func identicalSeedReplaysCityStateTrace() {
    func run() -> RunReceipt {
        var state = RunState(seed: 424_242, district: .wichita)
        if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }),
           let sensor = state.entities.first(where: { $0.kind == .cameraPole }) {
            state.entities[playerIndex].position = sensor.position
            state.entities[playerIndex].health = 1_000_000
        }
        var simulation = Simulation(state: state, rngSeed: 424_242)
        for _ in 0..<(60 * 20) {
            _ = simulation.step(input: .init(autoFireEnabled: true))
        }
        return simulation.runReceipt()
    }
    let a = run()
    let b = run()
    #expect(a == b)
    #expect(a.cityStateEvents == b.cityStateEvents)
    #expect(a.districtState == b.districtState)
}
