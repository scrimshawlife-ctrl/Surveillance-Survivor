import SpriteKit
import SurveillanceCore

@MainActor
final class EntityProjector {
    private var nodes: [UInt64: SKNode] = [:]
    private var nodeKinds: [UInt64: EntityKind] = [:]
    private var pool: [EntityKind: [SKNode]] = [:]
    /// Mirrors `PresentationPipeline.PresentationSettings` — not a second settings store.
    private var qualityTier: PresentationQualityTier = .full
    private var reducedFlash = false
    /// Presentation clock for multi-frame sprite cycles (not simulation time).
    private var animationTime: TimeInterval = 0
    /// Which clip each entity is playing and when it started, so a one-shot resumes
    /// from where it is instead of restarting every render frame.
    private var activeClips: [UInt64: (stem: String, start: TimeInterval)] = [:]
    /// Previous health per entity. A decrease is how the hit reaction is detected —
    /// presentation observing simulation truth, never producing it.
    private var lastHealth: [UInt64: Double] = [:]

    /// Apply accessibility / quality from the existing presentation pipeline.
    func applyPresentationSettings(_ settings: PresentationPipeline.PresentationSettings) {
        qualityTier = settings.tier
        reducedFlash = settings.reducedFlash
    }

    /// Backward-compatible entry used by older call sites; prefer `applyPresentationSettings`.
    func setReducedFlash(_ reducedFlash: Bool) {
        self.reducedFlash = reducedFlash
        qualityTier = PresentationQualityTier.resolve(reducedMotion: false, reducedFlash: reducedFlash)
    }

    /// Synchronize presentation nodes. Optional `display` samples apply interpolated
    /// poses and secondary motion; simulation `entities` remain the authority for
    /// appearance fields (health, weapons, sensor flags).
    /// `tick` is required for deployable expended/active timing when `display` omits a sample.
    func synchronize(
        entities: [Entity],
        display: [UInt64: PresentationPipeline.DisplaySample] = [:],
        tick: UInt64 = 0,
        animationDelta: TimeInterval = 1.0 / 60.0,
        targetedIDs: Set<UInt64> = [],
        in scene: SKScene
    ) {
        animationTime += max(0, animationDelta)

        let liveIDs = Set(entities.map(\.id))
        // Density soft-out uses existing quality ladder + CombatLimits calibration.
        let densityScale = qualityTier.densityScale(entityCount: entities.count)

        for (id, node) in nodes where !liveIDs.contains(id) {
            node.removeFromParent()
            if let kind = nodeKinds[id] {
                prepareForReuse(node, kind: kind)
                pool[kind, default: []].append(node)
            }
            nodes[id] = nil
            nodeKinds[id] = nil
            activeClips[id] = nil
            lastHealth[id] = nil
        }

        for entity in entities {
            let node = nodes[entity.id] ?? acquireNode(for: entity, in: scene)
            let sample = display[entity.id]
            if let sample {
                node.position = sample.position
                if entity.kind == .cameraPole {
                    // The cone revolves fully with LOS heading. The body swivels with
                    // it, but only within a bounded arc: the pole art is drawn as a
                    // vertical mast seen from above, so rotating it through a full
                    // circle reads as the mast toppling. A small arc makes the camera
                    // visibly track what it is scanning while staying a standing pole.
                    node.zRotation = 0
                    node.childNode(withName: "body")?.zRotation = Self.cameraSwivel(for: sample.heading)
                    node.childNode(withName: "scan-cone")?.zRotation = sample.heading
                } else if entity.kind == .player {
                    node.zRotation = sample.secondary.lean
                    node.xScale = sample.secondary.squash
                    node.yScale = 2 - sample.secondary.squash
                } else {
                    node.zRotation = 0
                    node.xScale = 1
                    node.yScale = 1
                }
            } else {
                node.position = CGPoint(x: CGFloat(entity.position.x), y: CGFloat(entity.position.y))
                if entity.kind == .cameraPole {
                    node.zRotation = 0
                    node.childNode(withName: "body")?.zRotation = Self.cameraSwivel(for: CGFloat(entity.heading))
                    node.childNode(withName: "scan-cone")?.zRotation = CGFloat(entity.heading)
                } else {
                    node.zRotation = 0
                }
                node.xScale = 1
                node.yScale = 1
            }
            node.zPosition = VisualCombatLayers.entityLayer(for: entity.kind)
            updateAppearance(
                node,
                for: entity,
                densityScale: densityScale,
                animationState: sample?.animationState,
                tick: tick
            )
            // Only things auto-fire can actually shoot carry a reticle.
            let targetable: Set<EntityKind> = [.cameraPole, .securityGuard, .boss]
            applyTargetReticle(
                on: node,
                targeted: targetable.contains(entity.kind) && targetedIDs.contains(entity.id)
            )
        }
    }

