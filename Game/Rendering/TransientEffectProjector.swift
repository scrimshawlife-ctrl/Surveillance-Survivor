import SpriteKit
import SurveillanceCore

/// Plays world-space effect clips that belong to a moment rather than to an
/// entity's own appearance.
///
/// The four banks below shipped in #159 and never played, because nothing owned
/// them: they are not an entity's texture, so `EntityProjector` had nowhere to put
/// them. This projector spawns a short-lived node, runs the clip, and removes it.
///
/// Isolation: every trigger is an observed transition in authoritative state —
/// an entity appearing, health falling, a boss phase changing, a sensor going
/// dark. Nothing here produces simulation state, and no effect's presence,
/// position or frame index feeds back into hits, damage or timing. Effects are
/// purely decorative and may be dropped entirely without changing a run.
@MainActor
final class TransientEffectProjector {
    /// A clip that plays once at a fixed world position and then disappears.
    private struct Burst {
        let clip: AnimationClip
        let node: SKSpriteNode
        let start: TimeInterval
    }

    /// Where an effect sits relative to the entities it describes.
    private enum Depth {
        /// Under everything — the effect is part of the ground.
        case ground
        /// Over everything — the effect is happening to a body.
        case overlay

        var z: CGFloat {
            switch self {
            case .ground: VisualCombatLayers.groundEffect
            case .overlay: VisualCombatLayers.overlayEffect
            }
        }
    }

    /// A clip that loops on an entity for as long as a condition holds.
    private struct Attachment {
        let clip: AnimationClip
        let node: SKSpriteNode
        let start: TimeInterval
    }

    // Effect banks, with the canvases and playback modes recorded in
    // WEAPON_VFX_ASSET_MANIFEST. Sizes are world units, chosen so each effect
    // covers the thing it describes rather than the whole arena.
    private static let blindSpotOpen = AnimationClip(stem: GameAssetName.Effect.blindSpotOpen, playback: .oneShot, frameDuration: 0.07)
    private static let hardwareImpact = AnimationClip(stem: GameAssetName.Effect.hardwareImpact, playback: .oneShot, frameDuration: 0.06)
    private static let bossTelegraph = AnimationClip(stem: GameAssetName.Effect.bossTelegraphPrimary, playback: .oneShot, frameDuration: 0.08)
    private static let redactionField = AnimationClip(stem: GameAssetName.Effect.redactionField, playback: .loop, frameDuration: 0.11)

    // Sizes were first guessed against the manifest canvases and never checked in
    // play. Captured over a live camera kill, the 72-unit impact produced nothing
    // legible at satellite zoom — the effect fired correctly and could not be seen.
    // Scaled against what each effect describes: an impact reads on a 72x144 LPR
    // pole, a telegraph has to bracket a 108x135 boss, and the Blind Spot marks a
    // 120-unit extraction decal.
    private static let blindSpotSize = CGSize(width: 260, height: 260)
    private static let impactSize = CGSize(width: 150, height: 150)
    private static let telegraphSize = CGSize(width: 300, height: 300)
    private static let redactionSize = CGSize(width: 190, height: 190)

    /// Scene-graph name prefix for every effect node this projector owns.
    static let nodeNamePrefix = "effect-"

    private var bursts: [Burst] = []
    private var attachments: [UInt64: Attachment] = [:]
    private var lastHealth: [UInt64: Double] = [:]
    private var knownExtractionIDs: Set<UInt64> = []
    private var lastBossPhase: BossPhase?
    private var animationTime: TimeInterval = 0
    private var qualityTier: PresentationQualityTier = .full
    private var reducedFlash = false

    func applyPresentationSettings(_ settings: PresentationPipeline.PresentationSettings) {
        qualityTier = settings.tier
        reducedFlash = settings.reducedFlash
    }

    /// Drop every live effect — used when a run ends or a district changes so
    /// effects never outlive the scene that spawned them.
    func reset() {
        for burst in bursts { burst.node.removeFromParent() }
        for attachment in attachments.values { attachment.node.removeFromParent() }
        bursts.removeAll()
        attachments.removeAll()
        lastHealth.removeAll()
        knownExtractionIDs.removeAll()
        lastBossPhase = nil
    }

    func synchronize(
        entities: [Entity],
        bossPhase: BossPhase?,
        animationDelta: TimeInterval = 1.0 / 60.0,
        in scene: SKScene
    ) {
        animationTime += max(0, animationDelta)

        let live = Set(entities.map(\.id))
        detectTriggers(entities: entities, bossPhase: bossPhase, in: scene)
        advanceBursts()
        advanceAttachments(entities: entities, live: live)

        // Health is recorded last so the next frame compares against this one.
        for entity in entities { lastHealth[entity.id] = entity.health }
        lastHealth = lastHealth.filter { live.contains($0.key) }
    }

    // MARK: - Triggers

