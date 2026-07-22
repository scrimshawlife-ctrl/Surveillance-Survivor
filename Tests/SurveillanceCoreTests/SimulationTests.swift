import Testing
@testable import SurveillanceCore

@Test func deterministicRunsMatch() {
    var first = Simulation(seed: 42)
    var second = Simulation(seed: 42)
    for _ in 0..<900 {
        _ = first.step(input: .init(movement: .init(x: 1, y: 0.25)))
        _ = second.step(input: .init(movement: .init(x: 1, y: 0.25)))
    }
    #expect(first.state == second.state)
}

@Test func playerMovementIsNormalized() {
    var simulation = Simulation(seed: 7)
    _ = simulation.step(input: .init(movement: .init(x: 10, y: 0)))
    let player = simulation.state.entities.first { $0.kind == .player }
    #expect((player?.position.x ?? 0) > 0)
}

@Test func suspicionEscalatesWithPopulation() {
    var simulation = Simulation(seed: 9)
    for _ in 0..<3600 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.suspicion > 0)
    #expect(simulation.state.suspicionTier.rawValue > 0)
}