    /// Start time for `stem` on `id`, latching the moment the clip changes so a
    /// one-shot plays from frame 1 exactly once.
    private func clipStart(id: UInt64, stem: String) -> TimeInterval {
        if let active = activeClips[id], active.stem == stem { return active.start }
        activeClips[id] = (stem, animationTime)
        return animationTime
    }

    /// Resolve a clip frame for `entity`, or nil to leave the caller's normal
    /// still/atlas selection alone.
    private func clipFrame(for entity: Entity, state: EntityAnimationState?) -> String? {
        if let state, let clip = AnimationClipCatalog.clip(for: entity.kind, state: state) {
            let elapsed = animationTime - clipStart(id: entity.id, stem: clip.stem)
            return AnimationClipCatalog.frameName(
                for: clip,
                elapsed: elapsed,
                holdStill: !qualityTier.advancesSpriteFrameCycles
            )
        }
        return nil
    }

    /// Player hit reaction. Deliberately not bound to `.damaged`, which is the
    /// sustained "health below 30" state — binding it there would freeze the walk
    /// cycle for the rest of the run. Triggered by an observed health decrease and
    /// cleared when the one-shot completes, so the player returns to walking.
    private func playerDamageFrame(for entity: Entity) -> String? {
        let clip = AnimationClipCatalog.playerDamage
        if let previous = lastHealth[entity.id], entity.health < previous - 0.0001, entity.health > 0 {
            activeClips[entity.id] = (clip.stem, animationTime)
        }
        guard let active = activeClips[entity.id], active.stem == clip.stem else { return nil }
        let elapsed = animationTime - active.start
        if AnimationClipCatalog.hasFinished(clip, elapsed: elapsed) {
            activeClips[entity.id] = nil
            return nil
        }
        return AnimationClipCatalog.frameName(
            for: clip,
            elapsed: elapsed,
            holdStill: !qualityTier.advancesSpriteFrameCycles
        )
    }

    private func acquireNode(for entity: Entity, in scene: SKScene) -> SKNode {
        let node = pool[entity.kind]?.popLast() ?? makeNode(for: entity.kind, sensor: entity.sensorArchetype)
        node.name = "entity-\(entity.id)"
        node.isHidden = false
        node.alpha = 1
        scene.addChild(node)
        nodes[entity.id] = node
        nodeKinds[entity.id] = entity.kind
        return node
    }

    private func makeNode(for kind: EntityKind, sensor: SensorArchetype? = nil) -> SKNode {
        switch kind {
        case .player:
            return TextureAssetLoader.sprite(role: .playerIdleDown) ?? playerFallback()
        case .securityGuard:
            // Archetype texture swapped in updateAppearance; start with default skin.
            // Size and anchor come from the map so this cannot drift from the table
            // that applyGuardAppearance uses on the very next frame.
            let guardEntry = VisualAssetMap.entry(.guardDefault)
            return TextureAssetLoader.sprite(named: GameAssetName.Guard.default, size: guardEntry.displaySize, anchor: guardEntry.anchor)
                ?? TextureAssetLoader.sprite(role: .guardDefault)
                ?? shape(rect: CGSize(width: 24, height: 24), radius: 5, fill: .systemRed)
        case .cameraPole:
            return cameraNode(archetype: sensor)
        case .projectile:
            // Prefer weapon-family projectile stills (Hallmark M9); fall back to shape taxonomy.
            return TextureAssetLoader.sprite(role: .projectileDefault)
                ?? projectileFallbackShape(for: nil)
        case .boss:
            return TextureAssetLoader.sprite(role: .bossDefault)
                ?? bossFallbackShape()
        case .extraction:
            return TextureAssetLoader.sprite(role: .blindSpotDecal)
                ?? shape(circle: 60, fill: .cyan.withAlphaComponent(0.18), stroke: .cyan)
        case .mirrorArray:
            return TextureAssetLoader.sprite(role: .mirrorArray)
                ?? shape(rect: CGSize(width: 48, height: 48), radius: 8, fill: .systemTeal)
        case .signalFlood:
            return TextureAssetLoader.sprite(role: .signalFlood)
                ?? shape(
                    circle: 72,
                    fill: VisualCombatPalette.floodFill(reducedFlash: false, densityScale: 1),
                    stroke: VisualCombatPalette.floodStroke(reducedFlash: false, densityScale: 1)
                )
        }
    }

