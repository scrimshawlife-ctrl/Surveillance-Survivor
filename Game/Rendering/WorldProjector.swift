import SpriteKit
import SurveillanceCore

final class WorldProjector {
    private let root = SKNode()
    private var renderedLayout: WorldLayout?

    func synchronize(layout: WorldLayout, in scene: SKScene) {
        guard renderedLayout != layout else { return }
        root.removeAllChildren()
        if root.parent == nil {
            root.zPosition = 0
            scene.addChild(root)
        }

        let worldRect = CGRect(
            x: CGFloat(layout.bounds.minX),
            y: CGFloat(layout.bounds.minY),
            width: CGFloat(layout.bounds.maxX - layout.bounds.minX),
            height: CGFloat(layout.bounds.maxY - layout.bounds.minY)
        )
        let asphalt = SKShapeNode(rect: worldRect)
        asphalt.fillColor = SKColor(white: 0.12, alpha: 1)
        asphalt.strokeColor = SKColor(white: 0.4, alpha: 1)
        asphalt.lineWidth = 4
        root.addChild(asphalt)

        for obstacle in layout.obstacles {
            let size = CGSize(width: CGFloat(obstacle.halfSize.x * 2), height: CGFloat(obstacle.halfSize.y * 2))
            let node = SKShapeNode(rectOf: size, cornerRadius: 12)
            node.position = CGPoint(x: CGFloat(obstacle.center.x), y: CGFloat(obstacle.center.y))
            node.fillColor = SKColor(white: 0.24, alpha: 1)
            node.strokeColor = .systemYellow.withAlphaComponent(0.55)
            node.lineWidth = 3
            root.addChild(node)
        }

        addParkingLines(to: root, bounds: layout.bounds)
        renderedLayout = layout
    }

    private func addParkingLines(to root: SKNode, bounds: WorldBounds) {
        for x in stride(from: bounds.minX + 90, through: bounds.maxX - 90, by: 90) {
            let line = SKShapeNode(rectOf: CGSize(width: 3, height: 72))
            line.position = CGPoint(x: CGFloat(x), y: 0)
            line.fillColor = .white.withAlphaComponent(0.24)
            line.strokeColor = .clear
            root.addChild(line)
        }
    }
}
