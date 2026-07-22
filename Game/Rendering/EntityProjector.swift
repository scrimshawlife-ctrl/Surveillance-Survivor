import SpriteKit

final class EntityProjector {
    private var nodes: [Int: SKShapeNode] = [:]

    func synchronize(entities: [Entity], in scene: SKScene) {
        let liveIDs = Set(entities.map(\.id))

        for (id, node) in nodes where !liveIDs.contains(id) {
            node.removeFromParent()
            nodes[id] = nil
        }

        for entity in entities {
            let node = nodes[entity.id] ?? makeNode(for: entity, in: scene)
            node.position = CGPoint(x: entity.position.x, y: entity.position.y)
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
        case .security:
            node = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 5)
            node.fillColor = .systemRed
            node.strokeColor = .white
        }

        node.name = "entity-\(entity.id)"
        scene.addChild(node)
        nodes[entity.id] = node
        return node
    }
}