    private func prepareForReuse(_ node: SKNode, kind: EntityKind) {
        node.removeAllActions()
        node.position = .zero
        node.zRotation = 0
        node.xScale = 1
        node.yScale = 1
        node.alpha = 1
        node.isHidden = true
        node.name = nil
        node.userData = nil
        if let sprite = node as? SKSpriteNode {
            sprite.colorBlendFactor = 0
            sprite.color = .white
        }
        if let shape = node as? SKShapeNode {
            shape.fillColor = .clear
            shape.strokeColor = .clear
            shape.lineWidth = 1
            shape.xScale = 1
            shape.yScale = 1
        }
        node.childNode(withName: "status-ring")?.removeFromParent()
        guard kind == .cameraPole else { return }
        // Camera structural children persist across pooling, so reset every
        // projector-owned mutable value before a different sensor reuses them.
        if let cone = node.childNode(withName: "scan-cone") {
            cone.removeAllActions()
            cone.zRotation = 0
            cone.xScale = 1
            cone.yScale = 1
            cone.alpha = 1
            cone.isHidden = false
        }
        if let accent = node.childNode(withName: "sensor-accent") as? SKShapeNode {
            accent.fillColor = .systemYellow
            accent.strokeColor = .white
            accent.alpha = 1
            accent.isHidden = false
        }
    }

