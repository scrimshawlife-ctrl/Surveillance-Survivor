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
        in scene: SKScene
    ) {
        animationTime += max(0, animationDelta)

        let liveIDs = Set(entities.map(\.id))
        // Density soft-out uses existing quality ladder + CombatLimits calibration.
        let densityScale = qualityTier.densityScale(entityCount: entities.count)

        for (id, node) in nodes where !liveIDs.contains(id) {
            node.removeFromParent()
            if let kind = nodeKinds[id] {
                prepareForReuse(node)
                pool[kind, default: []].append(node)
            }
            nodes[id] = nil
            nodeKinds[id] = nil
        }

        for entity in entities {
            let node = nodes[entity.id] ?? acquireNode(for: entity, in: scene)
            let sample = display[entity.id]
            if let sample {
                node.position = sample.position
                if entity.kind == .cameraPole {
                    node.zRotation = sample.heading
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
                node.zRotation = entity.kind == .cameraPole ? CGFloat(entity.heading) : 0
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
        }
    }

    private func acquireNode(for entity: Entity, in scene: SKScene) -> SKNode {
        let node = pool[entity.kind]?.popLast() ?? makeNode(for: entity.kind)
        node.name = "entity-\(entity.id)"
        node.isHidden = false
        node.alpha = 1
        scene.addChild(node)
        nodes[entity.id] = node
        nodeKinds[entity.id] = entity.kind
        return node
    }

    private func makeNode(for kind: EntityKind) -> SKNode {
        switch kind {
        case .player:
            return TextureAssetLoader.sprite(role: .playerIdleDown) ?? playerFallback()
        case .securityGuard:
            // Archetype texture swapped in updateAppearance; start with default skin.
            return TextureAssetLoader.sprite(named: GameAssetName.Guard.default, size: CGSize(width: 40, height: 52), anchor: CGPoint(x: 0.5, y: 0.12))
                ?? TextureAssetLoader.sprite(role: .guardDefault)
                ?? shape(rect: CGSize(width: 24, height: 24), radius: 5, fill: .systemRed)
        case .cameraPole:
            return cameraNode()
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

    private func prepareForReuse(_ node: SKNode) {
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
                let frameName = PlayerAtlasManifest.frameName(baseAsset: baseName, at: animationTime)
                if sprite.userData?["asset"] as? String != frameName,
                   let image = TextureAssetLoader.image(named: frameName)
                    ?? TextureAssetLoader.image(named: baseName) {
                    let texture = SKTexture(image: image)
                    texture.filteringMode = .nearest
                    sprite.texture = texture
                    sprite.userData = NSMutableDictionary(dictionary: ["asset": frameName])
                }
                sprite.alpha = integrity <= 0 ? 0.35 : integrity < 30 ? 0.75 : 1
            } else {
                node.alpha = integrity <= 0 ? 0.35 : integrity < 30 ? 0.75 : 1
            }
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
                        body.strokeColor = entity.disruptedUntilTick == nil ? .white : VisualCombatPalette.disruptTint
                    }
                } else if let sprite = node as? SKSpriteNode {
                    if entity.kind == .securityGuard {
                        applyGuardAppearance(sprite, for: entity)
                    } else if entity.kind == .boss {
                        applyBossAppearance(sprite)
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
        let bodyName = VisualAssetMap.assetName(lprRole)
        if let existing = node.childNode(withName: "body"), existing.userData?["asset"] as? String != bodyName {
            let replacement = cameraBody(role: lprRole, health: entity.health)
            replacement.name = "body"
            replacement.zPosition = existing.zPosition
            replacement.userData = NSMutableDictionary(dictionary: ["asset": bodyName])
            existing.removeFromParent()
            node.addChild(replacement)
        }
        if let accent = node.childNode(withName: "sensor-accent") as? SKShapeNode {
            accent.fillColor = sensorColor(for: entity.sensorArchetype)
            accent.strokeColor = entity.disruptedUntilTick == nil ? .white : .systemYellow
        }

        guard let cone = node.childNode(withName: "scan-cone") as? SKShapeNode else { return }
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

    private func cameraNode() -> SKNode {
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

        let cone = SKShapeNode(path: scanConePath())
        cone.name = "scan-cone"
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

    private func scanConePath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 390, y: -100))
        path.addArc(center: .zero, radius: 403, startAngle: -.pi / 7, endAngle: .pi / 7, clockwise: false)
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
        let frameName = OptionalSpriteFrameCycle.frameName(base: baseName, at: animationTime)
        if sprite.userData?["asset"] as? String != frameName,
           let image = TextureAssetLoader.image(named: frameName)
            ?? TextureAssetLoader.image(named: baseName)
            ?? TextureAssetLoader.image(named: GameAssetName.Guard.default) {
            let texture = SKTexture(image: image)
            texture.filteringMode = .nearest
            sprite.texture = texture
            sprite.userData = NSMutableDictionary(dictionary: ["asset": frameName])
        }
    }

    /// Boss still + optional multi-frame bank when `boss_default_2…` inventory exists.
    private func applyBossAppearance(_ sprite: SKSpriteNode) {
        let baseName = GameAssetName.Boss.default
        let frameName = OptionalSpriteFrameCycle.frameName(base: baseName, at: animationTime)
        if sprite.userData?["asset"] as? String != frameName,
           let image = TextureAssetLoader.image(named: frameName)
            ?? TextureAssetLoader.image(named: baseName) {
            let texture = SKTexture(image: image)
            texture.filteringMode = .nearest
            sprite.texture = texture
            sprite.userData = NSMutableDictionary(dictionary: ["asset": frameName])
        }
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
                let texture = SKTexture(image: image)
                texture.filteringMode = .nearest
                sprite.texture = texture
                sprite.userData = NSMutableDictionary(dictionary: ["asset": assetName])
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
                let texture = SKTexture(image: image)
                texture.filteringMode = .nearest
                sprite.texture = texture
                sprite.userData = NSMutableDictionary(dictionary: ["asset": assetName])
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
