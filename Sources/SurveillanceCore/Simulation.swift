import Foundation

public struct Simulation: Sendable {
    public private(set) var state: RunState
    private var rng: DeterministicRNG
    private var tick: UInt64 = 0
    public let fixedStep: Double

    public init(
        seed: UInt64,
        fixedStep: Double = 1.0 / 60.0,
        activeWeapons: [WeaponSystem] = [.baselineKinetic]
    ) {
        state = RunState(seed: seed, activeWeapons: activeWeapons)
        rng = DeterministicRNG(seed: seed)
        self.fixedStep = fixedStep
    }

    public mutating func step(input: PlayerInput) -> [RunEvent] {
        var events: [RunEvent] = []
        tick &+= 1
        state.elapsed += fixedStep
        updateStatusEffects()
        movePlayer(input)
        updateSecurityMovement()
        moveEntitiesWithinWorld()
        fireActiveWeapons(events: &events)
        resolveProjectileHits(events: &events)
        rotateCameraPoles()
        spawnCadence(events: &events)
        updateSuspicion(events: &events)
        resolveDeaths(events: &events)
        return events
    }

    private mutating func updateStatusEffects() {
        for index in state.entities.indices {
            if state.entities[index].sensorDisabledTicks > 0 {
                state.entities[index].sensorDisabledTicks -= 1
            }
            if state.entities[index].identitySpoofedTicks > 0 {
                state.entities[index].identitySpoofedTicks -= 1
            }
        }
    }

    private mutating func movePlayer(_ input: PlayerInput) {
        guard let index = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        state.entities[index].velocity = input.movement.normalized() * 210
    }

