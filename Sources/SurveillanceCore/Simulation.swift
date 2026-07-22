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
        resolveThreatContact(events: &events)
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
            extractionCompleted: state.runCompleted && !state.playerDefeated
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
        state.entities[index].velocity = input.movement.normalized() * BossCatalog.bundled.playerSpeed
    }

    private mutating func updateSecurityMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where [.securityGuard, .boss].contains(state.entities[index].kind) {
            let offset = player.position - state.entities[index].position
            let baseDirection = offset.normalized()
            let archetype = state.entities[index].guardArchetype
            if archetype?.definition.movementStyle == .dormantUntilNearby, offset.magnitude > (archetype?.definition.activationRange ?? 0) {
                state.entities[index].velocity = .init()
                continue
            }
            let direction: Vector2
            if archetype?.definition.movementStyle == .orbit {
                let orbit = Vector2(x: -baseDirection.y, y: baseDirection.x)
                direction = offset.magnitude > 220 ? (baseDirection + orbit * 0.35).normalized() : orbit
            } else {
                direction = baseDirection
            }
            let baseSpeed = state.entities[index].kind == .boss ? BossCatalog.bundled.shiftManagerSpeed : (archetype?.speed ?? 88)
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

    private mutating func resolveThreatContact(events: inout [RunEvent]) {
        guard let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        let player = state.entities[playerIndex]
        guard player.health > 0 else { return }

        var damageThisTick = 0.0
        for threat in state.entities where [.securityGuard, .boss].contains(threat.kind) && threat.health > 0 {
            guard (threat.disruptedUntilTick ?? 0) <= tick else { continue }
            guard (threat.position - player.position).magnitude <= threat.radius + player.radius else { continue }
            let damagePerSecond: Double
            if threat.kind == .boss {
                damagePerSecond = BossCatalog.bundled.shiftManagerContactDamagePerSecond
            } else {
                damagePerSecond = threat.guardArchetype?.contactDamagePerSecond ?? 8
            }
            damageThisTick += damagePerSecond * fixedStep
        }

        guard damageThisTick > 0 else { return }
        state.entities[playerIndex].health = max(0, player.health - damageThisTick)
        damageTaken += damageThisTick
        if tick.isMultiple(of: 15) {
            events.append(.init(.playerDamaged, String(format: "Player took %.1f contact damage", damageThisTick)))
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
        let suspicion = SuspicionCatalog.bundled
        let tierMultiplier = suspicion.cameraRotationBaseMultiplier + Double(state.suspicionTier.rawValue) * suspicion.cameraRotationTierIncrement
        for index in state.entities.indices where state.entities[index].kind == .cameraPole {
            guard isSensorActive(state.entities[index]) else { continue }
            let archetype = state.entities[index].sensorArchetype ?? .lprCameraPole
            let speed = archetype.rotationSpeed * tierMultiplier
            state.entities[index].heading = (state.entities[index].heading + speed * fixedStep).truncatingRemainder(dividingBy: .pi * 2)
        }
    }

    private mutating func updateAutomatedSurveillanceMovement() {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        for index in state.entities.indices where state.entities[index].kind == .cameraPole {
            guard isSensorActive(state.entities[index]) else {
                state.entities[index].velocity = .init()
                continue
            }
            let archetype = state.entities[index].sensorArchetype ?? .lprCameraPole
            let offset = player.position - state.entities[index].position
            let direction: Vector2
            switch archetype.definition.movementStyle {
            case .orbit:
                let orbit = Vector2(x: -offset.y, y: offset.x).normalized()
                direction = offset.magnitude > 220 ? (offset.normalized() + orbit * 0.4).normalized() : orbit
                state.entities[index].velocity = direction * 90
            case .chase:
                direction = offset.normalized()
                state.entities[index].velocity = direction * (offset.magnitude > 170 ? 52 : 0)
            case .stationary:
                state.entities[index].velocity = .init()
                continue
            }
            state.entities[index].heading = atan2(direction.y, direction.x)
        }
    }

    private func isSensorActive(_ entity: Entity) -> Bool {
        (entity.sensorDisabledUntilTick ?? 0) <= tick && (entity.disruptedUntilTick ?? 0) <= tick
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let waves = WaveCatalog.bundled
        let target = min(waves.guardMaximumTarget, waves.guardInitialTarget + Int(state.elapsed / waves.guardGrowthIntervalSeconds))
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        if current < target && tick.isMultiple(of: waves.guardSpawnIntervalTicks) {
            let angle = rng.unit() * .pi * 2
            let proposed = Vector2(x: cos(angle) * waves.guardSpawnRadius, y: sin(angle) * waves.guardSpawnRadius)
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
        let sensorTarget = min(SensorArchetype.allCases.count - 1, Int(tick / waves.sensorSpawnIntervalTicks))
        guard deployedSensors < sensorTarget && tick.isMultiple(of: waves.sensorSpawnIntervalTicks) else { return }
        let sensorCases = Array(SensorArchetype.allCases.dropFirst())
        let sensor = sensorCases[Int(sensorSpawnOrdinal % UInt64(sensorCases.count))]
        sensorSpawnOrdinal &+= 1
        let sensorAngle = rng.unit() * .pi * 2
        let sensorPosition = Vector2(x: cos(sensorAngle) * waves.sensorSpawnRadius, y: sin(sensorAngle) * waves.sensorSpawnRadius)
        state.entities.append(Entity(id: rng.next(), kind: .cameraPole, sensorArchetype: sensor, position: state.world.bounds.clamped(sensorPosition, margin: sensor.radius), heading: sensorAngle + .pi, health: sensor.health, radius: sensor.radius))
        spawnedEntities[.cameraPole, default: 0] += 1
        events.append(.init(.entitySpawned, "Automated surveillance deployed: \(sensor.displayName)"))
    }

    private mutating func updateSuspicion(events: inout [RunEvent]) {
        let tuning = SuspicionCatalog.bundled
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let guardCount = state.entities.filter { $0.kind == .securityGuard }.count
        let contactWeight = state.entities.reduce(0.0) { partial, camera in
            guard camera.kind == .cameraPole && camera.health > 0 else { return partial }
            guard isSensorActive(camera) else { return partial }
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
            let patrolMultiplier = archetype == .predictivePatrolNode ? tuning.predictivePatrolPressureMultiplier : 1
            return partial + multiplier * patrolMultiplier
        }
        let priorTier = state.suspicionTier
        let pressure = Double(guardCount) * tuning.guardPressurePerSecond + contactWeight * tuning.sensorContactPressurePerSecond - (contactWeight == 0 ? tuning.noContactRecoveryPerSecond : 0)
        state.suspicion = min(100, max(0, state.suspicion + pressure * fixedStep))
        if contactWeight > 0 && tick.isMultiple(of: tuning.sensorContactEventIntervalTicks) { events.append(.init(.sensorContact, "LPR scan contact")) }
        state.suspicionTier = tuning.tier(for: state.suspicion)
        if state.suspicionTier != priorTier { events.append(.init(.tierChanged, "Suspicion escalated to tier \(state.suspicionTier.rawValue)")) }
    }

    private mutating func activateShiftManagerIfNeeded(events: inout [RunEvent]) {
        let boss = BossCatalog.bundled
        guard state.suspicionTier == .totalVisibility, !state.bossDefeated else { return }
        guard !state.entities.contains(where: { $0.kind == .boss && $0.health > 0 }) else { return }
        state.entities.append(Entity(
            id: rng.next(),
            kind: .boss,
            position: state.world.bounds.clamped(.init(x: boss.shiftManagerSpawnX, y: 0), margin: boss.shiftManagerRadius),
            health: boss.shiftManagerHealth,
            radius: boss.shiftManagerRadius
        ))
        spawnedEntities[.boss, default: 0] += 1
        bossActivatedAtTick = tick
        events.append(.init(.bossActivated, "The Shift Manager activated"))
    }

    private mutating func resolveDeaths(events: inout [RunEvent]) {
        let removed = state.entities.filter { $0.health <= 0 }
        if removed.contains(where: { $0.kind == .player }) {
            state.playerDefeated = true
            state.runCompleted = true
            events.append(.init(.playerDefeated, "The grid reacquired the Ghost"))
        }
        if removed.contains(where: { $0.kind == .boss }) {
            state.bossDefeated = true
            if let bossActivatedAtTick { bossPhaseDurations.append(tick - bossActivatedAtTick) }
        }
        // Keep a defeated player entity for receipt/HUD projection, but remove other wreckage.
        state.entities.removeAll { $0.health <= 0 && $0.kind != .player }
        for entity in removed where entity.kind != .player {
            deathsByArchetype[entity.kind, default: 0] += 1
            events.append(.init(.entityDestroyed, "Removed \(entity.kind.rawValue)"))
            if entity.kind == .cameraPole {
                state.dataShards += 1
                offerUpgrades(events: &events)
            }
        }
        if removed.contains(where: { $0.kind == .player }) {
            deathsByArchetype[.player, default: 0] += 1
        }
        if state.bossDefeated && !state.extractionOpen && !state.playerDefeated {
            let boss = BossCatalog.bundled
            state.extractionOpen = true
            state.entities.append(Entity(id: rng.next(), kind: .extraction, position: .init(x: boss.blindSpotPositionX, y: 0), health: boss.blindSpotHealth, radius: boss.blindSpotRadius))
            events.append(.init(.extractionOpened, "Blind Spot opened"))
        }
    }

    private mutating func resolveExtraction(events: inout [RunEvent]) {
        guard state.extractionOpen, !state.runCompleted, !state.playerDefeated else { return }
        guard let player = state.entities.first(where: { $0.kind == .player }), player.health > 0 else { return }
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
        let definition = UpgradeCatalog.bundled.upgrade(choice)
        guard let weapon = definition.weapon else { return true }
        if let evolution = definition.evolution {
            return !state.evolutions.contains(evolution)
                && state.activeWeapons.contains { $0.id == weapon && $0.level >= definition.minimumWeaponLevel! }
        }
        if definition.addsWeapon {
            return state.activeWeapons.contains { $0.id == weapon } || state.activeWeapons.count < CombatLimits.maximumActiveWeapons
        }
        return state.activeWeapons.contains { $0.id == weapon }
    }

    private mutating func applyUpgradeSelection(_ index: Int?, events: inout [RunEvent]) {
        guard let index, state.pendingUpgradeChoices.indices.contains(index) else { return }
        let choice = state.pendingUpgradeChoices[index]
        let definition = UpgradeCatalog.bundled.upgrade(choice)
        if let suspicionReduction = definition.effect.suspicionReduction {
            state.suspicion = max(0, state.suspicion - suspicionReduction)
        }
        if let weapon = definition.weapon {
            if state.activeWeapons.firstIndex(where: { $0.id == weapon }) == nil {
                guard definition.addsWeapon, state.activeWeapons.count < CombatLimits.maximumActiveWeapons else { return }
                state.activeWeapons.append(ContentCatalog.bundled.weapon(weapon).weaponSystem())
            } else {
                guard let weaponIndex = state.activeWeapons.firstIndex(where: { $0.id == weapon }) else { return }
                apply(definition.effect, to: &state.activeWeapons[weaponIndex])
                state.activeWeapons[weaponIndex].level += 1
            }
        }
        if let evolution = definition.evolution { state.evolutions.insert(evolution) }
        state.pendingUpgradeChoices = []
        selectedUpgrades.append(choice)
        events.append(.init(.upgradeSelected, "Applied \(choice.rawValue)"))
    }

    private func apply(_ effect: UpgradeEffect, to weapon: inout WeaponSystem) {
        if let cadenceReduction = effect.cadenceReduction {
            weapon.cadenceTicks = max(effect.minimumCadence ?? 1, weapon.cadenceTicks - cadenceReduction)
        }
        weapon.projectileSpeed += effect.projectileSpeedIncrease ?? 0
        weapon.projectileRadius += effect.projectileRadiusIncrease ?? 0
        switch weapon.payload {
        case let .damage(amount):
            weapon.payload = .damage(amount + (effect.damageIncrease ?? 0))
        case let .disableCameraSensors(durationTicks):
            weapon.payload = .disableCameraSensors(durationTicks: durationTicks + (effect.disableDurationIncrease ?? 0))
        case let .spoofCameraSensors(durationTicks, suspicionMultiplier):
            let adjustedMultiplier = effect.suspicionMultiplierSet ?? max(effect.minimumSuspicionMultiplier ?? 0, suspicionMultiplier - (effect.suspicionMultiplierReduction ?? 0))
            weapon.payload = .spoofCameraSensors(durationTicks: durationTicks + (effect.spoofDurationIncrease ?? 0), suspicionMultiplier: adjustedMultiplier)
        case let .processing(durationTicks, slowMultiplier, damagePerTick):
            let adjustedSlowMultiplier = effect.slowMultiplierSet ?? max(effect.minimumSlowMultiplier ?? 0, slowMultiplier - (effect.slowMultiplierReduction ?? 0))
            weapon.payload = .processing(durationTicks: durationTicks + (effect.processingDurationIncrease ?? 0), slowMultiplier: adjustedSlowMultiplier, damagePerTick: damagePerTick + (effect.processingDamageIncrease ?? 0))
        case .reflect, .signalFlood:
            break
        }
    }
}
