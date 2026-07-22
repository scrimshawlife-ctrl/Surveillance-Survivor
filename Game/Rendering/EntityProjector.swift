import SpriteKit
import SurveillanceCore

final class EntityProjector {
    private var nodes: [UInt64: SKNode] = [:]

    func synchronize(entities: [Entity], in scene: SKScene) {
        let liveIDs = Set(entities.map(\.id))

        for (id, node) in nodes where !liveIDs.contains(id) {
            node.removeFromParent()
            nodes[id] = nil
        }

        for entity in entities {
            let node = nodes[entity.id] ?? makeNode(for: entity, in: scene)
            node.position = CGPoint(x: CGFloat(entity.position.x), y: CGFloat(entity.position.y))
            node.zRotation = entity.kind == .cameraPole ? CGFloat(entity.heading) : 0
            node.zPosition = entity.kind == .player ? 30 : 20
            updateAppearance(node, for: entity)
        }
    }

    private func makeNode(for entity: Entity, in scene: SKScene) -> SKNode {
        let node: SKNode
        switch entity.kind {
        case .player:
            node = TextureAssetLoader.sprite(named: GameAssetName.Player.idleDown, size: CGSize(width: 54, height: 72)) ?? playerFallback()
        case .securityGuard:
            node = shape(rect: CGSize(width: 24, height: 24), radius: 5, fill: .systemRed)
        case .cameraPole:
            node = cameraNode()
        case .projectile:
            node = shape(circle: 5, fill: .systemOrange, stroke: .clear)
        case .boss:
            node = shape(rect: CGSize(width: 64, height: 64), radius: 12, fill: .systemPurple)
        case .extraction:
            node = shape(circle: 60, fill: .cyan.withAlphaComponent(0.2), stroke: .cyan)
        }

        node.name = "entity-\(entity.id)"
        scene.addChild(node)
        nodes[entity.id] = node
        return node
    }

    private func updateAppearance(_ node: SKNode, for entity: Entity) {
        guard entity.kind == .cameraPole else { return }
        let bodyName: String
        if entity.health <= 0 {
            bodyName = GameAssetName.LPRCamera.destroyed
        } else if entity.health < 30 {
            bodyName = GameAssetName.LPRCamera.damaged
        } else {
            bodyName = GameAssetName.LPRCamera.intact
        }
        node.childNode(withName: "body")?.userData = NSMutableDictionary(dictionary: ["asset": bodyName])
    }

    private func cameraNode() -> SKNode {
        let container = SKNode()
        let body = TextureAssetLoader.sprite(named: GameAssetName.LPRCamera.intact, size: CGSize(width: 48, height: 96)) ?? shape(rect: CGSize(width: 14, height: 46), radius: 3, fill: .systemYellow)
        body.name = "body"
        body.zPosition = 2
        container.addChild(body)

        let cone = SKShapeNode(path: scanConePath())
        cone.name = "scan-cone"
        cone.fillColor = .systemRed.withAlphaComponent(0.12)
        cone.strokeColor = .systemRed.withAlphaComponent(0.45)
        cone.lineWidth = 1
        cone.zPosition = 1
        container.addChild(cone)
        return container
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

    private func shape(circle radius: CGFloat, fill: SKColor, stroke: SKColor = .white) -> SKShapeNode {
        let node = SKShapeNode(circleOfRadius: radius)
        node.fillColor = fill
        node.strokeColor = stroke
        return node
    }

    private func shape(rect size: CGSize, radius: CGFloat, fill: SKColor) -> SKShapeNode {
        let node = SKShapeNode(rectOf: size, cornerRadius: radius)
        node.fillColor = fill
        node.strokeColor = .white
        return node
    }
}
