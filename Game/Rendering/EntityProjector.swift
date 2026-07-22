import SpriteKit
import SurveillanceCore

final class EntityProjector {
    private var nodes: [UInt64: SKShapeNode] = [:]

    func synchronize(entities: [Entity], in scene: SKScene) {
        let liveIDs = Set(entities.map(\.id))

        for (id, node) in nodes where !liveIDs.contains(id) {
            node.removeFromParent()
            nodes[id] = nil
        }

        for entity in entities {
            let node = nodes[entity.id] ?? makeNode(for: entity, in: scene)
            node.position = CGPoint(
                x: CGFloat(entity.position.x),
                y: CGFloat(entity.position.y)
            )
            node.zPosition = entity.kind == .player ? 20 : 10
        }
    }

    private func makeNode(for entity: Entity, in scene: SKScene) -> SKShapeNode {
        let node: SKShapeNode
        switch entity.kind {
        case .player:
            node = SKShapeNode(circleOfRadius: 18)
            node.fillColor = .white
            node.strokeColor = .cyan
        case .securityGuard:
            node = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 5)
            node.fillColor = .systemRed
            node.strokeColor = .white
        case .cameraPole:
            node = SKShapeNode(rectOf: CGSize(width: 12, height: 38), cornerRadius: 3)
            node.fillColor = .systemYellow
            node.strokeColor = .white
        case .projectile:
            node = SKShapeNode(circleOfRadius: 5)
            node.fillColor = .systemOrange
            node.strokeColor = .clear
        case .boss:
            node = SKShapeNode(rectOf: CGSize(width: 64, height: 64), cornerRadius: 12)
            node.fillColor = .systemPurple
            node.strokeColor = .white
        case .extraction:
            node = SKShapeNode(circleOfRadius: 60)
            node.fillColor = .cyan.withAlphaComponent(0.2)
            node.strokeColor = .cyan
        }

        node.name = "entity-\(entity.id)"
        scene.addChild(node)
        nodes[entity.id] = node
        return node
    }
}
