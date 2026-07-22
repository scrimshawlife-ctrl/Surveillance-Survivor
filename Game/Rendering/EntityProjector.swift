import SpriteKit
import SurveillanceCore

@MainActor
final class EntityProjector {
    private var nodes: [UInt64: SKNode] = [:]
    private var nodeKinds: [UInt64: EntityKind] = [:]
    private var pool: [EntityKind: [SKNode]] = [:]

    func synchronize(entities: [Entity], in scene: SKScene) {
        let liveIDs = Set(entities.map(\.id))

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
            node.position = CGPoint(x: CGFloat(entity.position.x), y: CGFloat(entity.position.y))
            node.zRotation = entity.kind == .cameraPole ? CGFloat(entity.heading) : 0
            node.zPosition = entity.kind == .player ? 30 : 20
            updateAppearance(node, for: entity)
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
            return TextureAssetLoader.sprite(named: GameAssetName.Player.idleDown, size: CGSize(width: 54, height: 72)) ?? playerFallback()
        case .securityGuard:
            return shape(rect: CGSize(width: 24, height: 24), radius: 5, fill: .systemRed)
        case .cameraPole:
            return cameraNode()
        case .projectile:
            return shape(circle: 5, fill: .systemOrange, stroke: .clear)
        case .boss:
            return shape(rect: CGSize(width: 64, height: 64), radius: 12, fill: .systemPurple)
        case .extraction:
            return shape(circle: 60, fill: .cyan.withAlphaComponent(0.2), stroke: .cyan)
        case .mirrorArray:
            return shape(rect: CGSize(width: 48, height: 48), radius: 8, fill: .systemTeal)
        case .signalFlood:
            return shape(circle: 72, fill: .systemYellow.withAlphaComponent(0.18), stroke: .systemYellow)
        }
    }

    private func prepareForReuse(_ node: SKNode) {
        node.removeAllActions()
        node.position = .zero
        node.zRotation = 0
        node.alpha = 1
        node.isHidden = true
        node.name = nil
    }

    private func updateAppearance(_ node: SKNode, for entity: Entity) {
        guard entity.kind == .cameraPole else {
            if [.securityGuard, .boss].contains(entity.kind), let body = node as? SKShapeNode {
                let baseColor: SKColor = entity.kind == .boss ? .systemPurple : guardColor(for: entity.guardArchetype)
                body.fillColor = entity.processing == nil ? baseColor : .systemPurple
                body.strokeColor = entity.disruptedUntilTick == nil ? .white : .systemYellow
            }
            return
        }
        let bodyName: String
        if entity.health <= 0 {
            bodyName = GameAssetName.LPRCamera.destroyed
        } else if entity.health < 30 {
            bodyName = GameAssetName.LPRCamera.damaged
        } else {
            bodyName = GameAssetName.LPRCamera.intact
        }
        if let existing = node.childNode(withName: "body"), existing.userData?["asset"] as? String != bodyName {
            let replacement = cameraBody(named: bodyName, health: entity.health)
            replacement.name = "body"
            replacement.zPosition = existing.zPosition
            replacement.userData = NSMutableDictionary(dictionary: ["asset": bodyName])
            existing.removeFromParent()
            node.addChild(replacement)
        }

        guard let cone = node.childNode(withName: "scan-cone") as? SKShapeNode else { return }
        if entity.sensorDisabledUntilTick != nil || entity.disruptedUntilTick != nil {
            cone.isHidden = true
        } else if entity.sensorSpoof != nil {
            cone.isHidden = false
            cone.fillColor = .systemCyan.withAlphaComponent(0.1)
            cone.strokeColor = .systemCyan.withAlphaComponent(0.55)
        } else {
            cone.isHidden = false
            cone.fillColor = .systemRed.withAlphaComponent(0.12)
            cone.strokeColor = .systemRed.withAlphaComponent(0.45)
        }
    }

    private func cameraNode() -> SKNode {
        let container = SKNode()
        let body = cameraBody(named: GameAssetName.LPRCamera.intact, health: 60)
        body.name = "body"
        body.zPosition = 2
        body.userData = NSMutableDictionary(dictionary: ["asset": GameAssetName.LPRCamera.intact])
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

    private func cameraBody(named name: String, health: Double) -> SKNode {
        if let sprite = TextureAssetLoader.sprite(named: name, size: CGSize(width: 48, height: 96)) { return sprite }
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
