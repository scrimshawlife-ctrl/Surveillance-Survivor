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
        updateSecurityMovement()
        moveEntitiesWithinWorld()
        rotateCameraPoles()
        spawnCadence(events: &events)
        updateSuspicion(events: &events)
        resolveDeaths(events: &events)
        return events
    }

    private mutating func movePlayer(_ input: PlayerInput) {
        guard let index = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        let direction = input.movement.normalized()
        state.entities[index].velocity = direction * 210
    }

    private mutating func updateSecurityMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where state.entities[index].kind == .securityGuard {
            let direction = (player.position - state.entities[index].position).normalized()
            state.entities[index].velocity = direction * 88
            state.entities[index].heading = atan2(direction.y, direction.x)
        }
    }

    private mutating func moveEntitiesWithinWorld() {
        for index in state.entities.indices {
            let kind = state.entities[index].kind
            guard kind == .player || kind == .securityGuard || kind == .projectile || kind == .boss else { continue }

            let previous = state.entities[index].position
            let proposed = previous + state.entities[index].velocity * fixedStep
            let clamped = state.world.bounds.clamped(proposed, margin: state.entities[index].radius)
            state.entities[index].position = collidesWithObstacle(clamped, radius: state.entities[index].radius) ? previous : clamped
        }
    }

    private func collidesWithObstacle(_ point: Vector2, radius: Double) -> Bool {
        state.world.obstacles.contains { obstacle in
            let closestX = min(max(point.x, obstacle.center.x - obstacle.halfSize.x), obstacle.center.x + obstacle.halfSize.x)
            let closestY = min(max(point.y, obstacle.center.y - obstacle.halfSize.y), obstacle.center.y + obstacle.halfSize.y)
            let dx = point.x - closestX
            let dy = point.y - closestY
            return dx * dx + dy * dy < radius * radius
        }
    }

    private mutating func rotateCameraPoles() {
        let speed = 0.42 + Double(state.suspicionTier.rawValue) * 0.08
        for index in state.entities.indices where state.entities[index].kind == .cameraPole {
            state.entities[index].heading.formTruncatingRemainder(dividingBy: .pi * 2)
            state.entities[index].heading += speed * fixedStep
        }
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let target = min(40, 2 + Int(state.elapsed / 5))
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        guard current < target, Int(state.elapsed * 10) % 10 == 0 else { return }
        let angle = rng.unit() * .pi * 2
        let distance = 500.0
        let proposed = Vector2(x: cos(angle) * distance, y: sin(angle) * distance)
        let entity = Entity(
            id: rng.next(),
            kind: .securityGuard,
            position: state.world.bounds.clamped(proposed, margin: 18),
            health: 20,
            radius: 14
        )
        state.entities.append(entity)
        events.append(.init(.entitySpawned, "Contract security dispatched"))
    }

    private mutating func updateSuspicion(events: inout [RunEvent]) {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let guardCount = state.entities.filter { $0.kind == .securityGuard }.count
        let cameraContacts = state.entities.filter { camera in
            guard camera.kind == .cameraPole, camera.health > 0 else { return false }
            let offset = player.position - camera.position
            guard offset.magnitude <= 430 else { return false }
            let forward = Vector2(x: cos(camera.heading), y: sin(camera.heading))
            return forward.dot(offset.normalized()) >= cos(.pi / 7)
        }.count

        let priorTier = state.suspicionTier
        let passivePressure = Double(guardCount) * 0.12
        let sensorPressure = Double(cameraContacts) * 6.0
        let decay = cameraContacts == 0 ? 0.35 : 0
        state.suspicion = min(100, max(0, state.suspicion + (passivePressure + sensorPressure - decay) * fixedStep))

        if cameraContacts > 0, Int(state.elapsed * 2) % 2 == 0 {
            events.append(.init(.sensorContact, "LPR scan contact"))
        }

        let rawTier = min(5, Int(state.suspicion / 20))
        state.suspicionTier = SuspicionTier(rawValue: rawTier) ?? .totalVisibility
        if state.suspicionTier != priorTier {
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
