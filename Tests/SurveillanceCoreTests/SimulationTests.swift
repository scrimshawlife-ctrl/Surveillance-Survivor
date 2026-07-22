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

@Test func parkingLotGenerationIsDeterministic() {
    let first = ParkingLotGenerator.generate(seed: 808)
    let second = ParkingLotGenerator.generate(seed: 808)
    #expect(first.layout == second.layout)
    #expect(first.cameras == second.cameras)
    #expect(first.layout.obstacles.count == 5)
    #expect(first.cameras.count == 4)
}

@Test func playerRemainsInsideWorldBounds() {
    var simulation = Simulation(seed: 11)
    for _ in 0..<2_000 {
        _ = simulation.step(input: .init(movement: .init(x: 1, y: 1)))
    }
    let player = simulation.state.entities.first { $0.kind == .player }!
    let bounds = simulation.state.world.bounds
    #expect(player.position.x <= bounds.maxX - player.radius)
    #expect(player.position.y <= bounds.maxY - player.radius)
}

@Test func cameraPolesRotateDeterministically() {
    var simulation = Simulation(seed: 12)
    let initial = simulation.state.entities.first { $0.kind == .cameraPole }!.heading
    for _ in 0..<60 { _ = simulation.step(input: .init()) }
    let updated = simulation.state.entities.first { $0.kind == .cameraPole }!.heading
    #expect(updated != initial)
}

@Test func guardSpawnsUseOneSecondTickCadence() {
    var simulation = Simulation(seed: 13)
    var spawnEvents = 0

    for _ in 0..<120 {
        spawnEvents += simulation.step(input: .init()).filter { $0.message == "Contract security dispatched" }.count
    }

    let guards = simulation.state.entities.filter { $0.kind == .securityGuard }
    #expect(spawnEvents == 2)
    #expect(guards.count == 2)
}

@Test func cameraHeadingsRemainNormalized() {
    var simulation = Simulation(seed: 14)

    for _ in 0..<10_000 { _ = simulation.step(input: .init()) }

    let headings = simulation.state.entities
        .filter { $0.kind == .cameraPole }
        .map(\.heading)
    #expect(headings.allSatisfy { $0 >= 0 && $0 < .pi * 2 })
}

@Test func playerDoesNotEnterCentralObstacle() {
    var simulation = Simulation(seed: 15)

    for _ in 0..<600 {
        _ = simulation.step(input: .init(movement: .init(x: 0, y: 1)))
    }

    let player = simulation.state.entities.first { $0.kind == .player }!
    #expect(player.position.y <= -96)
}

@Test func automaticFireDestroysACameraPoleDeterministically() {
    var simulation = Simulation(seed: 16)
    for _ in 0..<600 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .cameraPole }.count < 4)
    #expect(simulation.state.dataShards > 0)
}

@Test func projectilesDoNotAccumulateAtWorldEdges() {
    var simulation = Simulation(seed: 17)
    for _ in 0..<3_600 { _ = simulation.step(input: .init()) }
    #expect(simulation.state.entities.filter { $0.kind == .projectile }.count < 20)
}