    private func updateAppearance(
        _ node: SKNode,
        for entity: Entity,
        densityScale: CGFloat = 1,
        animationState: EntityAnimationState? = nil,
        tick: UInt64 = 0
    ) {
        if entity.kind == .mirrorArray || entity.kind == .signalFlood {
            applyDeployableAppearance(
                node,
                for: entity,
                densityScale: densityScale,
                animationState: animationState,
                tick: tick
            )
            return
        }
        if entity.kind == .projectile {
            applyProjectileAppearance(node, for: entity)
            return
        }
        if entity.kind == .player {
            applyPlayerVisibilityHalo(on: node, alive: entity.health > 0)
            let integrity = max(0, entity.health)
            if let body = node as? SKShapeNode {
                body.fillColor = integrity <= 0 ? .darkGray : integrity < 30 ? .systemPink : VisualCombatPalette.playerFill
                body.strokeColor = integrity < 30 ? .systemRed : VisualCombatPalette.playerStroke
            } else if let sprite = node as? SKSpriteNode {
                let role = VisualAssetMap.playerRole(
                    velocityX: entity.velocity.x,
                    velocityY: entity.velocity.y,
                    heading: entity.heading
                )
                let baseName = VisualAssetMap.assetName(role)
                // Defeat and extract are terminal and outrank locomotion; the hit
                // reaction is a brief interrupt. Anything else falls through to the
                // ordinary walk/idle atlas.
                let frameName = clipFrame(for: entity, state: animationState)
                    ?? playerDamageFrame(for: entity)
                    ?? (qualityTier.advancesSpriteFrameCycles
                        ? PlayerAtlasManifest.frameName(baseAsset: baseName, at: animationTime)
                        : baseName)
                let entry = VisualAssetMap.entry(role)
                if sprite.userData?["asset"] as? String != frameName,
                   let image = TextureAssetLoader.image(named: frameName)
                    ?? TextureAssetLoader.image(named: baseName) {
                    // Lock display size: SpriteKit resets size to texture pixels on swap,
                    // which reads as "resolution thrash" across walk/idle frames.
                    applyTexture(
                        image,
                        to: sprite,
                        asset: frameName,
                        displaySize: entry.displaySize,
                        anchor: entry.anchor
                    )
                }
                sprite.alpha = integrity <= 0 ? 0.35 : integrity < 30 ? 0.75 : 1
            } else {
                node.alpha = integrity <= 0 ? 0.35 : integrity < 30 ? 0.75 : 1
            }
            // Recorded last, after playerDamageFrame has compared against it.
            lastHealth[entity.id] = entity.health
            return
        }
        guard entity.kind == .cameraPole else {
            if [.securityGuard, .boss].contains(entity.kind) {
                if let body = node as? SKShapeNode {
                    if entity.kind == .boss {
                        body.fillColor = entity.processing == nil
                            ? VisualCombatPalette.bossFill
                            : VisualCombatPalette.processingTint
                        body.strokeColor = entity.disruptedUntilTick == nil
                            ? VisualCombatPalette.bossStroke
                            : VisualCombatPalette.disruptTint
                    } else {
                        let baseColor = guardColor(for: entity.guardArchetype)
                        body.fillColor = entity.processing == nil ? baseColor : VisualCombatPalette.processingTint
                        // Avoid pure-white stroke outlines (reads as "white out lines" on device).
                        body.strokeColor = entity.disruptedUntilTick == nil
                            ? VisualCombatPalette.bossStroke.withAlphaComponent(0.55)
                            : VisualCombatPalette.disruptTint
                    }
                } else if let sprite = node as? SKSpriteNode {
                    if entity.kind == .securityGuard {
                        applyGuardAppearance(sprite, for: entity)
                    } else if entity.kind == .boss {
                        applyBossAppearance(sprite, for: entity)
                    }
                    // Textures carry archetype identity; tint only for processing / disruption.
                    if entity.processing != nil {
                        sprite.color = VisualCombatPalette.processingTint
                        sprite.colorBlendFactor = 0.4
                    } else if entity.disruptedUntilTick != nil {
                        sprite.color = VisualCombatPalette.disruptTint
                        sprite.colorBlendFactor = 0.35
                    } else {
                        sprite.colorBlendFactor = 0
                    }
                }
                // Shape grammar (dash + silhouette) so status is not color-only (Art QA F-P2-02).
                applyStatusRing(
                    on: node,
                    processing: entity.processing != nil,
                    disrupted: entity.disruptedUntilTick != nil
                )
            }
            return
        }
        let lprRole = VisualAssetMap.lprRole(health: entity.health)
        let stillName = VisualAssetMap.assetName(lprRole)
        // lpr_scan_loop while sweeping, lpr_destroy_sequence once on death; the
        // health-derived still remains the fallback and the shape-node fallback below
        // is untouched.
        let bodyName = clipFrame(for: entity, state: animationState) ?? stillName
        if let sprite = node.childNode(withName: "body") as? SKSpriteNode {
            if sprite.userData?["asset"] as? String != bodyName,
               let image = TextureAssetLoader.image(named: bodyName)
                ?? TextureAssetLoader.image(named: stillName) {
                let entry = VisualAssetMap.entry(lprRole)
                applyTexture(
                    image,
                    to: sprite,
                    asset: bodyName,
                    displaySize: entry.displaySize,
                    anchor: entry.anchor
                )
            }
        } else if let existing = node.childNode(withName: "body"), existing.userData?["asset"] as? String != bodyName {
            let replacement = cameraBody(role: lprRole, health: entity.health)
            replacement.name = "body"
            replacement.zPosition = existing.zPosition
            replacement.userData = NSMutableDictionary(dictionary: ["asset": bodyName])
            existing.removeFromParent()
            node.addChild(replacement)
        }
        if let accent = node.childNode(withName: "sensor-accent") as? SKShapeNode {
            accent.fillColor = sensorColor(for: entity.sensorArchetype)
            // Soft stroke — pure white outlines read as white-out lines on device.
            accent.strokeColor = entity.disruptedUntilTick == nil
                ? SKColor(white: 0.75, alpha: 0.35)
                : .systemYellow.withAlphaComponent(0.7)
            accent.lineWidth = 1
        }

        guard let cone = node.childNode(withName: "scan-cone") as? SKShapeNode else { return }
        let archetypeKey = (entity.sensorArchetype ?? .lprCameraPole).rawValue
        if cone.userData?["archetype"] as? String != archetypeKey {
            cone.path = scanConePath(for: entity.sensorArchetype)
            let data = (cone.userData as NSMutableDictionary?) ?? NSMutableDictionary()
            data["archetype"] = archetypeKey
            cone.userData = data
        }
        // Density softens cones so stacked LPR wedges don't white-out the field.
        if entity.sensorDisabledUntilTick != nil || entity.disruptedUntilTick != nil {
            cone.isHidden = true
        } else if entity.sensorSpoof != nil {
            cone.isHidden = false
            cone.fillColor = VisualCombatPalette.spoofConeFill(densityScale: densityScale)
            cone.strokeColor = VisualCombatPalette.spoofConeStroke(densityScale: densityScale)
        } else {
            cone.isHidden = false
            cone.fillColor = VisualCombatPalette.hostileConeFill(densityScale: densityScale)
            cone.strokeColor = VisualCombatPalette.hostileConeStroke(densityScale: densityScale)
        }
    }

