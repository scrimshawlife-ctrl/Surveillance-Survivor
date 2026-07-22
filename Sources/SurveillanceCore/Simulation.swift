import Foundation

public struct Simulation: Sendable {
    public private(set) var state: RunState
    private var rng: DeterministicRNG
    public let fixedStep: Double

    public init(seed: UInt64, fixedStep: Double = 1.0 / 60.0) {
        state = RunState(seed: seed)
        rng = DeterministicRNG(seed: seed)
        self.fixedStep = fixedStep
    }

    public mutating func step(input: PlayerInput) -> [RunEvent] {
        var events: [RunEvent] = []
        state.elapsed += fixedStep
        movePlayer(input)
        moveEntities()
        spawnCadence(events: &events)
        updateSuspicion(events: &events)
        resolveDeaths(events: &events)
        return events
    }

    private mutating func movePlayer(_ input: PlayerInput) {
        guard let index = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        let direction = input.movement.normalized()
        state.entities[index].velocity = Vector2(x: direction.x * 210, y: direction.y * 210)
    }

    private mutating func moveEntities() {
        for index in state.entities.indices {
            state.entities[index].position.x += state.entities[index].velocity.x * fixedStep
            state.entities[index].position.y += state.entities[index].velocity.y * fixedStep
        }
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let target = min(40, 2 + Int(state.elapsed / 5))
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        guard current < target, Int(state.elapsed * 10) % 10 == 0 else { return }
        let angle = rng.unit() * .pi * 2
        let distance = 500.0
        let entity = Entity(
            id: rng.next(),
            kind: .securityGuard,
            position: .init(x: cos(angle) * distance, y: sin(angle) * distance),
            health: 20,
            radius: 14
        )
        state.entities.append(entity)
        events.append(.init(.entitySpawned, "Contract security dispatched"))
    }

    private mutating func updateSuspicion(events: inout [RunEvent]) {
        let count = state.entities.filter { $0.kind == .securityGuard }.count
        let prior = state.suspicionTier
        state.suspicion = min(100, max(0, state.suspicion + Double(count) * fixedStep * 0.12))
        let rawTier = min(5, Int(state.suspicion / 20))
        state.suspicionTier = SuspicionTier(rawValue: rawTier) ?? .totalVisibility
        if state.suspicionTier != prior {
            events.append(.init(.tierChanged, "Suspicion escalated to tier \(rawTier)"))
        }
    }

    private mutating func resolveDeaths(events: inout [RunEvent]) {
        let removed = state.entities.filter { $0.health <= 0 }
        if removed.contains(where: { $0.kind == .boss }) { state.bossDefeated = true }
        state.entities.removeAll { $0.health <= 0 }
        for entity in removed {
            events.append(.init(.entityDestroyed, "Removed \(entity.kind.rawValue)"))
        }
        if state.bossDefeated && !state.extractionOpen {
            state.extractionOpen = true
            state.entities.append(Entity(id: rng.next(), kind: .extraction, position: .init(x: 300, y: 0), health: 1_000_000, radius: 60))
            events.append(.init(.extractionOpened, "Blind Spot opened"))
        }
    }
}
