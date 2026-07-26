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
    private var directorDecisions: [DirectorDecisionSample] = []
    private var cityStateEvents: [CityStateEventSample] = []
    private var buildSynergyActivations: [BuildSynergyActivationSample] = []
    private var coordinationEvents: [CoordinationEventSample] = []
    private var interactableActivations: [InteractableActivationSample] = []
    private var landmarkEvents: [LandmarkEventSample] = []
    private var upgradeOfferBiasEvents: [UpgradeOfferBiasSample] = []
    /// Pre-move projectile positions for continuous collision this step only.
    /// Newly fired projectiles are absent → degenerate segment at spawn (no reverse phantom).
    private var projectileOriginsThisStep: [UInt64: Vector2] = [:]
    /// Optional P11 challenge context (daily/weekly). Mutators are explicit levers only.
    private let challenge: ChallengeInstance?
    /// Authored rules for the district this run takes place in. Districts never
    /// change mid-run, so the profile is resolved once at construction.
    private let profile: DistrictSimulationProfile
    public let fixedStep: Double

    public init(
        seed: UInt64,
        district: DistrictID = .campaignOpener,
        fixedStep: Double = 1.0 / 60.0,
        challenge: ChallengeInstance? = nil
    ) {
        // Challenge instance owns district/seed when provided.
        let resolvedDistrict = challenge?.districtId ?? district
        let resolvedSeed = challenge?.seed ?? seed
        state = RunState(seed: resolvedSeed, district: resolvedDistrict)
        rng = DeterministicRNG(seed: resolvedSeed)
        profile = resolvedDistrict.profile
        self.fixedStep = fixedStep
        self.challenge = challenge
    }

    /// Install a prepared authoritative state (tests / host-driven smokes).
    public init(
        state: RunState,
        rngSeed: UInt64,
        fixedStep: Double = 1.0 / 60.0,
        challenge: ChallengeInstance? = nil
    ) {
        self.state = state
        rng = DeterministicRNG(seed: rngSeed)
        profile = state.district.profile
        self.fixedStep = fixedStep
        self.challenge = challenge
    }

    public mutating func step(input: PlayerInput) -> [RunEvent] {
        guard !state.runCompleted else { return [] }
        var events: [RunEvent] = []
        tick &+= 1
        state.elapsed += fixedStep
        projectileOriginsThisStep = [:]
        applyUpgradeSelection(input.upgradeChoiceIndex, events: &events)
        movePlayer(input)
        evaluateInteractables(input: input, events: &events)
        updateSecurityMovement()
        updateAutomatedSurveillanceMovement()
        moveEntitiesWithinWorld()
        evaluateLandmarkEncounter(events: &events)
        // Honors PlayerInput.autoFireEnabled so -UITesting / deliberate suppression
        // cannot AFK-kill sensors into upgrade drafts that cover launch chrome.
        if input.autoFireEnabled {
            fireActiveWeapons(events: &events)
        }
        resolveProjectileHits(events: &events)
        projectileOriginsThisStep = [:]
        applyOngoingCountermeasures()
        applyMirrorArrays(events: &events)
        resolveThreatContact(events: &events)
        // Lethal contact must end the run before suspicion/director/spawn still mutate it.
        if (state.entities.first(where: { $0.kind == .player })?.health ?? 0) <= 0 {
            resolveDeaths(events: &events)
            activateShiftManagerIfNeeded(events: &events)
            resolveExtraction(events: &events)
            recordReceiptState(events)
            return events
        }
        rotateCameraPoles()
        updateSuspicion(events: &events)
        applyLandmarkSuspicionFloor()
        evaluateCoordinationGraph(events: &events)
        evaluateSuspicionDirector(events: &events)
        spawnCadence(events: &events)
        // Resolve deaths before boss activation so a boss that dies this tick cannot be
        // replaced in the same step (which would leave a live boss after extraction opens).
        resolveDeaths(events: &events)
        activateShiftManagerIfNeeded(events: &events)
        resolveExtraction(events: &events)
        recordReceiptState(events)
        return events
    }

    public func runReceipt() -> RunReceipt {
        RunReceipt(
            seed: state.seed,
            district: state.district,
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
            extractionCompleted: state.runCompleted && !state.playerDefeated,
            directorDecisions: directorDecisions,
            cityStateEvents: cityStateEvents,
            districtState: state.districtState,
            buildSynergyActivations: buildSynergyActivations,
            buildEngine: state.buildEngine,
            coordinationEvents: coordinationEvents,
            coordination: state.coordination,
            interactableActivations: interactableActivations,
            landmarkEvents: landmarkEvents,
            landmarkEncounter: state.landmarkEncounter,
            upgradeOfferBiasEvents: upgradeOfferBiasEvents,
            challenge: challenge
        )
    }

    /// P9 landmark set piece — pressure levers only (spawn / observation / suspicion nudge).
    private mutating func evaluateLandmarkEncounter(events: inout [RunEvent]) {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let result = LandmarkEncounterEngine.evaluate(
            district: state.district,
            playerPosition: player.position,
            elapsed: state.elapsed,
            tick: tick,
            fixedStep: fixedStep,
            state: state.landmarkEncounter
        )
        state.landmarkEncounter = result.state
        for sample in result.events {
            landmarkEvents.append(sample)
            events.append(
                .init(
                    .landmarkEncounterChanged,
                    "Landmark: \(sample.kind) — \(sample.reason)"
                )
            )
        }
        if result.suspicionNudgePerSecond > 0 {
            state.suspicion = min(100, max(0, state.suspicion + result.suspicionNudgePerSecond * fixedStep))
        }
    }

    /// Authored landmark boss hook: while inside, suspicion may not sit below this tier.
    /// Applied after `updateSuspicion` so recovery cannot cancel the floor the same tick.
    private mutating func applyLandmarkSuspicionFloor() {
        guard state.landmarkEncounter.isPlayerInside else { return }
        guard let encounter = LandmarkEncounterCatalog.bundled.primary(for: state.district) else { return }
        let minimumTierRaw = encounter.bossHooks.minimumTierRaw
        guard minimumTierRaw > 0 else { return }
        let thresholds = SuspicionCatalog.bundled.tierThresholds
        let index = minimumTierRaw - 1
        guard thresholds.indices.contains(index) else { return }
        state.suspicion = max(state.suspicion, thresholds[index])
        state.suspicionTier = SuspicionCatalog.bundled.tier(for: state.suspicion)
    }

    /// P9 environmental interactables — utility activation stresses linked infrastructure.
    private mutating func evaluateInteractables(input: PlayerInput, events: inout [RunEvent]) {
        guard let player = state.entities.first(where: { $0.kind == .player }) else { return }
        let result = InteractableEngine.tryActivate(
            district: state.district,
            playerPosition: player.position,
            elapsed: state.elapsed,
            tick: tick,
            utilityPressed: input.activateUtility,
            states: state.interactables,
            districtState: state.districtState
        )
        state.interactables = result.states
        state.districtState = result.districtState
        for sample in result.samples {
            interactableActivations.append(sample)
            events.append(
                .init(
                    .interactableActivated,
                    "Interactable: \(sample.label) → \(sample.opportunity)/\(sample.cost)"
                )
            )
        }
        for sample in result.cityStateEvents {
            cityStateEvents.append(sample)
            events.append(
                .init(
                    .cityStateChanged,
                    "City state: \(sample.nodeId) → \(sample.status.rawValue) (\(sample.reason))"
                )
            )
        }
    }

    private mutating func recordReceiptState(_ events: [RunEvent]) {
        for event in events {
            eventSequence.append(.init(tick: tick, sequence: nextEventSequence, event: event))
            nextEventSequence &+= 1
        }
        if tick == 1 || tick.isMultiple(of: 60) || events.contains(where: { $0.kind == .tierChanged || $0.kind == .extractionCompleted || $0.kind == .directorDecision }) {
            suspicionTimeline.append(.init(tick: tick, value: state.suspicion, tier: state.suspicionTier))
        }
    }

    /// Coordination graph: interruptible capture cascade with explicit encounter levers only.
    private mutating func evaluateCoordinationGraph(events: inout [RunEvent]) {
        let catalog = CoordinationCatalog.bundled
        guard catalog.forbidHiddenStatScaling else { return }

        // Start / advance on sensor contact signals emitted this tick.
        if events.contains(where: { $0.kind == .sensorContact }) {
            if state.coordination.chainId == nil {
                ingestCoordination(
                    CoordinationEngine.startIfNeeded(
                        catalog: catalog,
                        state: state.coordination,
                        district: state.district,
                        elapsed: state.elapsed,
                        tick: tick,
                        signal: "sensorContact"
                    ),
                    events: &events
                )
            } else {
                ingestCoordination(
                    CoordinationEngine.handleSignal(
                        catalog: catalog,
                        state: state.coordination,
                        elapsed: state.elapsed,
                        tick: tick,
                        signal: "sensorContact"
                    ),
                    events: &events
                )
            }
        }

        guard tick.isMultiple(of: catalog.evaluationIntervalTicks) else { return }
        ingestCoordination(
            CoordinationEngine.tickTimers(
                catalog: catalog,
                state: state.coordination,
                elapsed: state.elapsed,
                tick: tick
            ),
            events: &events
        )
    }

    private mutating func ingestCoordination(_ result: CoordinationStepResult, events: inout [RunEvent]) {
        guard result.state != state.coordination || !result.events.isEmpty else { return }
        state.coordination = result.state
        for sample in result.events {
            coordinationEvents.append(sample)
            events.append(
                .init(
                    .coordinationChanged,
                    "Coordination: \(sample.linkId) → \(sample.status.rawValue) (\(sample.reason))"
                )
            )
        }
    }

    private mutating func signalCoordination(_ signal: String, events: inout [RunEvent]) {
        let catalog = CoordinationCatalog.bundled
        guard catalog.forbidHiddenStatScaling else { return }
        guard state.coordination.chainId != nil else { return }
        ingestCoordination(
            CoordinationEngine.handleSignal(
                catalog: catalog,
                state: state.coordination,
                elapsed: state.elapsed,
                tick: tick,
                signal: signal
            ),
            events: &events
        )
    }

    /// Suspicion Director: explicit encounter levers only. Never scales damage or health.
    private mutating func evaluateSuspicionDirector(events: inout [RunEvent]) {
        let catalog = SuspicionDirectorCatalog.bundled
        guard catalog.forbidHiddenStatScaling else { return }
        guard tick.isMultiple(of: catalog.evaluationIntervalTicks) else { return }
        let result = SuspicionDirector.evaluate(
            catalog: catalog,
            state: state.suspicionDirector,
            tier: state.suspicionTier,
            elapsed: state.elapsed,
            tick: tick,
            rng: &rng,
            budgetCostRelief: state.buildEngine.directorBudgetRelief
        )
        state.suspicionDirector = result.state
        if let decision = result.decision {
            directorDecisions.append(decision)
            events.append(.init(.directorDecision, "Director: \(decision.actionId) (tier \(decision.tier.rawValue))"))
        }
    }

    /// Sensor destruction stresses the district surveillance node and propagates costs/opportunities.
    private mutating func applyCityStateSensorDestroy(events: inout [RunEvent]) {
        let catalog = CityStateCatalog.bundled
        guard catalog.forbidHiddenStatScaling else { return }
        guard let nodeId = CityStateEngine.primarySurveillanceNodeId(catalog: catalog, district: state.district) else {
            return
        }
        let (next, samples) = CityStateEngine.applyHit(
            catalog: catalog,
            state: state.districtState,
            nodeId: nodeId,
            amount: catalog.sensorDestroyIntegrityHit,
            tick: tick,
            reason: "sensor destroyed"
        )
        state.districtState = next
        for sample in samples {
            cityStateEvents.append(sample)
            events.append(
                .init(
                    .cityStateChanged,
                    "City state: \(sample.nodeId) → \(sample.status.rawValue) (\(sample.reason))"
                )
            )
        }
    }

    private mutating func movePlayer(_ input: PlayerInput) {
        guard let index = state.entities.firstIndex(where: { $0.kind == .player }) else { return }
        let velocity = input.movement.normalized() * BossCatalog.bundled.playerSpeed
        state.entities[index].velocity = velocity
        if hypot(velocity.x, velocity.y) > 0.001 {
            state.entities[index].heading = atan2(velocity.y, velocity.x)
        }
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
            let baseSpeed = state.entities[index].kind == .boss
                ? BossCatalog.bundled.shiftManagerSpeed * profile.bossSpeedMultiplier
                : (archetype?.speed ?? 88)
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
            let radius = state.entities[index].radius
            let proposed = previous + state.entities[index].velocity * fixedStep
            let clamped = state.world.bounds.clamped(proposed, margin: radius)

            // Projectiles ignore solid obstacles; world bounds still kill them.
            if kind == .projectile {
                // Record true pre-move origin for swept hits this step.
                projectileOriginsThisStep[state.entities[index].id] = previous
                if clamped != proposed {
                    state.entities[index].health = 0
                } else {
                    state.entities[index].position = clamped
                }
                continue
            }

            // Axis-separated resolution so solid bodies slide along obstacle edges
            // instead of sticking when a diagonal step clips a corner.
            var next = previous
            let tryX = state.world.bounds.clamped(Vector2(x: clamped.x, y: previous.y), margin: radius)
            if !collidesWithObstacle(tryX, radius: radius) {
                next.x = tryX.x
            }
            let tryY = state.world.bounds.clamped(Vector2(x: next.x, y: clamped.y), margin: radius)
            if !collidesWithObstacle(tryY, radius: radius) {
                next.y = tryY.y
            }
            state.entities[index].position = next
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
            // Cap only this projectile weapon — later deployables/projectile weapons must still fire.
            guard projectileCount < CombatLimits.maximumProjectiles else { continue }
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
        // Presentation/FX marker uses the same disable window as the payload so the
        // field does not vanish while targets are still disrupted.
        let markerTicks = max(1 as UInt64, min(durationTicks, 180))
        state.entities.append(Entity(
            id: rng.next(),
            kind: .signalFlood,
            position: player.position,
            health: 1,
            radius: weapon.projectileRadius,
            sourceWeapon: weapon.id,
            payload: weapon.payload,
            effectExpiresAtTick: tick + markerTicks
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
        if disrupted > 0 {
            signalCoordination("guardDisrupted", events: &events)
            signalCoordination("sensorDisabled", events: &events)
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
            let projectile = state.entities[projectileIndex]
            let current = projectile.position
            // Only projectiles that moved this step have an origin. Newly fired ones
            // use a degenerate segment at spawn — never invent a reverse phantom trail.
            let previous = projectileOriginsThisStep[projectile.id] ?? current
            let pRadius = projectile.radius

            var bestTarget: (index: Int, t: Double, id: UInt64)?
            for index in state.entities.indices {
                let target = state.entities[index]
                guard [.cameraPole, .securityGuard, .boss].contains(target.kind), target.health > 0 else { continue }
                let combined = target.radius + pRadius
                guard let t = Self.firstIntersectionT(
                    from: previous,
                    to: current,
                    center: target.position,
                    radius: combined
                ) else { continue }
                if let best = bestTarget {
                    if t < best.t || (t == best.t && target.id < best.id) {
                        bestTarget = (index, t, target.id)
                    }
                } else {
                    bestTarget = (index, t, target.id)
                }
            }
            guard let hit = bestTarget else { continue }
            let targetIndex = hit.index
            // Snap contact to earliest intersection for readable hit placement.
            let ab = current - previous
            state.entities[projectileIndex].position = previous + ab * hit.t

            switch state.entities[projectileIndex].payload {
            case let .some(.damage(amount)):
                let applied = min(amount, max(0, state.entities[targetIndex].health))
                state.entities[targetIndex].health -= amount
                damageDealt += applied
                events.append(.init(.countermeasureHit, "Dealt \(amount) damage to \(state.entities[targetIndex].kind.rawValue)"))
            case let .some(.disableCameraSensors(durationTicks)) where state.entities[targetIndex].kind == .cameraPole:
                let existing = state.entities[targetIndex].sensorDisabledUntilTick ?? tick
                state.entities[targetIndex].sensorDisabledUntilTick = max(existing, tick + durationTicks)
                events.append(.init(.countermeasureHit, "Redacted camera sensors for \(durationTicks) ticks"))
                signalCoordination("sensorDisabled", events: &events)
            case let .some(.spoofCameraSensors(durationTicks, suspicionMultiplier)) where state.entities[targetIndex].kind == .cameraPole:
                let untilTick = max(state.entities[targetIndex].sensorSpoof?.untilTick ?? tick, tick + durationTicks)
                state.entities[targetIndex].sensorSpoof = .init(untilTick: untilTick, suspicionMultiplier: suspicionMultiplier)
                events.append(.init(.countermeasureHit, "Spoofed camera identity for \(durationTicks) ticks"))
                signalCoordination("sensorSpoofed", events: &events)
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

    /// First parameter t ∈ [0,1] along segment AB where a circle of `radius` is entered.
    /// Returns nil if the swept path never intersects the circle.
    private static func firstIntersectionT(
        from a: Vector2,
        to b: Vector2,
        center: Vector2,
        radius: Double
    ) -> Double? {
        let ab = b - a
        let ac = Vector2(x: a.x - center.x, y: a.y - center.y)
        let A = ab.x * ab.x + ab.y * ab.y
        let C0 = ac.x * ac.x + ac.y * ac.y - radius * radius
        // Already overlapping at the start of the segment.
        if C0 <= 0 { return 0 }
        if A < 1e-12 { return nil }
        let Bcoef = 2 * (ac.x * ab.x + ac.y * ab.y)
        let disc = Bcoef * Bcoef - 4 * A * C0
        if disc < 0 { return nil }
        let s = disc.squareRoot()
        let inv = 1 / (2 * A)
        let t1 = (-Bcoef - s) * inv
        let t2 = (-Bcoef + s) * inv
        var best: Double?
        for t in [t1, t2] where t >= 0 && t <= 1 {
            if best == nil || t < best! { best = t }
        }
        return best
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
            let applied = min(processing.damagePerTick, max(0, state.entities[index].health))
            state.entities[index].health -= processing.damagePerTick
            damageDealt += applied
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
                let raw = 4 * damageMultiplier
                let applied = min(raw, max(0, state.entities[index].health))
                state.entities[index].health -= raw
                damageDealt += applied
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
                damagePerSecond = BossCatalog.bundled.shiftManagerContactDamagePerSecond * profile.bossContactDamageMultiplier
            } else {
                damagePerSecond = threat.guardArchetype?.contactDamagePerSecond ?? 8
            }
            damageThisTick += damagePerSecond * fixedStep
        }

        guard damageThisTick > 0 else { return }
        let applied = min(damageThisTick, max(0, player.health))
        state.entities[playerIndex].health = max(0, player.health - damageThisTick)
        damageTaken += applied
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
            state.entities[index].heading = normalizedHeading(
                state.entities[index].heading + speed * fixedStep
            )
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
            state.entities[index].heading = normalizedHeading(atan2(direction.y, direction.x))
        }
    }

    private func isSensorActive(_ entity: Entity) -> Bool {
        (entity.sensorDisabledUntilTick ?? 0) <= tick && (entity.disruptedUntilTick ?? 0) <= tick
    }

    private func normalizedHeading(_ heading: Double) -> Double {
        let tau = Double.pi * 2
        var value = heading.truncatingRemainder(dividingBy: tau)
        if value < 0 { value += tau }
        return value
    }

    private mutating func spawnCadence(events: inout [RunEvent]) {
        let waves = WaveCatalog.bundled
        let director = state.suspicionDirector
        let coordination = state.coordination
        let maximumGuards = min(waves.guardPopulationCeiling, profile.guardMaximumTarget)
        let baseTarget = waves.guardInitialTarget + Int(state.elapsed / waves.guardGrowthIntervalSeconds)
        let landmark = state.landmarkEncounter
        // Explicit director + coordination + landmark levers: additive population pressure, still clamped.
        let challengeGuardDelta = challenge?.guardTargetDelta ?? 0
        let directedTarget = max(
            0,
            baseTarget
                + director.appliedGuardTargetDelta
                + coordination.appliedGuardTargetDelta
                + landmark.appliedGuardTargetDelta
                + challengeGuardDelta
        )
        let targetWithChallenge = min(maximumGuards, directedTarget)
        let current = state.entities.filter { $0.kind == .securityGuard }.count
        let challengeSpawn = challenge?.spawnIntervalMultiplier ?? 1.0
        let combinedIntervalMultiplier =
            director.appliedSpawnIntervalMultiplier
                * coordination.appliedSpawnIntervalMultiplier
                * landmark.appliedSpawnIntervalMultiplier
                * challengeSpawn
        let guardInterval = max(
            1 as UInt64,
            UInt64((Double(waves.guardSpawnIntervalTicks) * combinedIntervalMultiplier).rounded())
        )
        if current < targetWithChallenge && tick.isMultiple(of: guardInterval) {
            let angle = rng.unit() * .pi * 2
            let proposed = Vector2(x: cos(angle) * waves.guardSpawnRadius, y: sin(angle) * waves.guardSpawnRadius)
            let roster = profile.guardRoster
            let archetype = roster[Int(securitySpawnOrdinal % UInt64(roster.count))]
            securitySpawnOrdinal &+= 1
            var spawnPosition = state.world.bounds.clamped(proposed, margin: archetype.radius)
            // If clamping collapsed a spawn onto the player, push out along the ray (no extra RNG).
            if let player = state.entities.first(where: { $0.kind == .player }) {
                let minClearance = archetype.radius + player.radius + 80
                let offset = spawnPosition - player.position
                if offset.magnitude < minClearance {
                    let push = offset.magnitude > 1e-6
                        ? offset.normalized()
                        : Vector2(x: cos(angle), y: sin(angle))
                    spawnPosition = state.world.bounds.clamped(
                        player.position + push * minClearance,
                        margin: archetype.radius
                    )
                }
            }
            state.entities.append(Entity(
                id: rng.next(),
                kind: .securityGuard,
                guardArchetype: archetype,
                position: spawnPosition,
                health: archetype.health,
                radius: archetype.radius
            ))
            spawnedEntities[.securityGuard, default: 0] += 1
            events.append(.init(.entitySpawned, "Contract security dispatched: \(archetype.displayName)"))
        }

        // Deployments are counted against the district's authored starting grid, so
        // districts that open with non-LPR sensors still escalate on schedule.
        let deploymentOrder = profile.sensorDeploymentOrder
        let deployedSensors = max(0, state.entities.filter { $0.kind == .cameraPole }.count - profile.startingSensors.count)
        let sensorInterval = max(
            1 as UInt64,
            UInt64((Double(waves.sensorSpawnIntervalTicks) * director.appliedSensorCadenceMultiplier).rounded())
        )
        let sensorTarget = min(deploymentOrder.count, Int(tick / sensorInterval))
        guard deployedSensors < sensorTarget && tick.isMultiple(of: sensorInterval) else { return }
        let sensor = deploymentOrder[Int(sensorSpawnOrdinal % UInt64(deploymentOrder.count))]
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
        // District escalation scales observation pressure only; recovery stays authored
        // globally so evasion remains a viable answer in every city.
        // City-state observation softener is an explicit infrastructure lever, never damage/HP.
        let cityObservation = CityStateEngine.observationPressureMultiplier(state: state.districtState)
        // Build-engine observation softener is explicit synergy behavior (never damage/HP).
        let buildObservation = max(0.5, 1.0 - state.buildEngine.observationSoftener)
        // Coordination + landmark observation bonuses are explicit levers (never damage/HP).
        let coordinationObservation = 1.0 + state.coordination.appliedObservationBonus
        let landmarkObservation = 1.0 + state.landmarkEncounter.appliedObservationBonus
        // P11 challenge observation mutator is an explicit policy lever (never damage/HP).
        let challengeObservation = 1.0 + (challenge?.observationPressureBonus ?? 0)
        let observed = (Double(guardCount) * tuning.guardPressurePerSecond + contactWeight * tuning.sensorContactPressurePerSecond)
            * profile.suspicionPressureMultiplier
            * cityObservation
            * buildObservation
            * coordinationObservation
            * landmarkObservation
            * challengeObservation
        let recovery = tuning.noContactRecoveryPerSecond * (1.0 + state.buildEngine.suspicionRecoveryBoost)
        let pressure = observed - (contactWeight == 0 ? recovery : 0)
        state.suspicion = min(100, max(0, state.suspicion + pressure * fixedStep))
        if contactWeight > 0 && tick.isMultiple(of: tuning.sensorContactEventIntervalTicks) { events.append(.init(.sensorContact, "LPR scan contact")) }
        state.suspicionTier = tuning.tier(for: state.suspicion)
        if state.suspicionTier != priorTier { events.append(.init(.tierChanged, "Suspicion escalated to tier \(state.suspicionTier.rawValue)")) }
    }

    private mutating func activateShiftManagerIfNeeded(events: inout [RunEvent]) {
        let boss = BossCatalog.bundled
        guard !state.runCompleted, !state.playerDefeated else { return }
        guard state.suspicionTier == .totalVisibility, !state.bossDefeated else { return }
        // Any boss entity (including health <= 0 awaiting removal) blocks respawn.
        guard !state.entities.contains(where: { $0.kind == .boss }) else { return }
        state.entities.append(Entity(
            id: rng.next(),
            kind: .boss,
            position: state.world.bounds.clamped(profile.bossSpawn, margin: boss.shiftManagerRadius),
            health: boss.shiftManagerHealth * profile.bossHealthMultiplier,
            radius: boss.shiftManagerRadius
        ))
        spawnedEntities[.boss, default: 0] += 1
        bossActivatedAtTick = tick
        events.append(.init(.bossActivated, "\(state.district.bossName) activated"))
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
                // One draft opportunity per camera kill (queue if a pick is already open).
                requestUpgradeOffer(events: &events)
                applyCityStateSensorDestroy(events: &events)
                signalCoordination("sensorDestroyed", events: &events)
            }
        }
        if removed.contains(where: { $0.kind == .player }) {
            deathsByArchetype[.player, default: 0] += 1
        }
        if state.bossDefeated && !state.extractionOpen && !state.playerDefeated {
            let boss = BossCatalog.bundled
            state.extractionOpen = true
            state.entities.append(Entity(id: rng.next(), kind: .extraction, position: profile.extractionPosition, health: boss.blindSpotHealth, radius: boss.blindSpotRadius))
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

    /// Queue or open a three-choice draft for each camera destruction (1:1 with data shards).
    private mutating func requestUpgradeOffer(events: inout [RunEvent]) {
        if !state.pendingUpgradeChoices.isEmpty {
            state.queuedUpgradeOffers += 1
            return
        }
        offerUpgrades(events: &events)
    }

    /// Opens a three-choice draft when possible. Returns false if no draft was opened.
    @discardableResult
    private mutating func offerUpgrades(events: inout [RunEvent]) -> Bool {
        guard state.pendingUpgradeChoices.isEmpty else { return false }
        // Drop in-flight projectiles so an offer freeze cannot immediately chain
        // into another camera kill the instant the player selects an upgrade.
        state.entities.removeAll { $0.kind == .projectile }
        let eligible = UpgradeChoice.allCases.filter(isUpgradeEligible)
        guard !eligible.isEmpty else { return false }
        var weightingTags = CitySystemicRulesCatalog.bundled.rule(for: state.district)?.upgradeWeightingTags ?? []
        if let extras = challenge?.extraUpgradeWeightingTags {
            for tag in extras where !weightingTags.contains(tag) {
                weightingTags.append(tag)
            }
        }
        let result = UpgradeOfferBias.pickOffers(
            eligible: eligible,
            weightingTags: weightingTags,
            count: UpgradeOfferBias.defaultOfferCount,
            build: .bundled,
            rng: &rng
        )
        state.pendingUpgradeChoices = result.offers
        offeredUpgrades.append(state.pendingUpgradeChoices)
        let sample = UpgradeOfferBiasSample(
            tick: tick,
            weightingTags: weightingTags,
            preferredOfferedCount: result.preferredCount,
            totalOffered: result.offers.count,
            offeredIds: result.offers.map(\.rawValue)
        )
        upgradeOfferBiasEvents.append(sample)
        // Destruction progression language — covers LPR and other cameraPole archetypes.
        let biasNote = weightingTags.isEmpty
            ? "Camera data shard recovered"
            : "Camera data shard recovered (city bias: \(weightingTags.joined(separator: ",")))"
        events.append(.init(.upgradeOffered, biasNote))
        return true
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
            if let weaponIndex = state.activeWeapons.firstIndex(where: { $0.id == weapon }) {
                apply(definition.effect, to: &state.activeWeapons[weaponIndex])
                state.activeWeapons[weaponIndex].level += 1
            } else if definition.addsWeapon, state.activeWeapons.count < CombatLimits.maximumActiveWeapons {
                // Unlock must apply the card's effect to baseline stats (cadence/damage/etc.).
                // Leaving the weapon at level 1 with effects applied matches "acquire L1 + upgrade".
                var system = ContentCatalog.bundled.weapon(weapon).weaponSystem()
                apply(definition.effect, to: &system)
                state.activeWeapons.append(system)
            }
            // Stale/ineligible weapon choice: still consume the draft so the run cannot soft-lock.
        }
        if let evolution = definition.evolution { state.evolutions.insert(evolution) }
        state.pendingUpgradeChoices = []
        selectedUpgrades.append(choice)
        events.append(.init(.upgradeSelected, "Applied \(choice.rawValue)"))
        recomputeBuildEngine(events: &events)
        drainQueuedUpgradeOffers(events: &events)
    }

    /// Drain multi-kill queue one draft at a time. If a draft cannot open (no eligible
    /// upgrades), drop the remaining queue so `queuedUpgradeOffers` cannot orphan.
    private mutating func drainQueuedUpgradeOffers(events: inout [RunEvent]) {
        while state.queuedUpgradeOffers > 0 && state.pendingUpgradeChoices.isEmpty {
            state.queuedUpgradeOffers -= 1
            if !offerUpgrades(events: &events) {
                state.queuedUpgradeOffers = 0
                break
            }
        }
    }

    /// Rebuild synergy graph from selected upgrades; emit events for newly active synergies.
    private mutating func recomputeBuildEngine(events: inout [RunEvent]) {
        let catalog = BuildEngineCatalog.bundled
        guard catalog.forbidHiddenStatScaling else { return }
        let prior = Set(state.buildEngine.activeSynergyIds)
        let next = BuildEngine.evaluate(catalog: catalog, selected: selectedUpgrades)
        state.buildEngine = next
        let newlyActive = Set(next.activeSynergyIds).subtracting(prior)
        for sample in BuildEngine.activations(catalog: catalog, state: next, tick: tick) where newlyActive.contains(sample.synergyId) {
            buildSynergyActivations.append(sample)
            events.append(.init(.buildSynergyChanged, "Build synergy: \(sample.synergyId) — \(sample.summary)"))
        }
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