    /// Keeps the dark player silhouette readable on every city floor without
    /// recoloring the authored sprite. The broken outer ring remains meaningful
    /// in grayscale and stays below the character in the entity's local space.
    /// Marks what auto-fire has acquired. Presentation only — never affects
    /// targeting, damage, or collision.
    private func applyTargetReticle(on node: SKNode, targeted: Bool) {
        let name = "target-reticle"
        if !targeted {
            node.childNode(withName: name)?.removeFromParent()
            return
        }
        if node.childNode(withName: name) != nil { return }
        let reticle = SKShapeNode(circleOfRadius: 17)
        reticle.name = name
        reticle.strokeColor = VisualDesignTokens.skTargetReticle
        reticle.lineWidth = 2
        reticle.fillColor = .clear
        reticle.zPosition = 6
        reticle.alpha = reducedFlash ? 0.55 : 0.85
        if !reducedFlash {
            // A slow pulse reads as "acquired" without competing with hit flashes.
            reticle.run(.repeatForever(.sequence([
                .scale(to: 1.18, duration: 0.42),
                .scale(to: 1.0, duration: 0.42)
            ])))
        }
        node.addChild(reticle)
    }

    private func applyPlayerVisibilityHalo(on node: SKNode, alive: Bool) {
        let halo: SKShapeNode
        if let existing = node.childNode(withName: "player-visibility-halo") as? SKShapeNode {
            halo = existing
        } else {
            let path = CGMutablePath()
            for quadrant in 0..<4 {
                let start = CGFloat(quadrant) * .pi / 2 + 0.18
                path.addArc(center: .zero, radius: 24, startAngle: start, endAngle: start + 0.92, clockwise: false)
            }
            halo = SKShapeNode(path: path)
            halo.name = "player-visibility-halo"
            halo.position = CGPoint(x: 0, y: 7)
            halo.zPosition = -0.5
            halo.lineWidth = 3
            halo.glowWidth = 0
            node.addChild(halo)
        }
        halo.strokeColor = alive
            ? SKColor(white: 0.96, alpha: 0.72)
            : SKColor(white: 0.5, alpha: 0.3)
        halo.isHidden = false
    }

    /// Bounded mast swivel from the authoritative scan heading.
    ///
    /// Decorative and clamped: the sim owns `heading` and `rotationSpeed`, this only
    /// projects them. Sine of the heading gives a smooth back-and-forth as the
    /// sensor sweeps, so the mast leans toward what it is watching and returns,
    /// never spinning past the arc.
    static let cameraSwivelLimit: CGFloat = 0.28 // ~16 degrees

    static func cameraSwivel(for heading: CGFloat) -> CGFloat {
        sin(heading) * cameraSwivelLimit
    }

    private func cameraNode(archetype: SensorArchetype?) -> SKNode {
        let container = SKNode()
        let intact = VisualAssetMap.Role.lprIntact
        let body = cameraBody(role: intact, health: 60)
        body.name = "body"
        body.zPosition = 2
        body.userData = NSMutableDictionary(dictionary: ["asset": VisualAssetMap.assetName(intact)])
        container.addChild(body)
        let accent = shape(circle: 7, fill: .systemYellow)
        accent.name = "sensor-accent"
        accent.zPosition = 3
        container.addChild(accent)

        let cone = SKShapeNode(path: scanConePath(for: archetype))
        cone.name = "scan-cone"
        // Recorded so a pooled node reused by a different sensor rebuilds its cone
        // instead of inheriting the previous archetype's detection volume.
        cone.userData = NSMutableDictionary(dictionary: ["archetype": (archetype ?? .lprCameraPole).rawValue])
        cone.fillColor = VisualCombatPalette.hostileConeFill(densityScale: 1)
        cone.strokeColor = VisualCombatPalette.hostileConeStroke(densityScale: 1)
        cone.lineWidth = 1
        // Cones under body so LPR silhouette stays primary.
        cone.zPosition = -1
        container.addChild(cone)
        return container
    }