    private mutating func updateSecurityMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where state.entities[index].kind == .securityGuard {
            guard state.entities[index].identitySpoofedTicks == 0 else {
                state.entities[index].velocity = .init()
                continue
            }
            let direction = (player.position - state.entities[index].position).normalized()
            state.entities[index].velocity = direction * 88
            state.entities[index].heading = atan2(direction.y, direction.x)
        }
    }

    private mutating func moveEntitiesWithinWorld() {
        for index in state.entities.indices {
            let kind = state.entities[index].kind
            guard [.player, .securityGuard, .projectile, .boss].contains(kind) else { continue }
            let previous = state.entities[index].position
            let proposed = previous + state.entities[index].velocity * fixedStep
            let clamped = state.world.bounds.clamped(proposed, margin: state.entities[index].radius)
            if kind == .projectile && clamped != proposed {
                state.entities[index].health = 0
            } else if kind == .projectile || !collidesWithObstacle(clamped, radius: state.entities[index].radius) {
                state.entities[index].position = clamped
            }
        }
    }

    private mutating func fireActiveWeapons(events: inout [RunEvent]) {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let weapons = Array(state.activeWeapons.prefix(CombatLimits.maximumActiveWeapons))
        for weapon in weapons where tick.isMultiple(of: weapon.cadenceTicks) {
            let projectileCount = state.entities.filter { $0.kind == .projectile && $0.health > 0 }.count
            guard projectileCount < CombatLimits.maximumProjectiles else { break }
            guard let target = selectTarget(for: weapon, from: player.position) else { continue }
            let direction = (target.position - player.position).normalized()
            state.entities.append(Entity(
                id: rng.next(),
                kind: .projectile,
                position: player.position,
                velocity: direction * weapon.projectileSpeed,
                health: 1,
                radius: weapon.projectileRadius,
                sourceWeapon: weapon.id,
                payload: weapon.payload
            ))
            events.append(.init(.weaponFired, "\(weapon.id.rawValue) fired at \(target.kind.rawValue)"))
        }
    }

    private func selectTarget(for weapon: WeaponSystem, from origin: Vector2) -> Entity? {
        func nearest(_ kinds: Set<EntityKind>) -> Entity? {
            state.entities
                .filter { kinds.contains($0.kind) && $0.health > 0 && ($0.position - origin).magnitude <= weapon.range }
                .min {
                    let left = ($0.position - origin).magnitude
                    let right = ($1.position - origin).magnitude
                    return left == right ? $0.id < $1.id : left < right
                }
        }
        switch weapon.targetingRule {
        case .nearestCameraThenThreat: return nearest([.cameraPole]) ?? nearest([.securityGuard, .boss])
        case .nearestThreat: return nearest([.securityGuard, .boss])
        case .nearestCamera: return nearest([.cameraPole])
        }
    }

    private mutating func resolveProjectileHits(events: inout [RunEvent]) {
        for projectileIndex in state.entities.indices where state.entities[projectileIndex].kind == .projectile && state.entities[projectileIndex].health > 0 {
            guard let targetIndex = state.entities.indices.first(where: { index in
                let target = state.entities[index]
                guard [.cameraPole, .securityGuard, .boss].contains(target.kind) else { return false }
                return target.health > 0 && (target.position - state.entities[projectileIndex].position).magnitude <= target.radius + state.entities[projectileIndex].radius
            }) else { continue }

            switch state.entities[projectileIndex].payload {
            case .some(.damage(let amount)):
                state.entities[targetIndex].health -= amount
                events.append(.init(.countermeasureHit, "Dealt \(amount) damage to \(state.entities[targetIndex].kind.rawValue)"))

            case .some(.disableSensor(let durationTicks)):
                guard state.entities[targetIndex].kind == .cameraPole else { break }
                state.entities[targetIndex].sensorDisabledTicks = max(
                    state.entities[targetIndex].sensorDisabledTicks,
                    durationTicks
                )
                events.append(.init(.statusApplied, "Redacted camera sensor for \(durationTicks) ticks"))

            case .some(.spoofIdentity(let durationTicks, let suspicionReduction)):
                state.entities[targetIndex].identitySpoofedTicks = max(
                    state.entities[targetIndex].identitySpoofedTicks,
                    durationTicks
                )
                state.suspicion = max(0, state.suspicion - suspicionReduction)
                events.append(.init(.statusApplied, "Spoofed \(state.entities[targetIndex].kind.rawValue) identity for \(durationTicks) ticks"))

            case nil:
                break
            }
            state.entities[projectileIndex].health = 0
        }
    }

    private func collidesWithObstacle(_ point: Vector2, radius: Double) -> Bool {
        state.world.obstacles.contains { obstacle in
            let x = min(max(point.x, obstacle.center.x - obstacle.halfSize.x), obstacle.center.x + obstacle.halfSize.x)
            let y = min(max(point.y, obstacle.center.y - obstacle.halfSize.y), obstacle.center.y + obstacle.halfSize.y)
            let dx = point.x - x
            let dy = point.y - y
            return dx * dx + dy * dy < radius * radius
        }
    }

    private mutating func rotateCameraPoles() {
        let speed = 0.42 + Double(state.suspicionTier.rawValue) * 0.08
        for index in state.entities.indices where state.entities[index].kind == .cameraPole {
            guard state.entities[index].sensorDisabledTicks == 0 else { continue }
            state.entities[index].heading = (state.entities[index].heading + speed * fixedStep).truncatingRemainder(dividingBy: .pi * 2)
        }
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let target = min(40, 2 + Int(state.elapsed / 5))
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        guard current < target && tick.isMultiple(of: 60) else { return }
        let angle = rng.unit() * .pi * 2
        let proposed = Vector2(x: cos(angle) * 500, y: sin(angle) * 500)
        state.entities.append(Entity(
            id: rng.next(),
            kind: .securityGuard,
            position: state.world.bounds.clamped(proposed, margin: 18),
            health: 20,
            radius: 14
        ))
        events.append(.init(.entitySpawned, "Contract security dispatched"))
    }

    private mutating func updateSuspicion(events: inout [RunEvent]) {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let guardCount = state.entities.filter {
            $0.kind == .securityGuard && $0.health > 0 && $0.identitySpoofedTicks == 0
        }.count
        let contacts = state.entities.filter { camera in
            guard camera.kind == .cameraPole,
                  camera.health > 0,
                  camera.sensorDisabledTicks == 0,
                  camera.identitySpoofedTicks == 0 else { return false }
            let offset = player.position - camera.position
            guard offset.magnitude <= 430 else { return false }
            return Vector2(x: cos(camera.heading), y: sin(camera.heading)).dot(offset.normalized()) >= cos(.pi / 7)
        }.count
        let priorTier = state.suspicionTier
        let pressure = Double(guardCount) * 0.12 + Double(contacts) * 6.0 - (contacts == 0 ? 0.35 : 0)
        state.suspicion = min(100, max(0, state.suspicion + pressure * fixedStep))
        if contacts > 0 && tick.isMultiple(of: 30) { events.append(.init(.sensorContact, "LPR scan contact")) }
        let rawTier = min(5, Int(state.suspicion / 20))
        state.suspicionTier = SuspicionTier(rawValue: rawTier) ?? .totalVisibility
        if state.suspicionTier != priorTier { events.append(.init(.tierChanged, "Suspicion escalated to tier \(rawTier)")) }
    }

    private mutating func resolveDeaths(events: inout [RunEvent]) {
        let removed = state.entities.filter { $0.health <= 0 }
        if removed.contains(where: { $0.kind == .boss }) { state.bossDefeated = true }
        state.entities.removeAll { $0.health <= 0 }
        for entity in removed {
            events.append(.init(.entityDestroyed, "Removed \(entity.kind.rawValue)"))
            if entity.kind == .cameraPole {
                state.dataShards += 1
                events.append(.init(.upgradeOffered, "LPR data shard recovered"))
            }
        }
        if state.bossDefeated && !state.extractionOpen {
            state.extractionOpen = true
            state.entities.append(Entity(id: rng.next(), kind: .extraction, position: .init(x: 300, y: 0), health: 1_000_000, radius: 60))
            events.append(.init(.extractionOpened, "Blind Spot opened"))
        }
    }
}
