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

        addParallax(behind: worldRect, district: district)
        fillTerrain(in: worldRect, district: district)
        projectObstacles(layout.obstacles, district: district)
        addParkingLines(to: root, bounds: layout.bounds)
        scatterDecals(in: worldRect, district: district)
        placeCityLandmarks(in: worldRect, district: district)
        renderedKey = key
    }

    private func addParallax(behind worldRect: CGRect, district: DistrictID) {
        let role = VisualAssetMap.skylineRole(for: district)
        guard let sprite = TextureAssetLoader.sprite(role: role)
                ?? TextureAssetLoader.sprite(role: .envParallaxSkyline) else { return }
        sprite.zPosition = -2
        sprite.alpha = 0.55
        sprite.position = CGPoint(x: worldRect.midX, y: worldRect.maxY + sprite.size.height * 0.15)
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
            var y = worldRect.minY
            while y < worldRect.maxY {
                var x = worldRect.minX
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

    private func projectObstacles(_ obstacles: [WorldObstacle], district: DistrictID) {
        let hangarAvailable = district == .wichita
            && TextureAssetLoader.isAvailable(GameAssetName.Wichita.landmarkHangar)
        let warehouseAvailable = district == .louisville
            && TextureAssetLoader.isAvailable(GameAssetName.Louisville.landmarkWarehouse)
        let useRetail = TextureAssetLoader.isAvailable(GameAssetName.Environment.obstacleRetailMass)
        for (index, obstacle) in obstacles.enumerated() {
            let size = CGSize(width: CGFloat(obstacle.halfSize.x * 2), height: CGFloat(obstacle.halfSize.y * 2))
            let position = CGPoint(x: CGFloat(obstacle.center.x), y: CGFloat(obstacle.center.y))
            if hangarAvailable, index.isMultiple(of: 2),
               let sprite = TextureAssetLoader.sprite(role: .wichitaLandmarkHangar) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if warehouseAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .louisvilleLandmarkWarehouse) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if useRetail, let sprite = TextureAssetLoader.sprite(role: .envObstacleRetailMass) {
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
        if let stamp = TextureAssetLoader.sprite(role: .envDecalSheet) {
            stamp.setScale(0.35)
            stamp.alpha = 0.22
            stamp.zPosition = 0.5
            stamp.position = CGPoint(x: worldRect.midX + 180, y: worldRect.midY - 120)
            root.addChild(stamp)
        }

        if district == .wichita {
            if let runway = TextureAssetLoader.sprite(role: .wichitaDecalRunwayStripe) {
                runway.alpha = 0.55
                runway.zPosition = 0.45
                runway.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 40)
                root.addChild(runway)
            }
            if let dust = TextureAssetLoader.sprite(role: .wichitaDecalGrainDust) {
                dust.alpha = 0.35
                dust.zPosition = 0.45
                dust.position = CGPoint(x: worldRect.maxX - 220, y: worldRect.minY + 180)
                root.addChild(dust)
            }
            if let shadow = TextureAssetLoader.sprite(role: .wichitaOverlayAircraftShadow) {
                shadow.alpha = 0.28
                shadow.zPosition = 0.7
                shadow.position = CGPoint(x: worldRect.midX - 100, y: worldRect.midY + 160)
                root.addChild(shadow)
            }
            if let radar = TextureAssetLoader.sprite(role: .wichitaOverlayRadarSweep) {
                radar.alpha = 0.18
                radar.zPosition = 0.75
                radar.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(radar)
            }
        }

        if district == .louisville {
            if let stain = TextureAssetLoader.sprite(role: .louisvilleDecalBourbonStain) {
                stain.alpha = 0.4
                stain.zPosition = 0.45
                stain.position = CGPoint(x: worldRect.midX - 160, y: worldRect.midY - 80)
                root.addChild(stain)
            }
            if let wet = TextureAssetLoader.sprite(role: .louisvilleDecalWetBrick) {
                wet.alpha = 0.35
                wet.zPosition = 0.45
                wet.position = CGPoint(x: worldRect.midX + 140, y: worldRect.midY + 60)
                root.addChild(wet)
            }
            if let haze = TextureAssetLoader.sprite(role: .louisvilleOverlayRiverHaze) {
                haze.alpha = 0.2
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 120)
                root.addChild(haze)
            }
            if let glint = TextureAssetLoader.sprite(role: .louisvilleOverlayHiddenCameraGlint) {
                glint.alpha = 0.22
                glint.zPosition = 0.8
                glint.position = CGPoint(x: worldRect.midX + 40, y: worldRect.midY + 40)
                root.addChild(glint)
            }
            if let redaction = TextureAssetLoader.sprite(role: .louisvilleOverlayMapRedaction) {
                redaction.alpha = 0.16
                redaction.zPosition = 0.85
                redaction.position = CGPoint(x: worldRect.maxX - 200, y: worldRect.maxY - 160)
                root.addChild(redaction)
            }
        }

        if district.definition.level <= 2,
           let prop = TextureAssetLoader.sprite(role: .envPropSheetRetail) {
            prop.setScale(0.28)
            prop.alpha = 0.55
            prop.zPosition = 0.6
            prop.position = CGPoint(x: worldRect.minX + 220, y: worldRect.maxY - 160)
            root.addChild(prop)
        }
    }

    private func placeCityLandmarks(in worldRect: CGRect, district: DistrictID) {
        if district == .wichita {
            if let monument = TextureAssetLoader.sprite(role: .wichitaLandmarkMonument) {
                monument.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 90)
                monument.zPosition = 1.2
                monument.alpha = 0.9
                root.addChild(monument)
            }
            if let elevators = TextureAssetLoader.sprite(role: .wichitaLandmarkGrainElevator) {
                elevators.position = CGPoint(x: worldRect.minX + 140, y: worldRect.maxY - 120)
                elevators.zPosition = 1.2
                root.addChild(elevators)
            }
            if let bridge = TextureAssetLoader.sprite(role: .wichitaLandmarkBridge) {
                bridge.position = CGPoint(x: worldRect.maxX - 200, y: worldRect.minY + 100)
                bridge.zPosition = 1.1
                root.addChild(bridge)
            }
            if let siren = TextureAssetLoader.sprite(role: .wichitaPropTornadoSiren) {
                siren.position = CGPoint(x: worldRect.maxX - 120, y: worldRect.maxY - 100)
                siren.zPosition = 1.3
                root.addChild(siren)
            }
            return
        }

        guard district == .louisville else { return }
        if let spires = TextureAssetLoader.sprite(role: .louisvilleLandmarkTwinSpires) {
            spires.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 90)
            spires.zPosition = 1.2
            root.addChild(spires)
        }
        if let river = TextureAssetLoader.sprite(role: .louisvilleLandmarkRiverfront) {
            river.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 90)
            river.zPosition = 1.1
            root.addChild(river)
        }
        if let victorian = TextureAssetLoader.sprite(role: .louisvilleLandmarkVictorian) {
            victorian.position = CGPoint(x: worldRect.minX + 130, y: worldRect.maxY - 140)
            victorian.zPosition = 1.2
            root.addChild(victorian)
        }
        if let gate = TextureAssetLoader.sprite(role: .louisvillePropIronGate) {
            gate.position = CGPoint(x: worldRect.maxX - 150, y: worldRect.midY)
            gate.zPosition = 1.15
            root.addChild(gate)
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