    private func cameraBody(role: VisualAssetMap.Role, health: Double) -> SKNode {
        if let sprite = TextureAssetLoader.sprite(role: role) { return sprite }
        let color: SKColor = health <= 0 ? .darkGray : health < 30 ? .systemOrange : .systemYellow
        return shape(rect: CGSize(width: 14, height: 46), radius: 3, fill: color)
    }

    /// Draw the sensor's *actual* detection volume.
    ///
    /// This was hardcoded to radius 403 / half-angle pi/7, which happens to match
    /// `lprCameraPole` and no other archetype. Every other sensor was drawn lying
    /// about where it detects: the doorbell swarm claimed 403 units when it reaches
    /// 260, the pan-tilt eye reaches 520 but drew 403, and the acoustic detector is
    /// omnidirectional yet drew a 25.7-degree wedge. Players read the cone as the
    /// contract and were caught outside it, or crept around a wedge that did not
    /// bound anything. Geometry now comes from the same archetype values
    /// `Simulation.contactWeight` tests against, so the drawing cannot drift from
    /// the rule.
    private func scanConePath(for archetype: SensorArchetype?) -> CGPath {
        let sensor = archetype ?? .lprCameraPole
        let range = CGFloat(sensor.scanRange)
        guard let halfAngle = sensor.scanHalfAngle.map({ CGFloat($0) }) else {
            // No half-angle means the sim checks range alone — an omnidirectional
            // sensor. A ring is the honest shape; a wedge would imply a blind side
            // that does not exist.
            return CGPath(ellipseIn: CGRect(x: -range, y: -range, width: range * 2, height: range * 2), transform: nil)
        }
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addArc(center: .zero, radius: range, startAngle: -halfAngle, endAngle: halfAngle, clockwise: false)
        path.closeSubpath()
        return path
    }

    private func playerFallback() -> SKShapeNode {
        shape(circle: 18, fill: .white, stroke: .cyan)
    }

    private func guardColor(for archetype: GuardArchetype?) -> SKColor {
        switch archetype {
        case .flashlightCadet: .systemYellow
        case .radioGuy: .systemBlue
        case .clipboardEnforcer: .systemOrange
        case .tacticalPolo: .systemRed
        case .segwaySentinel: .systemTeal
        case .supervisorOnBreak: .systemBrown
        case nil: .systemRed
        }
    }

    /// Hallmark m1 — roster skins when attached; fall back to `guard_default`.
    /// Inventory-first multi-frame: cycles `base_2…` only when those PNGs exist
    /// (`OptionalSpriteFrameCycle`); otherwise holds the still (Art QA F-P2-03 defer).
    private func applyGuardAppearance(_ sprite: SKSpriteNode, for entity: Entity) {
        let baseName = GameAssetName.Guard.asset(for: entity.guardArchetype)
        // Advance the walk cycle only while the sim says this guard is moving, so a
        // halted guard holds its still instead of marching on the spot. Same speed
        // threshold the rest of presentation uses — read from state, never invented here.
        let walking = EntityAnimationStateMachine.hostileState(entity: entity) == .moving
        let frameName = walking && qualityTier.advancesSpriteFrameCycles
            ? OptionalSpriteFrameCycle.frameName(base: baseName, at: animationTime)
            : baseName
        if sprite.userData?["asset"] as? String != frameName,
           let image = TextureAssetLoader.image(named: frameName)
            ?? TextureAssetLoader.image(named: baseName)
            ?? TextureAssetLoader.image(named: GameAssetName.Guard.default) {
            let entry = VisualAssetMap.entry(.guardDefault)
            applyTexture(image, to: sprite, asset: frameName, displaySize: entry.displaySize, anchor: entry.anchor)
        }
    }

