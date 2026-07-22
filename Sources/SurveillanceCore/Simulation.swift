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

    init(state: RunState, rngSeed: UInt64, fixedStep: Double = 1.0 / 60.0) {
        self.state = state
        rng = DeterministicRNG(seed: rngSeed)
        self.fixedStep = fixedStep
    }

    public mutating func step(input: PlayerInput) -> [RunEvent] {
        var events: [RunEvent] = []
        tick &+= 1
        state.elapsed += fixedStep
        applyUpgradeSelection(input.upgradeChoiceIndex, events: &events)
        movePlayer(input)
        updateSecurityMovement()
        moveEntitiesWithinWorld()
        fireActiveWeapons(events: &events)
        resolveProjectileHits(events: &events)
        applyOngoingCountermeasures()
        rotateCameraPoles()
        spawnCadence(events: &events)
        updateSuspicion(events: &events)
        resolveDeaths(events: &events)
        return events
    }

    private mutating func movePlayer(_ input: PlayerInput) {
        guard let index = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        state.entities[index].velocity = input.movement.normalized() * 210
    }

    private mutating func updateSecurityMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where state.entities[index].kind == .securityGuard {
            let direction = (player.position - state.entities[index].position).normalized()
            let slowMultiplier = state.entities[index].processing.map { $0.untilTick > tick ? $0.slowMultiplier : 1 } ?? 1
            state.entities[index].velocity = direction * (88 * slowMultiplier)
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
            case let .some(.damage(amount)):
                state.entities[targetIndex].health -= amount
                events.append(.init(.countermeasureHit, "Dealt \(amount) damage to \(state.entities[targetIndex].kind.rawValue)"))
            case let .some(.disableCameraSensors(durationTicks)) where state.entities[targetIndex].kind == .cameraPole:
                let existing = state.entities[targetIndex].sensorDisabledUntilTick ?? tick
                state.entities[targetIndex].sensorDisabledUntilTick = max(existing, tick + durationTicks)
                events.append(.init(.countermeasureHit, "Redacted camera sensors for \(durationTicks) ticks"))
            case let .some(.spoofCameraSensors(durationTicks, suspicionMultiplier)) where state.entities[targetIndex].kind == .cameraPole:
                let untilTick = max(state.entities[targetIndex].sensorSpoof?.untilTick ?? tick, tick + durationTicks)
                state.entities[targetIndex].sensorSpoof = .init(untilTick: untilTick, suspicionMultiplier: suspicionMultiplier)
                events.append(.init(.countermeasureHit, "Spoofed camera identity for \(durationTicks) ticks"))
            case let .some(.processing(durationTicks, slowMultiplier, damagePerTick)) where [.securityGuard, .boss].contains(state.entities[targetIndex].kind):
                let untilTick = max(state.entities[targetIndex].processing?.untilTick ?? tick, tick + durationTicks)
                state.entities[targetIndex].processing = .init(untilTick: untilTick, slowMultiplier: slowMultiplier, damagePerTick: damagePerTick)
                events.append(.init(.countermeasureHit, "Applied FOIA processing for \(durationTicks) ticks"))
            default:
                break
            }
            state.entities[projectileIndex].health = 0
        }
    }

    private mutating func applyOngoingCountermeasures() {
        for index in state.entities.indices {
            guard let processing = state.entities[index].processing, processing.untilTick > tick else { continue }
            state.entities[index].health -= processing.damagePerTick
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
        let guardCount = state.entities.filter { $0.kind == .securityGuard }.count
        let contactWeight = state.entities.reduce(0.0) { partial, camera in
            guard camera.kind == .cameraPole && camera.health > 0 else { return partial }
            guard (camera.sensorDisabledUntilTick ?? 0) <= tick else { return partial }
            let offset = player.position - camera.position
            guard offset.magnitude <= 430 else { return partial }
            guard Vector2(x: cos(camera.heading), y: sin(camera.heading)).dot(offset.normalized()) >= cos(.pi / 7) else { return partial }
            let multiplier = camera.sensorSpoof.map { $0.untilTick > tick ? $0.suspicionMultiplier : 1 } ?? 1
            return partial + multiplier
        }
        let priorTier = state.suspicionTier
        let pressure = Double(guardCount) * 0.12 + contactWeight * 6.0 - (contactWeight == 0 ? 0.35 : 0)
        state.suspicion = min(100, max(0, state.suspicion + pressure * fixedStep))
        if contactWeight > 0 && tick.isMultiple(of: 30) { events.append(.init(.sensorContact, "LPR scan contact")) }
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
                offerUpgrades(events: &events)
            }
        }
        if state.bossDefeated && !state.extractionOpen {
            state.extractionOpen = true
            state.entities.append(Entity(id: rng.next(), kind: .extraction, position: .init(x: 300, y: 0), health: 1_000_000, radius: 60))
            events.append(.init(.extractionOpened, "Blind Spot opened"))
        }
    }

    private mutating func offerUpgrades(events: inout [RunEvent]) {
        guard state.pendingUpgradeChoices.isEmpty else { return }
        let choices = UpgradeChoice.allCases.filter { choice in
            switch choice {
            case .redactionOrdinance:
                return state.activeWeapons.contains(where: { $0.id == .redactionOrdinance }) ||
                    state.activeWeapons.count < CombatLimits.maximumActiveWeapons
            case .identityTransponder:
                return state.activeWeapons.contains(where: { $0.id == .identityTransponder }) ||
                    state.activeWeapons.count < CombatLimits.maximumActiveWeapons
            case .foiaSwarm:
                return state.activeWeapons.contains(where: { $0.id == .foiaSwarm }) ||
                    state.activeWeapons.count < CombatLimits.maximumActiveWeapons
            default:
                return true
            }
        }
        let offset = Int(rng.next() % UInt64(choices.count))
        state.pendingUpgradeChoices = (0..<3).map { choices[($0 + offset) % choices.count] }
        events.append(.init(.upgradeOffered, "LPR data shard recovered"))
    }

    private mutating func applyUpgradeSelection(_ index: Int?, events: inout [RunEvent]) {
        guard let index, state.pendingUpgradeChoices.indices.contains(index) else { return }
        let choice = state.pendingUpgradeChoices[index]
        switch choice {
        case .rapidCountermeasure:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .kineticCountermeasure }) else { return }
            state.activeWeapons[index].cadenceTicks = max(5, state.activeWeapons[index].cadenceTicks - 3)
            state.activeWeapons[index].level += 1
        case .reinforcedSignal:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .kineticCountermeasure }) else { return }
            if case let .damage(amount) = state.activeWeapons[index].payload { state.activeWeapons[index].payload = .damage(amount + 5) }
            state.activeWeapons[index].level += 1
        case .lowProfileRouting:
            state.suspicion = max(0, state.suspicion - 10)
        case .redactionOrdinance:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .redactionOrdinance }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(30, state.activeWeapons[index].cadenceTicks - 10)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.redactionOrdinance)
            } else {
                return
            }
        case .identityTransponder:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .identityTransponder }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(45, state.activeWeapons[index].cadenceTicks - 12)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.identityTransponder)
            } else {
                return
            }
        case .foiaSwarm:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .foiaSwarm }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(30, state.activeWeapons[index].cadenceTicks - 8)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.foiaSwarm)
            } else {
                return
            }
        }
        state.pendingUpgradeChoices = []
        events.append(.init(.upgradeSelected, "Applied \(choice.rawValue)"))
    }
}
