import SpriteKit
import SurveillanceCore

/// Presentation-only player trail for the Lot Ghost cosmetic unlock.
/// Soft afterimage dots — no combat effect, no system particles required.
@MainActor
final class GhostTrailPresenter {
    private let root = SKNode()
    private var crumbs: [SKShapeNode] = []
    private var lastDrop = CGPoint.zero
    private var enabled = false
    private let maxCrumbs = 22
    private let dropDistance: CGFloat = 12

    func setEnabled(_ on: Bool, in scene: SKScene) {
        enabled = on
        if on {
            if root.parent == nil {
                root.zPosition = VisualCombatLayers.ghostTrail
                root.name = "ghost-trail-root"
                scene.addChild(root)
            }
        } else {
            clear()
            root.removeFromParent()
        }
    }

    func clear() {
        crumbs.forEach { $0.removeFromParent() }
        crumbs.removeAll()
        lastDrop = .zero
    }

    /// Call each render frame with the player's display position.
    func update(playerPosition: CGPoint, reducedMotion: Bool) {
        guard enabled else { return }
        if reducedMotion {
            // Single soft marker under feet only.
            if crumbs.isEmpty {
                let node = makeCrumb(at: playerPosition, alpha: 0.22, radius: 5)
                root.addChild(node)
                crumbs.append(node)
            } else {
                crumbs[0].position = playerPosition
            }
            return
        }

        let dx = playerPosition.x - lastDrop.x
        let dy = playerPosition.y - lastDrop.y
        let dist = (dx * dx + dy * dy).squareRoot()
        guard dist >= dropDistance || crumbs.isEmpty else {
            fadeCrumbs()
            return
        }
        lastDrop = playerPosition
        let node = makeCrumb(at: playerPosition, alpha: 0.35, radius: 4.5)
        root.addChild(node)
        crumbs.append(node)
        if crumbs.count > maxCrumbs {
            let old = crumbs.removeFirst()
            old.removeFromParent()
        }
        fadeCrumbs()
    }

    private func fadeCrumbs() {
        let count = max(crumbs.count, 1)
        for (index, crumb) in crumbs.enumerated() {
            let t = CGFloat(index + 1) / CGFloat(count)
            crumb.alpha = 0.08 + 0.28 * t
            let scale = 0.55 + 0.45 * t
            crumb.setScale(scale)
        }
    }

    private func makeCrumb(at position: CGPoint, alpha: CGFloat, radius: CGFloat) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.position = position
        // Cool cyan-gray ghost — satirical lot-ghost, not neon party trail.
        node.fillColor = SKColor(red: 0.45, green: 0.72, blue: 0.78, alpha: alpha)
        node.strokeColor = SKColor(red: 0.55, green: 0.85, blue: 0.9, alpha: alpha * 0.5)
        node.lineWidth = 0.8
        node.zPosition = 0
        node.glowWidth = 0
        node.name = "ghost-trail-crumb"
        return node
    }
}