    /// Boss still + optional multi-frame bank when `boss_default_2…` inventory exists.
    private func applyBossAppearance(_ sprite: SKSpriteNode, for entity: Entity) {
        let baseName = GameAssetName.Boss.default
        let walking = EntityAnimationStateMachine.hostileState(entity: entity) == .moving
        let frameName = walking && qualityTier.advancesSpriteFrameCycles
            ? OptionalSpriteFrameCycle.frameName(base: baseName, at: animationTime)
            : baseName
        if sprite.userData?["asset"] as? String != frameName,
           let image = TextureAssetLoader.image(named: frameName)
            ?? TextureAssetLoader.image(named: baseName) {
            let entry = VisualAssetMap.entry(.bossDefault)
            applyTexture(image, to: sprite, asset: frameName, displaySize: entry.displaySize, anchor: entry.anchor)
        }
    }

    /// Assign texture without letting SpriteKit blow display size to source pixel dimensions.
    private func applyTexture(
        _ image: UIImage,
        to sprite: SKSpriteNode,
        asset: String,
        displaySize: CGSize,
        anchor: CGPoint
    ) {
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        sprite.texture = texture
        sprite.size = displaySize
        sprite.anchorPoint = anchor
        let data = (sprite.userData as NSMutableDictionary?) ?? NSMutableDictionary()
        data["asset"] = asset
        data["displayWidth"] = displaySize.width
        data["displayHeight"] = displaySize.height
        sprite.userData = data
    }

    private func sensorColor(for archetype: SensorArchetype?) -> SKColor {
        switch archetype ?? .lprCameraPole {
        case .lprCameraPole: .systemYellow
        case .panTiltZoomEye: .systemPurple
        case .parkingLotDrone: .systemTeal
        case .smartDoorbellSwarm: .systemPink
        case .acousticGunshotDetector: .systemOrange
        case .predictivePatrolNode: .systemIndigo
        }
    }

    private func projectileStyle(for weapon: WeaponID?) -> (fill: SKColor, stroke: SKColor, lineWidth: CGFloat) {
        switch weapon {
        case .kineticCountermeasure, .none:
            (VisualCombatPalette.kineticFill, .white, 1)
        case .redactionOrdinance:
            (VisualCombatPalette.redactionFill, VisualCombatPalette.redactionStroke, 2)
        case .identityTransponder:
            (VisualCombatPalette.spoofFill, VisualCombatPalette.playerStroke, 1.5)
        case .foiaSwarm:
            (VisualCombatPalette.foiaFill, .white, 1)
        case .mirrorArray:
            (.systemTeal, .white, 1)
        case .signalFlood:
            (VisualCombatPalette.foiaFill.withAlphaComponent(0.85), .systemOrange, 1)
        }
    }

    /// Distinct fallback silhouettes when still art is missing (shape taxonomy).
    private func projectileFallbackShape(for weapon: WeaponID?) -> SKShapeNode {
        let style = projectileStyle(for: weapon)
        switch weapon {
        case .redactionOrdinance:
            // Horizontal bar — black redaction strip.
            return shape(rect: CGSize(width: 14, height: 5), radius: 1, fill: style.fill, stroke: style.stroke)
        case .foiaSwarm:
            // Form stack — tall thin sheet.
            return shape(rect: CGSize(width: 6, height: 12), radius: 1, fill: style.fill, stroke: style.stroke)
        case .identityTransponder:
            // Spoof puck — hollow-feeling disk.
            let node = shape(circle: 6, fill: style.fill, stroke: style.stroke)
            node.lineWidth = style.lineWidth
            return node
        default:
            // Kinetic dart — small disk.
            return shape(circle: 5, fill: style.fill, stroke: style.stroke)
        }
    }

    private func bossFallbackShape() -> SKShapeNode {
        let node = shape(rect: CGSize(width: 64, height: 64), radius: 10, fill: VisualCombatPalette.bossFill, stroke: VisualCombatPalette.bossStroke)
        node.lineWidth = 2.5
        return node
    }

    /// Hallmark M9 — distinct projectile stills per weapon family when attached.
    private func applyProjectileAppearance(_ node: SKNode, for entity: Entity) {
        let assetName = GameAssetName.Projectile.asset(for: entity.sourceWeapon)
        if let sprite = node as? SKSpriteNode {
            if sprite.userData?["asset"] as? String != assetName,
               let image = TextureAssetLoader.image(named: assetName)
                ?? TextureAssetLoader.image(named: GameAssetName.Projectile.default) {
                let entry = VisualAssetMap.entry(.projectileDefault)
                applyTexture(image, to: sprite, asset: assetName, displaySize: entry.displaySize, anchor: entry.anchor)
            }
            return
        }
        if let body = node as? SKShapeNode {
            let style = projectileStyle(for: entity.sourceWeapon)
            body.fillColor = style.fill
            body.strokeColor = style.stroke
            body.lineWidth = style.lineWidth
            let diameter = max(6, CGFloat(entity.radius) * 2)
            body.xScale = diameter / 10
            body.yScale = diameter / 10
        }
    }

