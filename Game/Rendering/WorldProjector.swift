import SpriteKit
import SurveillanceCore

/// Projects world layout only. Never owns collision or gameplay truth.
@MainActor
final class WorldProjector {
    private let root = SKNode()
    private var renderedKey: String?

    func synchronize(layout: WorldLayout, district: DistrictID, in scene: SKScene) {
        let key = "\(district.rawValue)|\(layout.bounds.minX),\(layout.bounds.minY),\(layout.bounds.maxX),\(layout.bounds.maxY)|\(layout.obstacles.count)"
        guard renderedKey != key else { return }
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

        addParallax(behind: worldRect)
        fillTerrain(in: worldRect, district: district)
        projectObstacles(layout.obstacles)
        addParkingLines(to: root, bounds: layout.bounds)
        scatterDecals(in: worldRect, district: district)
        renderedKey = key
    }

    private func addParallax(behind worldRect: CGRect) {
        guard let sprite = TextureAssetLoader.sprite(role: .envParallaxSkyline) else { return }
        sprite.zPosition = -2
        sprite.alpha = 0.55
        sprite.position = CGPoint(x: worldRect.midX, y: worldRect.maxY + sprite.size.height * 0.15)
        // Stretch lightly to span wide districts without claiming gameplay space.
        let targetWidth = max(worldRect.width * 0.85, sprite.size.width)
        sprite.size = CGSize(width: targetWidth, height: sprite.size.height * (targetWidth / max(sprite.size.width, 1)))
        root.addChild(sprite)
    }

    private func fillTerrain(in worldRect: CGRect, district: DistrictID) {
        let role = VisualAssetMap.terrainRole(for: district)
        if let image = TextureAssetLoader.image(named: VisualAssetMap.assetName(role)) {
            let texture = SKTexture(image: image)
            texture.filteringMode = .nearest
            let tileSize: CGFloat = 256
            let startX = worldRect.minX
            let startY = worldRect.minY
            var y = startY
            while y < worldRect.maxY {
                var x = startX
                while x < worldRect.maxX {
                    let node = SKSpriteNode(texture: texture, size: CGSize(width: tileSize, height: tileSize))
                    node.anchorPoint = CGPoint(x: 0, y: 0)
                    node.position = CGPoint(x: x, y: y)
                    node.zPosition = 0
                    root.addChild(node)
                    x += tileSize
                }
                y += tileSize
            }
            return
        }

        let asphalt = SKShapeNode(rect: worldRect)
        asphalt.fillColor = SKColor(white: 0.12, alpha: 1)
        asphalt.strokeColor = SKColor(white: 0.4, alpha: 1)
        asphalt.lineWidth = 4
        asphalt.zPosition = 0
        root.addChild(asphalt)
    }

    private func projectObstacles(_ obstacles: [WorldObstacle]) {
        let useTexture = TextureAssetLoader.isAvailable(GameAssetName.Environment.obstacleRetailMass)
        for obstacle in obstacles {
            let size = CGSize(width: CGFloat(obstacle.halfSize.x * 2), height: CGFloat(obstacle.halfSize.y * 2))
            let position = CGPoint(x: CGFloat(obstacle.center.x), y: CGFloat(obstacle.center.y))
            if useTexture, let sprite = TextureAssetLoader.sprite(role: .envObstacleRetailMass) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else {
                let node = SKShapeNode(rectOf: size, cornerRadius: 12)
                node.position = position
                node.fillColor = SKColor(white: 0.24, alpha: 1)
                node.strokeColor = .systemYellow.withAlphaComponent(0.55)
                node.lineWidth = 3
                node.zPosition = 1
                root.addChild(node)
            }
        }
    }

    private func scatterDecals(in worldRect: CGRect, district: DistrictID) {
        // Lightweight readable markers only — never clutter movement. Uses the
        // decal sheet as a soft watermark stamp when present.
        guard TextureAssetLoader.isAvailable(GameAssetName.Environment.decalSheet),
              let stamp = TextureAssetLoader.sprite(role: .envDecalSheet) else { return }
        stamp.setScale(0.35)
        stamp.alpha = 0.22
        stamp.zPosition = 0.5
        stamp.position = CGPoint(x: worldRect.midX + 180, y: worldRect.midY - 120)
        root.addChild(stamp)

        if district.definition.level == 1,
           let prop = TextureAssetLoader.sprite(role: .envPropSheetRetail) {
            prop.setScale(0.28)
            prop.alpha = 0.55
            prop.zPosition = 0.6
            prop.position = CGPoint(x: worldRect.minX + 220, y: worldRect.maxY - 160)
            root.addChild(prop)
        }
    }

    private func addParkingLines(to root: SKNode, bounds: WorldBounds) {
        for x in stride(from: bounds.minX + 90, through: bounds.maxX - 90, by: 90) {
            let line = SKShapeNode(rectOf: CGSize(width: 3, height: 72))
            line.position = CGPoint(x: CGFloat(x), y: 0)
            line.fillColor = .white.withAlphaComponent(0.24)
            line.strokeColor = .clear
            line.zPosition = 0.4
            root.addChild(line)
        }
    }
}
