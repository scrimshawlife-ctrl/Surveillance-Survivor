import Foundation

public struct Simulation: Sendable {
    public private(set) var state: RunState
    private var rng: DeterministicRNG
    private var tick: UInt64 = 0
    public let fixedStep: Double

    public init(seed: UInt64, fixedStep: Double = 1.0 / 60.0) {
        state = RunState(seed: seed)
        rng = DeterministicRNG(seed: seed)
        self.fixedStep = fixedStep
    }

    public mutating func step(input: PlayerInput) -> [RunEvent] {
        var events: [RunEvent] = []
        tick &+= 1
        state.elapsed += fixedStep
        movePlayer(input)
        updateSecurityMovement()
        moveEntitiesWithinWorld()
        autoAttack(events: &events)
        resolveProjectileHits()
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
            if kind == .projectile, clamped != proposed {
                state.entities[index].health = 0
                continue
            }
            state.entities[index].position = kind == .projectile || !collidesWithObstacle(clamped, radius: state.entities[index].radius) ? clamped : previous
        }
    }

    private mutating func autoAttack(events: inout [RunEvent]) {
        guard tick.isMultiple(of: 15), let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let targets = state.entities.filter { $0.kind == .cameraPole && $0.health > 0 }
        guard let target = targets.min(by: {
            let left = ($0.position - player.position).magnitude
            let right = ($1.position - player.position).magnitude
            return left == right ? $0.id < $1.id : left < right
        }), (target.position - player.position).magnitude <= 1_000 else { return }
        let direction = (target.position - player.position).normalized()
        state.entities.append(Entity(id: rng.next(), kind: .projectile, position: player.position, velocity: direction * 600, health: 1, radius: 5))
        events.append(.init(.entitySpawned, "Automatic countermeasure fired"))
    }

    private mutating func resolveProjectileHits() {
        for projectileIndex in state.entities.indices where state.entities[projectileIndex].kind == .projectile && state.entities[projectileIndex].health > 0 {
            guard let targetIndex = state.entities.indices.first(where: { index in
                let target = state.entities[index]
                guard target.kind == .cameraPole || target.kind == .securityGuard else { return false }
                return target.health > 0 && (target.position - state.entities[projectileIndex].position).magnitude <= target.radius + state.entities[projectileIndex].radius
            }) else { continue }
            state.entities[targetIndex].health -= 15
            state.entities[projectileIndex].health = 0
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
            state.entities[index].heading = (state.entities[index].heading + speed * fixedStep)
                .truncatingRemainder(dividingBy: .pi * 2)
        }
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let target = min(40, 2 + Int(state.elapsed / 5))
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        guard current < target, tick.isMultiple(of: 60) else { return }
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

        if cameraContacts > 0, tick.isMultiple(of: 30) {
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