    /// Three-state deployable textures (inactive / active / expended). Live entities
    /// are typically `.active`; expended shows when health is depleted or the effect
    /// expiry tick has passed. Prefer the presentation sample's animation state so
    /// temporal expiry is not stuck at tick 0.
    private func applyDeployableAppearance(
        _ node: SKNode,
        for entity: Entity,
        densityScale: CGFloat = 1,
        animationState: EntityAnimationState? = nil,
        tick: UInt64 = 0
    ) {
        let state = animationState
            ?? EntityAnimationStateMachine.deployableState(entity: entity, tick: tick)
        let assetName: String
        switch entity.kind {
        case .mirrorArray:
            switch state {
            case .expended: assetName = GameAssetName.Deployable.mirrorArrayExpended
            case .active: assetName = GameAssetName.Deployable.mirrorArrayActive
            default: assetName = GameAssetName.Deployable.mirrorArrayInactive
            }
        case .signalFlood:
            switch state {
            case .expended: assetName = GameAssetName.Deployable.signalFloodExpended
            case .active: assetName = GameAssetName.Deployable.signalFloodActive
            default: assetName = GameAssetName.Deployable.signalFloodInactive
            }
        default:
            return
        }
        let fallback = entity.kind == .mirrorArray
            ? GameAssetName.Deployable.mirrorArray
            : GameAssetName.Deployable.signalFlood
        if let sprite = node as? SKSpriteNode {
            if sprite.userData?["asset"] as? String != assetName,
               let image = TextureAssetLoader.image(named: assetName)
                ?? TextureAssetLoader.image(named: fallback) {
                let role: VisualAssetMap.Role = entity.kind == .mirrorArray ? .mirrorArray : .signalFlood
                let entry = VisualAssetMap.entry(role)
                applyTexture(image, to: sprite, asset: assetName, displaySize: entry.displaySize, anchor: entry.anchor)
            }
            sprite.alpha = state == .expended ? 0.7 : 1
            return
        }
        if let body = node as? SKShapeNode {
            if entity.kind == .signalFlood {
                body.fillColor = VisualCombatPalette.floodFill(reducedFlash: reducedFlash, densityScale: densityScale)
                body.strokeColor = VisualCombatPalette.floodStroke(reducedFlash: reducedFlash, densityScale: densityScale)
            } else {
                body.fillColor = .systemTeal
                body.strokeColor = .white
            }
            body.alpha = state == .expended ? 0.5 : 1
        }
    }

    /// Dashed stamp (processing) vs dashed ellipse (disrupt) — non-color status channel.
    private func applyStatusRing(on node: SKNode, processing: Bool, disrupted: Bool) {
        guard let kind = VisualCombatPalette.statusRingKind(processing: processing, disrupted: disrupted) else {
            node.childNode(withName: "status-ring")?.removeFromParent()
            return
        }
        let ring: SKShapeNode
        if let existing = node.childNode(withName: "status-ring") as? SKShapeNode {
            ring = existing
        } else {
            ring = SKShapeNode()
            ring.name = "status-ring"
            ring.zPosition = 4
            ring.fillColor = .clear
            node.addChild(ring)
        }
        ring.path = VisualCombatPalette.statusRingPath(kind: kind)
        ring.strokeColor = VisualCombatPalette.statusRingStroke(kind: kind)
        ring.lineWidth = VisualCombatPalette.statusRingLineWidth(kind: kind)
        // Silhouette + line weight carry status (SKShapeNode has no portable dash API here).
        ring.glowWidth = kind == .processing ? 1.5 : 0
        ring.isHidden = false
    }

    // Existing shape helpers — optional stroke keeps prior call sites valid.
    private func shape(circle radius: CGFloat, fill: SKColor, stroke: SKColor = .white) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        return node
    }

    private func shape(rect size: CGSize, radius: CGFloat, fill: SKColor, stroke: SKColor = .white) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        return node
    }
}
