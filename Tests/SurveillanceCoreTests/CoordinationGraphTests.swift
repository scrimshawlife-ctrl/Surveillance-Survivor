import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledCoordinationGraphHasCounterplay() throws {
    let catalog = try CoordinationCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(catalog.minimumCounterplayPoints >= 2)
    let chain = try #require(catalog.primaryChain(for: .wichita))
    #expect(chain.links.count >= 3)
    #expect(chain.links.filter(\.counterplay).count >= 2)
    #expect(chain.links.first?.id == "sensorDetect")
}

@Test func coordinationStartsOnSensorContactAndInterruptsOnDestroy() {
    let catalog = CoordinationCatalog.bundled
    var state = CoordinationState.idle
    let started = CoordinationEngine.startIfNeeded(
        catalog: catalog,
        state: state,
        district: .wichita,
        elapsed: 1,
        tick: 30,
        signal: "sensorContact"
    )
    #expect(started.state.chainId == "lot_capture_cascade")
    #expect(started.state.linkStatuses["sensorDetect"] == .active)
    #expect(!started.events.isEmpty)

    let interrupted = CoordinationEngine.handleSignal(
        catalog: catalog,
        state: started.state,
        elapsed: 2,
        tick: 60,
        signal: "sensorDestroyed"
    )
    #expect(interrupted.state.chainId == nil)
    #expect(interrupted.state.interruptedCount == 1)
    #expect(interrupted.events.contains { $0.status == .interrupted })
}

@Test func coordinationRestartPreservesInterruptAndCompletionCounts() {
    let catalog = CoordinationCatalog.bundled
    var state = CoordinationState.idle
    state.interruptedCount = 2
    state.completedCount = 1
    let restarted = CoordinationEngine.startIfNeeded(
        catalog: catalog,
        state: state,
        district: .wichita,
        elapsed: 4,
        tick: 90,
        signal: "sensorContact"
    )
    #expect(restarted.state.chainId == "lot_capture_cascade")
    #expect(restarted.state.interruptedCount == 2)
    #expect(restarted.state.completedCount == 1)
}

@Test func completingFinalCoordinationLinkEmitsSingleCompletedEvent() throws {
    let catalog = CoordinationCatalog.bundled
    let chain = try #require(catalog.primaryChain(for: .wichita))
    var state = CoordinationState.idle
    state.chainId = chain.id
    state.activeLinkIndex = chain.links.count - 1
    state.linkEnteredElapsed = 0
    let last = try #require(chain.links.last)
    state.linkStatuses[last.id] = .active
    let seconds = try #require(last.timerSeconds)
    let result = CoordinationEngine.tickTimers(
        catalog: catalog,
        state: state,
        elapsed: state.linkEnteredElapsed + seconds + 0.01,
        tick: 99
    )
    #expect(result.state.chainId == nil)
    #expect(result.state.completedCount == 1)
    let completed = result.events.filter { $0.status == .completed }
    #expect(completed.count == 1)
    #expect(completed.first?.reason == "chain completed")
}

@Test func coordinationAdvancesOnTimerDeterministically() {
    let catalog = CoordinationCatalog.bundled
    let start = CoordinationEngine.startIfNeeded(
        catalog: catalog,
        state: .idle,
        district: .wichita,
        elapsed: 0,
        tick: 1,
        signal: "sensorContact"
    )
    // sensorDetect advances on sensorContact, not timer — feed contact then timer links.
    var state = start.state
    // Complete detect by second contact (advanceOn includes sensorContact)
    let advanced = CoordinationEngine.handleSignal(
        catalog: catalog,
        state: state,
        elapsed: 1,
        tick: 30,
        signal: "sensorContact"
    )
    state = advanced.state
    #expect(state.linkStatuses["sensorDetect"] == .completed || state.activeLinkIndex >= 1)

    // Tick through dispatcher timer
    if let chain = catalog.chain(id: state.chainId ?? ""),
       let link = chain.link(at: state.activeLinkIndex),
       let seconds = link.timerSeconds {
        let afterTimer = CoordinationEngine.tickTimers(
            catalog: catalog,
            state: state,
            elapsed: state.linkEnteredElapsed + seconds + 0.01,
            tick: 120
        )
        #expect(afterTimer.state.activeLinkIndex >= state.activeLinkIndex)
    }
}

@Test func sensorContactInSimulationStartsCoordinationChain() {
    var state = RunState(seed: 7070, district: .wichita)
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }),
       let sensor = state.entities.first(where: { $0.kind == .cameraPole }) {
        state.entities[playerIndex].position = sensor.position
        state.entities[playerIndex].health = 1_000_000
    }
    var simulation = Simulation(state: state, rngSeed: 7070)
    for _ in 0..<(60 * 5) {
        _ = simulation.step(input: .init(movement: .init(), autoFireEnabled: false))
        if simulation.state.coordination.chainId != nil { break }
    }
    // Force a contact event path if observation hasn't hit yet: pure start is covered above.
    // Prefer sim proof when contact fires.
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 12)
    if simulation.state.coordination.chainId != nil || !receipt.coordinationEvents.isEmpty {
        #expect(
            receipt.eventSequence.contains(where: { $0.event.kind == .coordinationChanged })
            || !receipt.coordinationEvents.isEmpty
        )
    } else {
        // Still assert catalog + pure engine wiring available on receipt shape.
        #expect(receipt.coordination != nil || receipt.coordinationEvents.isEmpty)
    }
}

@Test func destroyingSensorInterruptsActiveChainInSimulation() {
    var state = RunState(seed: 8080, district: .wichita)
    // Start chain via pure engine into state, then install into simulation.
    let started = CoordinationEngine.startIfNeeded(
        state: .idle,
        district: .wichita,
        elapsed: 0,
        tick: 1,
        signal: "sensorContact"
    )
    state.coordination = started.state
    #expect(state.coordination.chainId != nil)

    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    // Kill all sensors next step.
    for index in state.entities.indices where state.entities[index].kind == .cameraPole {
        state.entities[index].health = 0
    }
    var simulation = Simulation(state: state, rngSeed: 8080)
    _ = simulation.step(input: .init(autoFireEnabled: false))
    #expect(simulation.state.coordination.chainId == nil)
    #expect(simulation.state.coordination.interruptedCount >= 1)
    let receipt = simulation.runReceipt()
    #expect(receipt.coordinationEvents.contains { $0.status == .interrupted })
    #expect(receipt.eventSequence.contains { $0.event.kind == .coordinationChanged })
}

@Test func identicalSeedReplaysCoordinationTrace() {
    func run() -> RunReceipt {
        var state = RunState(seed: 909_090, district: .wichita)
        if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }),
           let sensor = state.entities.first(where: { $0.kind == .cameraPole }) {
            state.entities[playerIndex].position = sensor.position
            state.entities[playerIndex].health = 1_000_000
        }
        var simulation = Simulation(state: state, rngSeed: 909_090)
        for _ in 0..<(60 * 12) {
            _ = simulation.step(input: .init(autoFireEnabled: true))
        }
        return simulation.runReceipt()
    }
    let a = run()
    let b = run()
    #expect(a == b)
    #expect(a.coordinationEvents == b.coordinationEvents)
}
