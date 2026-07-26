import Foundation
import Testing
@testable import SurveillanceCore

/// Small, stable invariants intended for CI repetition and external automation agents.
/// These tests avoid balancing constants and authored-content counts so they remain
/// durable while gameplay content evolves.

@Test func automationIdenticalInputTranscriptProducesIdenticalStateAndReceipt() {
    let inputs = (0..<360).map { tick in
        PlayerInput(
            movement: Vector2(
                x: tick.isMultiple(of: 120) ? -1 : 1,
                y: tick.isMultiple(of: 90) ? 0.5 : -0.25
            ),
            activateUtility: tick.isMultiple(of: 180),
            autoFireEnabled: true,
            suppressThreatContact: true
        )
    }

    var first = Simulation(seed: 0xA11CE)
    var second = Simulation(seed: 0xA11CE)

    for input in inputs {
        let firstEvents = first.step(input: input)
        let secondEvents = second.step(input: input)
        #expect(firstEvents == secondEvents)
    }

    #expect(first.state == second.state)
    #expect(first.runReceipt() == second.runReceipt())
}

@Test func automationCompletedRunIsStrictlyImmutable() {
    var completed = RunState(seed: 77)
    completed.runCompleted = true
    completed.playerDefeated = false

    var simulation = Simulation(state: completed, rngSeed: 77)
    let beforeState = simulation.state
    let beforeReceipt = simulation.runReceipt()

    let events = simulation.step(
        input: PlayerInput(
            movement: .init(x: 1, y: 1),
            activateUtility: true,
            upgradeChoiceIndex: 0,
            autoFireEnabled: true,
            suppressThreatContact: false
        )
    )

    #expect(events.isEmpty)
    #expect(simulation.state == beforeState)
    #expect(simulation.runReceipt() == beforeReceipt)
}

@Test func automationFixedStepAdvancesElapsedTimeExactly() {
    var state = RunState(seed: 91)
    state.entities = [
        Entity(
            id: 1,
            kind: .player,
            position: .init(),
            health: 1_000_000,
            radius: 18
        )
    ]
    state.activeWeapons = []

    let fixedStep = 1.0 / 30.0
    var simulation = Simulation(state: state, rngSeed: 91, fixedStep: fixedStep)
    let stepCount = 240

    for _ in 0..<stepCount {
        _ = simulation.step(
            input: .init(
                autoFireEnabled: false,
                suppressThreatContact: true
            )
        )
    }

    #expect(abs(simulation.state.elapsed - (Double(stepCount) * fixedStep)) < 0.000_000_1)
    #expect(simulation.runReceipt().elapsedTicks == UInt64(stepCount))
}

@Test func automationRunStateCodableRoundTripPreservesAuthoritativeState() throws {
    var simulation = Simulation(seed: 0xC0FFEE)
    for tick in 0..<180 {
        _ = simulation.step(
            input: .init(
                movement: .init(x: tick.isMultiple(of: 2) ? 1 : -0.25, y: 0.5),
                activateUtility: tick.isMultiple(of: 60),
                autoFireEnabled: true,
                suppressThreatContact: true
            )
        )
    }

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let payload = try encoder.encode(simulation.state)
    let decoded = try JSONDecoder().decode(RunState.self, from: payload)

    #expect(decoded == simulation.state)
    #expect(try encoder.encode(decoded) == payload)
}

@Test func automationReceiptEventSequenceIsStrictlyMonotonic() {
    var simulation = Simulation(seed: 314_159)
    for _ in 0..<300 {
        _ = simulation.step(
            input: .init(
                movement: .init(x: 0.75, y: 0.25),
                autoFireEnabled: true,
                suppressThreatContact: true
            )
        )
    }

    let sequence = simulation.runReceipt().eventSequence
    for pair in zip(sequence, sequence.dropFirst()) {
        #expect(pair.0.sequence < pair.1.sequence)
        #expect(pair.0.tick <= pair.1.tick)
    }
}
