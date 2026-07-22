import Foundation

public struct Simulation: Sendable {
    public private(set) var state: RunState
    private var rng: DeterministicRNG
    private var tick: UInt64 = 0
    private var eventSequence: [RecordedRunEvent] = []
    private var nextEventSequence: UInt64 = 0
    private var suspicionTimeline: [SuspicionSample] = []
    private var offeredUpgrades: [[UpgradeChoice]] = []
    private var selectedUpgrades: [UpgradeChoice] = []
    private var spawnedEntities: [EntityKind: Int] = [:]
    private var deathsByArchetype: [EntityKind: Int] = [:]
    private var damageDealt = 0.0
    private var damageTaken = 0.0
    private var bossActivatedAtTick: UInt64?
    private var bossPhaseDurations: [UInt64] = []
    private var securitySpawnOrdinal: UInt64 = 0
    private var sensorSpawnOrdinal: UInt64 = 0
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
        guard !state.runCompleted else { return [] }
        var events: [RunEvent] = []
        tick &+= 1
        state.elapsed += fixedStep
        applyUpgradeSelection(input.upgradeChoiceIndex, events: &events)
        movePlayer(input)
        updateSecurityMovement()
        updateAutomatedSurveillanceMovement()
        moveEntitiesWithinWorld()
        fireActiveWeapons(events: &events)
        resolveProjectileHits(events: &events)
        applyOngoingCountermeasures()
        applyMirrorArrays(events: &events)
        rotateCameraPoles()
        spawnCadence(events: &events)
        updateSuspicion(events: &events)
        activateShiftManagerIfNeeded(events: &events)
        resolveDeaths(events: &events)
        resolveExtraction(events: &events)
        recordReceiptState(events)
        return events
    }

    public func runReceipt() -> RunReceipt {
        RunReceipt(
            seed: state.seed,
            elapsedTicks: tick,
            elapsedSeconds: state.elapsed,
            suspicionTimeline: suspicionTimeline,
            eventSequence: eventSequence,
            offeredUpgrades: offeredUpgrades,
            selectedUpgrades: selectedUpgrades,
            spawnedEntities: spawnedEntities,
            deathsByArchetype: deathsByArchetype,
            damageDealt: damageDealt,
            damageTaken: damageTaken,
            bossPhaseDurations: bossPhaseDurations,
            extractionCompleted: state.runCompleted
        )
    }

    private mutating func recordReceiptState(_ events: [RunEvent]) {
        for event in events {
            eventSequence.append(.init(tick: tick, sequence: nextEventSequence, event: event))
            nextEventSequence &+= 1
        }
        if tick == 1 || tick.isMultiple(of: 60) || events.contains(where: { $0.kind == .tierChanged || $0.kind == .extractionCompleted }) {
            suspicionTimeline.append(.init(tick: tick, value: state.suspicion, tier: state.suspicionTier))
        }
    }

    private mutating func movePlayer(_ input: PlayerInput) {
        guard let index = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        state.entities[index].velocity = input.movement.normalized() * 210
    }

    private mutating func updateSecurityMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where [.securityGuard, .boss].contains(state.entities[index].kind) {
            let offset = player.position - state.entities[index].position
            let baseDirection = offset.normalized()
            let archetype = state.entities[index].guardArchetype
            if archetype == .supervisorOnBreak, offset.magnitude > 180 {
                state.entities[index].velocity = .init()
                continue
            }
            let direction: Vector2
            if archetype == .segwaySentinel {
                let orbit = Vector2(x: -baseDirection.y, y: baseDirection.x)
                direction = offset.magnitude > 220 ? (baseDirection + orbit * 0.35).normalized() : orbit
            } else {
                direction = baseDirection
            }
            let baseSpeed = state.entities[index].kind == .boss ? 56.0 : (archetype?.speed ?? 88)
            let radioBuff = state.entities.contains { other in
                other.id != state.entities[index].id && other.kind == .securityGuard && other.guardArchetype == .radioGuy &&
                    (other.position - state.entities[index].position).magnitude <= 180
            } ? 1.15 : 1
            let slowMultiplier = state.entities[index].processing.map { $0.untilTick > tick ? $0.slowMultiplier : 1 } ?? 1
            let disruptionMultiplier = (state.entities[index].disruptedUntilTick ?? 0) > tick ? 0.0 : 1.0
            state.entities[index].velocity = direction * (baseSpeed * radioBuff * slowMultiplier * disruptionMultiplier)
            state.entities[index].heading = atan2(direction.y, direction.x)
        }
    }

    private mutating func moveEntitiesWithinWorld() {
        for index in state.entities.indices {
            let kind = state.entities[index].kind
            guard [.player, .securityGuard, .cameraPole, .projectile, .boss].contains(kind) else { continue }
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
            switch weapon.payload {
            case let .reflect(durationTicks, _):
                deployMirrorArray(from: player, weapon: weapon, durationTicks: durationTicks, events: &events)
                continue
            case let .signalFlood(radius, durationTicks, suspicionSpike):
                triggerSignalFlood(from: player, weapon: weapon, radius: radius, durationTicks: durationTicks, suspicionSpike: suspicionSpike, events: &events)
                continue
            default:
                break
            }
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

    private mutating func deployMirrorArray(from player: Entity, weapon: WeaponSystem, durationTicks: UInt64, events: inout [RunEvent]) {
        let deployed = state.entities.filter { $0.kind == .mirrorArray }.count
        guard deployed < CombatLimits.maximumPersistentDeployables else { return }
        state.entities.append(Entity(
            id: rng.next(),
            kind: .mirrorArray,
            position: player.position,
            health: 1,
            radius: weapon.projectileRadius,
            sourceWeapon: weapon.id,
            payload: weapon.payload,
            effectExpiresAtTick: tick + durationTicks
        ))
        events.append(.init(.weaponFired, "mirrorArray deployed"))
    }

    private mutating func triggerSignalFlood(from player: Entity, weapon: WeaponSystem, radius: Double, durationTicks: UInt64, suspicionSpike: Double, events: inout [RunEvent]) {
        state.entities.removeAll { $0.kind == .signalFlood }
        state.entities.append(Entity(
            id: rng.next(),
            kind: .signalFlood,
            position: player.position,
            health: 1,
            radius: weapon.projectileRadius,
            sourceWeapon: weapon.id,
            payload: weapon.payload,
            effectExpiresAtTick: tick + 18
        ))
        state.suspicion = min(100, state.suspicion + suspicionSpike)
        var disrupted = 0
        for index in state.entities.indices where [.cameraPole, .securityGuard, .boss].contains(state.entities[index].kind) {
            guard state.entities[index].health > 0, (state.entities[index].position - player.position).magnitude <= radius else { continue }
            let existing = state.entities[index].disruptedUntilTick ?? tick
            state.entities[index].disruptedUntilTick = max(existing, tick + durationTicks)
            if state.entities[index].kind == .cameraPole {
                let disabled = state.entities[index].sensorDisabledUntilTick ?? tick
                state.entities[index].sensorDisabledUntilTick = max(disabled, tick + durationTicks)
            }
            disrupted += 1
        }
        events.append(.init(.weaponFired, "signalFlood overloaded \(disrupted) targets"))
        events.append(.init(.countermeasureHit, "Signal flood disrupted \(disrupted) targets"))
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
                damageDealt += amount
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
            if (state.entities[index].sensorDisabledUntilTick ?? 0) <= tick {
                state.entities[index].sensorDisabledUntilTick = nil
            }
            if (state.entities[index].sensorSpoof?.untilTick ?? 0) <= tick {
                state.entities[index].sensorSpoof = nil
            }
            if (state.entities[index].disruptedUntilTick ?? 0) <= tick {
                state.entities[index].disruptedUntilTick = nil
            }
            guard let processing = state.entities[index].processing else { continue }
            guard processing.untilTick > tick else {
                state.entities[index].processing = nil
                continue
            }
            state.entities[index].health -= processing.damagePerTick
        }
        state.entities.removeAll { entity in
            guard let expiry = entity.effectExpiresAtTick else { return false }
            return expiry <= tick
        }
    }

    private mutating func applyMirrorArrays(events: inout [RunEvent]) {
        guard tick.isMultiple(of: 30) else { return }
        let mirrors = state.entities.filter { $0.kind == .mirrorArray }
        for mirror in mirrors {
            guard case let .reflect(_, damageMultiplier)? = mirror.payload else { continue }
            for index in state.entities.indices where state.entities[index].kind == .cameraPole {
                guard state.entities[index].health > 0, (state.entities[index].position - mirror.position).magnitude <= 260 else { continue }
                let disabled = state.entities[index].sensorDisabledUntilTick ?? tick
                state.entities[index].sensorDisabledUntilTick = max(disabled, tick + 2)
                state.entities[index].health -= 4 * damageMultiplier
                damageDealt += 4 * damageMultiplier
                events.append(.init(.countermeasureHit, "Mirror array reflected an LPR scan"))
            }
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
        let tierMultiplier = 0.42 + Double(state.suspicionTier.rawValue) * 0.08
        for index in state.entities.indices where state.entities[index].kind == .cameraPole {
            let archetype = state.entities[index].sensorArchetype ?? .lprCameraPole
            let speed = archetype.rotationSpeed * tierMultiplier
            state.entities[index].heading = (state.entities[index].heading + speed * fixedStep).truncatingRemainder(dividingBy: .pi * 2)
        }
    }

    private mutating func updateAutomatedSurveillanceMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where state.entities[index].kind == .cameraPole {
            let archetype = state.entities[index].sensorArchetype ?? .lprCameraPole
            let offset = player.position - state.entities[index].position
            let direction: Vector2
            switch archetype {
            case .parkingLotDrone:
                let orbit = Vector2(x: -offset.y, y: offset.x).normalized()
                direction = offset.magnitude > 220 ? (offset.normalized() + orbit * 0.4).normalized() : orbit
                state.entities[index].velocity = direction * 90
            case .smartDoorbellSwarm:
                direction = offset.normalized()
                state.entities[index].velocity = direction * (offset.magnitude > 170 ? 52 : 0)
            default:
                state.entities[index].velocity = .init()
                continue
            }
            state.entities[index].heading = atan2(direction.y, direction.x)
        }
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let target = min(40, 2 + Int(state.elapsed / 5))
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        if current < target && tick.isMultiple(of: 60) {
            let angle = rng.unit() * .pi * 2
            let proposed = Vector2(x: cos(angle) * 500, y: sin(angle) * 500)
            let archetype = GuardArchetype.allCases[Int(securitySpawnOrdinal % UInt64(GuardArchetype.allCases.count))]
            securitySpawnOrdinal &+= 1
            state.entities.append(Entity(
                id: rng.next(),
                kind: .securityGuard,
                guardArchetype: archetype,
                position: state.world.bounds.clamped(proposed, margin: archetype.radius),
                health: archetype.health,
                radius: archetype.radius
            ))
            spawnedEntities[.securityGuard, default: 0] += 1
            events.append(.init(.entitySpawned, "Contract security dispatched: \(archetype.displayName)"))
        }

        let deployedSensors = state.entities.filter { $0.kind == .cameraPole && ($0.sensorArchetype ?? .lprCameraPole) != .lprCameraPole }.count
        let sensorTarget = min(SensorArchetype.allCases.count - 1, Int(tick / 1_080))
        guard deployedSensors < sensorTarget && tick.isMultiple(of: 1_080) else { return }
        let sensorCases = Array(SensorArchetype.allCases.dropFirst())
        let sensor = sensorCases[Int(sensorSpawnOrdinal % UInt64(sensorCases.count))]
        sensorSpawnOrdinal &+= 1
        let sensorAngle = rng.unit() * .pi * 2
        let sensorPosition = Vector2(x: cos(sensorAngle) * 460, y: sin(sensorAngle) * 460)
        state.entities.append(Entity(id: rng.next(), kind: .cameraPole, sensorArchetype: sensor, position: state.world.bounds.clamped(sensorPosition, margin: sensor.radius), heading: sensorAngle + .pi, health: sensor.health, radius: sensor.radius))
        spawnedEntities[.cameraPole, default: 0] += 1
        events.append(.init(.entitySpawned, "Automated surveillance deployed: \(sensor.displayName)"))
    }

    private mutating func updateSuspicion(events: inout [RunEvent]) {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let guardCount = state.entities.filter { $0.kind == .securityGuard }.count
        let contactWeight = state.entities.reduce(0.0) { partial, camera in
            guard camera.kind == .cameraPole && camera.health > 0 else { return partial }
            guard (camera.sensorDisabledUntilTick ?? 0) <= tick else { return partial }
            guard (camera.disruptedUntilTick ?? 0) <= tick else { return partial }
            let archetype = camera.sensorArchetype ?? .lprCameraPole
            let offset = player.position - camera.position
            guard offset.magnitude <= archetype.scanRange else { return partial }
            if let halfAngle = archetype.scanHalfAngle {
                guard Vector2(x: cos(camera.heading), y: sin(camera.heading)).dot(offset.normalized()) >= cos(halfAngle) else { return partial }
            }
            if archetype == .acousticGunshotDetector {
                guard state.entities.contains(where: { $0.kind == .projectile && ($0.position - camera.position).magnitude <= archetype.scanRange }) else { return partial }
            }
            let multiplier = camera.sensorSpoof.map { $0.untilTick > tick ? $0.suspicionMultiplier : 1 } ?? 1
            let patrolMultiplier = archetype == .predictivePatrolNode ? 1.35 : 1
            return partial + multiplier * patrolMultiplier
        }
        let priorTier = state.suspicionTier
        let pressure = Double(guardCount) * 0.12 + contactWeight * 6.0 - (contactWeight == 0 ? 0.35 : 0)
        state.suspicion = min(100, max(0, state.suspicion + pressure * fixedStep))
        if contactWeight > 0 && tick.isMultiple(of: 30) { events.append(.init(.sensorContact, "LPR scan contact")) }
        let rawTier = state.suspicion >= 95 ? 5 : min(4, Int(state.suspicion / 20))
        state.suspicionTier = SuspicionTier(rawValue: rawTier) ?? .totalVisibility
        if state.suspicionTier != priorTier { events.append(.init(.tierChanged, "Suspicion escalated to tier \(rawTier)")) }
    }

    private mutating func activateShiftManagerIfNeeded(events: inout [RunEvent]) {
        guard state.suspicionTier == .totalVisibility, !state.bossDefeated else { return }
        guard !state.entities.contains(where: { $0.kind == .boss && $0.health > 0 }) else { return }
        state.entities.append(Entity(
            id: rng.next(),
            kind: .boss,
            position: state.world.bounds.clamped(.init(x: 420, y: 0), margin: 42),
            health: 450,
            radius: 42
        ))
        spawnedEntities[.boss, default: 0] += 1
        bossActivatedAtTick = tick
        events.append(.init(.bossActivated, "The Shift Manager activated"))
    }

    private mutating func resolveDeaths(events: inout [RunEvent]) {
        let removed = state.entities.filter { $0.health <= 0 }
        if removed.contains(where: { $0.kind == .boss }) {
            state.bossDefeated = true
            if let bossActivatedAtTick { bossPhaseDurations.append(tick - bossActivatedAtTick) }
        }
        state.entities.removeAll { $0.health <= 0 }
        for entity in removed {
            deathsByArchetype[entity.kind, default: 0] += 1
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

    private mutating func resolveExtraction(events: inout [RunEvent]) {
        guard state.extractionOpen, !state.runCompleted else { return }
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        guard let extraction = state.entities.first(where: { $0.kind == .extraction }) else { return }
        guard (player.position - extraction.position).magnitude <= player.radius + extraction.radius else { return }
        state.runCompleted = true
        events.append(.init(.extractionCompleted, "Extracted through Blind Spot"))
    }

    private mutating func offerUpgrades(events: inout [RunEvent]) {
        guard state.pendingUpgradeChoices.isEmpty else { return }
        let choices = UpgradeChoice.allCases.filter(isUpgradeEligible)
        let offset = Int(rng.next() % UInt64(choices.count))
        state.pendingUpgradeChoices = (0..<3).map { choices[($0 + offset) % choices.count] }
        offeredUpgrades.append(state.pendingUpgradeChoices)
        events.append(.init(.upgradeOffered, "LPR data shard recovered"))
    }

    private func isUpgradeEligible(_ choice: UpgradeChoice) -> Bool {
        func owns(_ weapon: WeaponID) -> Bool { state.activeWeapons.contains { $0.id == weapon } }
        func canAdd(_ weapon: WeaponID) -> Bool { owns(weapon) || state.activeWeapons.count < CombatLimits.maximumActiveWeapons }
        func canEvolve(_ weapon: WeaponID, _ evolution: WeaponEvolution) -> Bool {
            guard !state.evolutions.contains(evolution) else { return false }
            return state.activeWeapons.contains { $0.id == weapon && $0.level >= 3 }
        }
        return switch choice {
        case .redactionOrdinance: canAdd(.redactionOrdinance)
        case .identityTransponder: canAdd(.identityTransponder)
        case .foiaSwarm: canAdd(.foiaSwarm)
        case .mirrorArray: canAdd(.mirrorArray)
        case .signalFlood: canAdd(.signalFlood)
        case .precisionDart: owns(.kineticCountermeasure)
        case .blackBarMandate: owns(.redactionOrdinance)
        case .ghostPlateCache: owns(.identityTransponder)
        case .expeditedDiscovery: owns(.foiaSwarm)
        case .indictmentProtocol: canEvolve(.kineticCountermeasure, .indictmentProtocol)
        case .blackoutField: canEvolve(.redactionOrdinance, .blackoutField)
        case .ghostProtocol: canEvolve(.identityTransponder, .ghostProtocol)
        case .paperStorm: canEvolve(.foiaSwarm, .paperStorm)
        case .rapidCountermeasure, .reinforcedSignal, .lowProfileRouting: true
        }
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
        case .precisionDart:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .kineticCountermeasure }) else { return }
            if case let .damage(amount) = state.activeWeapons[index].payload { state.activeWeapons[index].payload = .damage(amount + 8) }
            state.activeWeapons[index].projectileSpeed += 90
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
        case .blackBarMandate:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .redactionOrdinance }) else { return }
            if case let .disableCameraSensors(durationTicks) = state.activeWeapons[index].payload {
                state.activeWeapons[index].payload = .disableCameraSensors(durationTicks: durationTicks + 90)
            }
            state.activeWeapons[index].level += 1
        case .identityTransponder:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .identityTransponder }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(45, state.activeWeapons[index].cadenceTicks - 12)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.identityTransponder)
            } else {
                return
            }
        case .ghostPlateCache:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .identityTransponder }) else { return }
            if case let .spoofCameraSensors(durationTicks, suspicionMultiplier) = state.activeWeapons[index].payload {
                state.activeWeapons[index].payload = .spoofCameraSensors(durationTicks: durationTicks + 120, suspicionMultiplier: max(0.1, suspicionMultiplier - 0.1))
            }
            state.activeWeapons[index].level += 1
        case .foiaSwarm:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .foiaSwarm }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(30, state.activeWeapons[index].cadenceTicks - 8)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.foiaSwarm)
            } else {
                return
            }
        case .expeditedDiscovery:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .foiaSwarm }) else { return }
            if case let .processing(durationTicks, slowMultiplier, damagePerTick) = state.activeWeapons[index].payload {
                state.activeWeapons[index].payload = .processing(durationTicks: durationTicks + 60, slowMultiplier: max(0.2, slowMultiplier - 0.1), damagePerTick: damagePerTick + 0.08)
            }
            state.activeWeapons[index].level += 1
        case .mirrorArray:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .mirrorArray }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(90, state.activeWeapons[index].cadenceTicks - 20)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.mirrorArray)
            } else {
                return
            }
        case .signalFlood:
            if let index = state.activeWeapons.firstIndex(where: { $0.id == .signalFlood }) {
                state.activeWeapons[index].level += 1
                state.activeWeapons[index].cadenceTicks = max(150, state.activeWeapons[index].cadenceTicks - 30)
            } else if state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                state.activeWeapons.append(.signalFlood)
            } else {
                return
            }
        case .indictmentProtocol:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .kineticCountermeasure }), state.activeWeapons[index].level >= 3 else { return }
            if case let .damage(amount) = state.activeWeapons[index].payload { state.activeWeapons[index].payload = .damage(amount + 18) }
            state.activeWeapons[index].cadenceTicks = max(5, state.activeWeapons[index].cadenceTicks - 4)
            state.activeWeapons[index].level += 1
            state.evolutions.insert(.indictmentProtocol)
        case .blackoutField:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .redactionOrdinance }), state.activeWeapons[index].level >= 3 else { return }
            if case let .disableCameraSensors(durationTicks) = state.activeWeapons[index].payload {
                state.activeWeapons[index].payload = .disableCameraSensors(durationTicks: durationTicks + 240)
            }
            state.activeWeapons[index].projectileRadius += 8
            state.activeWeapons[index].level += 1
            state.evolutions.insert(.blackoutField)
        case .ghostProtocol:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .identityTransponder }), state.activeWeapons[index].level >= 3 else { return }
            if case let .spoofCameraSensors(durationTicks, _) = state.activeWeapons[index].payload {
                state.activeWeapons[index].payload = .spoofCameraSensors(durationTicks: durationTicks + 240, suspicionMultiplier: 0.05)
            }
            state.activeWeapons[index].level += 1
            state.evolutions.insert(.ghostProtocol)
        case .paperStorm:
            guard let index = state.activeWeapons.firstIndex(where: { $0.id == .foiaSwarm }), state.activeWeapons[index].level >= 3 else { return }
            if case let .processing(durationTicks, _, damagePerTick) = state.activeWeapons[index].payload {
                state.activeWeapons[index].payload = .processing(durationTicks: durationTicks + 180, slowMultiplier: 0.25, damagePerTick: damagePerTick + 0.23)
            }
            state.activeWeapons[index].level += 1
            state.evolutions.insert(.paperStorm)
        }
        state.pendingUpgradeChoices = []
        selectedUpgrades.append(choice)
        events.append(.init(.upgradeSelected, "Applied \(choice.rawValue)"))
    }
}