    private func detectTriggers(entities: [Entity], bossPhase: BossPhase?, in scene: SKScene) {
        for entity in entities {
            switch entity.kind {
            case .extraction:
                // The Blind Spot opening is the run's turning point, and the clip is a
                // one-time reveal — so it fires when the entity first appears, not
                // whenever `extractionOpen` happens to be true.
                if !knownExtractionIDs.contains(entity.id) {
                    knownExtractionIDs.insert(entity.id)
                    spawn(Self.blindSpotOpen, size: Self.blindSpotSize, depth: .overlay, at: entity.position, in: scene)
                }
            case .cameraPole:
                // Impact fires on an observed health decrease rather than on a hit
                // event, because the event carries no position and the effect has to
                // land on the hardware that was struck.
                if let previous = lastHealth[entity.id], entity.health < previous - 0.0001 {
                    spawn(Self.hardwareImpact, size: Self.impactSize, depth: .overlay, at: entity.position, in: scene)
                }
                syncRedactionField(for: entity, in: scene)
            case .boss:
                if let bossPhase, bossPhase != lastBossPhase {
                    spawn(Self.bossTelegraph, size: Self.telegraphSize, depth: .ground, at: entity.position, in: scene)
                }
            default:
                break
            }
        }
        // Recorded once per frame regardless of whether a boss is on the field, so a
        // phase change while the boss is absent cannot fire a stale telegraph later.
        lastBossPhase = bossPhase
        knownExtractionIDs = knownExtractionIDs.intersection(Set(entities.map(\.id)))
    }

    /// The redaction field is not a burst — `redactionOrdinance` disables a camera's
    /// sensors for a duration, so the field belongs to the camera for exactly as long
    /// as it stays dark.
    private func syncRedactionField(for entity: Entity, in scene: SKScene) {
        let disabled = entity.sensorDisabledUntilTick != nil
        if disabled, attachments[entity.id] == nil {
            guard let node = makeNode(Self.redactionField, size: Self.redactionSize, depth: .ground) else { return }
            node.position = CGPoint(x: CGFloat(entity.position.x), y: CGFloat(entity.position.y))
            scene.addChild(node)
            attachments[entity.id] = Attachment(clip: Self.redactionField, node: node, start: animationTime)
        } else if !disabled, let existing = attachments.removeValue(forKey: entity.id) {
            existing.node.removeFromParent()
        }
    }

    // MARK: - Playback

    private func advanceBursts() {
        var surviving: [Burst] = []
        surviving.reserveCapacity(bursts.count)
        for burst in bursts {
            let elapsed = animationTime - burst.start
            if AnimationClipCatalog.hasFinished(burst.clip, elapsed: elapsed) {
                burst.node.removeFromParent()
                continue
            }
            apply(burst.clip, to: burst.node, elapsed: elapsed)
            surviving.append(burst)
        }
        bursts = surviving
    }

    private func advanceAttachments(entities: [Entity], live: Set<UInt64>) {
        let positions = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0.position) })
        for (id, attachment) in attachments {
            guard live.contains(id) else {
                attachment.node.removeFromParent()
                attachments[id] = nil
                continue
            }
            if let position = positions[id] {
                attachment.node.position = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
            }
            apply(attachment.clip, to: attachment.node, elapsed: animationTime - attachment.start)
        }
    }

    private func apply(_ clip: AnimationClip, to node: SKSpriteNode, elapsed: TimeInterval) {
        let frame = AnimationClipCatalog.frameName(
            for: clip,
            elapsed: elapsed,
            holdStill: !qualityTier.advancesSpriteFrameCycles
        )
        guard node.userData?["asset"] as? String != frame,
              let image = TextureAssetLoader.image(named: frame) else { return }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        let size = node.size
        node.texture = texture
        // SpriteKit resets size to texture pixels on swap; effects must not resize
        // mid-clip or they read as the camera lurching.
        node.size = size
        let data = (node.userData as NSMutableDictionary?) ?? NSMutableDictionary()
        data["asset"] = frame
        node.userData = data
    }

    // MARK: - Nodes

    private func spawn(_ clip: AnimationClip, size: CGSize, depth: Depth, at position: Vector2, in scene: SKScene) {
        guard let node = makeNode(clip, size: size, depth: depth) else { return }
        node.position = CGPoint(x: CGFloat(position.x), y: CGFloat(position.y))
        scene.addChild(node)
        bursts.append(Burst(clip: clip, node: node, start: animationTime))
    }

    /// Returns nil when the bank is absent, so a missing effect is simply not drawn
    /// rather than drawn as a blank or a placeholder box.
    private func makeNode(_ clip: AnimationClip, size: CGSize, depth: Depth) -> SKSpriteNode? {
        guard OptionalSpriteFrameCycle.availableFrameCount(base: clip.stem) > 0,
              let image = TextureAssetLoader.image(named: clip.stem) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        let node = SKSpriteNode(texture: texture, size: size)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.zPosition = depth.z
        // These banks carry bright scan and spark content. Reduced flash keeps them
        // legible as motion without the luminance spike.
        // Ground effects sit under every entity and are read through them, so they
        // need more presence than an overlay burst that sits on top of the art.
        let baseAlpha: CGFloat = depth == .ground ? 0.95 : 0.9
        node.alpha = reducedFlash ? baseAlpha * 0.55 : baseAlpha
        // Named so effects are findable in the scene graph — for tests, and so a
        // stuck effect is identifiable in a debugger rather than an anonymous sprite.
        node.name = "\(Self.nodeNamePrefix)\(clip.stem)"
        node.userData = NSMutableDictionary(dictionary: ["asset": clip.stem])
        return node
    }
}
