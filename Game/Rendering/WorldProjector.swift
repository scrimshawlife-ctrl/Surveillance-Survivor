import SpriteKit
import SurveillanceCore

/// Projects world layout only. Never owns collision or gameplay truth.
@MainActor
final class WorldProjector {
    struct CityOverlayPresentation {
        /// Calmed so wayfinding doesn't wallpaper the arena (operator: floors too busy).
        static let standardAlpha: CGFloat = 0.72
        static let reducedFlashAlpha: CGFloat = 0.52
        static let phoneMinimumLabelSize: CGFloat = 15

        let reducedFlash: Bool

        var overlayAlpha: CGFloat { reducedFlash ? Self.reducedFlashAlpha : Self.standardAlpha }
        var labelFontSize: CGFloat { Self.phoneMinimumLabelSize }
    }

    private let root = SKNode()
    private var renderedKey: String?

    func synchronize(
        layout: WorldLayout,
        district: DistrictID,
        landmark: LandmarkEncounterState = .idle,
        districtState: DistrictState? = nil,
        reducedFlash: Bool = false,
        in scene: SKScene
    ) {
        let stateKey = districtState?.nodes
            .map { "\($0.id):\(Int(($0.integrity * 100).rounded()))" }
            .joined(separator: ",") ?? "-"
        let key = "\(district.rawValue)|\(layout.bounds.minX),\(layout.bounds.minY),\(layout.bounds.maxX),\(layout.bounds.maxY)|\(layout.obstacles.count)|\(landmark.isPlayerInside)|\(landmark.activeEncounterId ?? "-")|\(stateKey)|reducedFlash:\(reducedFlash)"
        guard renderedKey != key else {
            // Light update of zone highlight without full rebuild.
            updateLandmarkZone(district: district, landmark: landmark)
            return
        }
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
        if VisualAssetMap.usesParkingLotMarks(for: district) {
            addParkingLines(to: root, bounds: layout.bounds)
        } else {
            addLaneTicks(to: root, bounds: layout.bounds, district: district)
        }
        addCityWayfinding(
            in: worldRect,
            district: district,
            state: districtState,
            presentation: CityOverlayPresentation(reducedFlash: reducedFlash)
        )
        scatterDecals(in: worldRect, district: district)
        placeCityLandmarks(in: worldRect, district: district)
        placeLandmarkZone(district: district, landmark: landmark)
        addFloorEdgeVignette(in: worldRect)
        // Cap landmark opacity/size after placement so city props stay secondary to playfield.
        for case let sprite as SKSpriteNode in root.children where sprite.zPosition >= 1.1 {
            calmLandmark(sprite)
        }
        renderedKey = key
    }

    /// Soft cyan ring for P9 landmark set piece (presentation only; sim owns truth).
    private func placeLandmarkZone(district: DistrictID, landmark: LandmarkEncounterState) {
        guard let encounter = LandmarkEncounterCatalog.bundled.primary(for: district) else { return }
        let ring = SKShapeNode(circleOfRadius: CGFloat(encounter.radius))
        ring.name = "landmark-zone"
        ring.position = CGPoint(x: CGFloat(encounter.center.x), y: CGFloat(encounter.center.y))
        // Dim cyan (not Blind Spot extraction cyan); under combat entities.
        ring.strokeColor = VisualCombatPalette.landmarkZoneStroke(inside: landmark.isPlayerInside)
        ring.fillColor = VisualCombatPalette.landmarkZoneFill(inside: landmark.isPlayerInside)
        ring.lineWidth = landmark.isPlayerInside ? 2.5 : 1.25
        ring.zPosition = VisualCombatLayers.landmarkZone
        ring.glowWidth = 0
        root.addChild(ring)
    }

    private func updateLandmarkZone(district: DistrictID, landmark: LandmarkEncounterState) {
        guard let ring = root.childNode(withName: "landmark-zone") as? SKShapeNode else { return }
        ring.strokeColor = VisualCombatPalette.landmarkZoneStroke(inside: landmark.isPlayerInside)
        ring.fillColor = VisualCombatPalette.landmarkZoneFill(inside: landmark.isPlayerInside)
        ring.lineWidth = landmark.isPlayerInside ? 2.5 : 1.25
        _ = district
    }

    private func addParallax(behind worldRect: CGRect, district: DistrictID) {
        let role = VisualAssetMap.skylineRole(for: district)
        guard let sprite = TextureAssetLoader.sprite(role: role)
                ?? TextureAssetLoader.sprite(role: .envParallaxSkyline) else { return }
        sprite.zPosition = -2
        // Keep skyline as a soft band — full-strength art drowns the playfield.
        sprite.alpha = 0.28
        sprite.position = CGPoint(x: worldRect.midX, y: worldRect.maxY + sprite.size.height * 0.12)
        let targetWidth = max(worldRect.width * 0.75, sprite.size.width * 0.9)
        sprite.size = CGSize(width: targetWidth, height: sprite.size.height * (targetWidth / max(sprite.size.width, 1)))
        root.addChild(sprite)
    }

    private func fillTerrain(in worldRect: CGRect, district: DistrictID) {
        // City identity first via base tint (readable, calm). Texture stamps are
        // sparse watermarks — dense dual-layer wallpaper made arenas too busy and
        // washed out city accuracy (operator 2026-08-02).
        let base = asphaltBaseColor(for: district)
        let asphalt = SKShapeNode(rect: worldRect)
        asphalt.fillColor = base
        asphalt.strokeColor = SKColor(white: 0.2, alpha: 0.28)
        asphalt.lineWidth = 1
        asphalt.zPosition = 0
        root.addChild(asphalt)

        // Primary city terrain — large sparse stamps, low alpha (open combat arena).
        stampTerrainLayer(
            role: VisualAssetMap.terrainRole(for: district),
            district: district,
            in: worldRect,
            baseSize: 400,
            alpha: 0.14,
            z: 0.05,
            phase: 0,
            coverage: .sparse
        )
        // Secondary terrain only as edge accents (not a second full carpet).
        if let secondary = VisualAssetMap.secondaryTerrainRole(for: district) {
            stampTerrainLayer(
                role: secondary,
                district: district,
                in: worldRect,
                baseSize: 480,
                alpha: 0.09,
                z: 0.06,
                phase: 1,
                coverage: .edgeAccents
            )
        }
    }

    private enum TerrainCoverage {
        /// Open arena: wider spacing, fewer stamps.
        case sparse
        /// Secondary city cue only at edges (N/S/E/W).
        case edgeAccents
    }

    /// District asphalt tint from city identity (presentation only).
    private func asphaltBaseColor(for district: DistrictID) -> SKColor {
        // Keep playfield dark for combat; push ΔL / hue enough that cities read
        // without dense texture (prairie warm vs brick cool vs industrial amber…).
        switch district {
        case .wichita:
            return SKColor(red: 0.19, green: 0.185, blue: 0.17, alpha: 1) // dry prairie asphalt
        case .louisville:
            return SKColor(red: 0.14, green: 0.145, blue: 0.175, alpha: 1) // wet brick cool
        case .tulsa:
            return SKColor(red: 0.195, green: 0.155, blue: 0.14, alpha: 1) // oil warm industrial
        case .dayton:
            return SKColor(red: 0.145, green: 0.17, blue: 0.195, alpha: 1) // overcast research blue-gray
        case .oakland:
            return SKColor(red: 0.135, green: 0.165, blue: 0.185, alpha: 1) // marine cool
        case .sanFrancisco:
            return SKColor(red: 0.14, green: 0.155, blue: 0.195, alpha: 1) // fog cool
        case .columbus:
            return SKColor(red: 0.125, green: 0.125, blue: 0.135, alpha: 1) // fluorescent civic charcoal
        case .newYorkCity:
            return SKColor(red: 0.14, green: 0.15, blue: 0.185, alpha: 1) // wet avenue cool
        case .losAngeles:
            return SKColor(red: 0.175, green: 0.155, blue: 0.13, alpha: 1) // sunbleached warm
        case .atlanta:
            return SKColor(red: 0.13, green: 0.155, blue: 0.145, alpha: 1) // humid canopy green-gray
        }
    }

    /// Terrain stamps — sparse arena coverage or edge-only secondary accents.
    private func stampTerrainLayer(
        role: VisualAssetMap.Role,
        district: DistrictID,
        in worldRect: CGRect,
        baseSize: CGFloat,
        alpha: CGFloat,
        z: CGFloat,
        phase: Int,
        coverage: TerrainCoverage
    ) {
        guard let image = TextureAssetLoader.image(named: VisualAssetMap.assetName(role)) else { return }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear

        switch coverage {
        case .edgeAccents:
            // Four large soft stamps at edges — secondary city grammar without mid-field noise.
            let salt = presentationSalt(district: district, worldRect: worldRect) &+ UInt64(phase)
            let biases: [DecalBias] = [.north, .south, .centerEast, .southWest]
            for (index, bias) in biases.enumerated() {
                let size = baseSize * (index % 2 == 0 ? 1.0 : 0.88)
                let node = SKSpriteNode(texture: texture, size: CGSize(width: size, height: size))
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                node.position = jitteredPoint(in: worldRect, salt: salt, index: index + 20, bias: bias)
                node.zRotation = CGFloat((index % 3) - 1) * 0.02
                node.zPosition = z
                node.alpha = alpha
                root.addChild(node)
            }
        case .sparse:
            let sizes: [CGFloat] = [baseSize, baseSize * 1.12, baseSize * 0.9]
            // Wider step → open center for combat readability.
            let xStepFactor: CGFloat = 1.05
            let yStepFactor: CGFloat = 0.98
            var row = 0
            var y = worldRect.minY - baseSize * 0.1
            while y < worldRect.maxY + baseSize * 0.15 {
                var col = 0
                let rowOffset = CGFloat(row % 2) * (baseSize * 0.35)
                var x = worldRect.minX - baseSize * 0.15 + rowOffset
                while x < worldRect.maxX + baseSize * 0.15 {
                    // Skip every other cell on even rows to keep mid-field open.
                    if (row + col) % 2 == 0 || row % 3 == 0 {
                        let size = sizes[(row + col) % sizes.count]
                        let node = SKSpriteNode(texture: texture, size: CGSize(width: size, height: size))
                        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                        node.position = CGPoint(x: x + size * 0.5, y: y + size * 0.5)
                        let twist = CGFloat(((row * 3 + col * 5) % 5) - 2) * 0.01
                        node.zRotation = twist
                        node.zPosition = z
                        node.alpha = alpha
                        root.addChild(node)
                    }
                    x += baseSize * xStepFactor
                    col += 1
                }
                y += baseSize * yStepFactor
                row += 1
            }
        }
    }

    /// Soft edge falloff so the playfield recedes at bounds (Hallmark m3).
    private func addFloorEdgeVignette(in worldRect: CGRect) {
        let frame = SKShapeNode(rect: worldRect)
        frame.fillColor = .clear
        frame.strokeColor = SKColor(white: 0, alpha: 0.35)
        frame.lineWidth = max(48, min(worldRect.width, worldRect.height) * 0.06)
        frame.glowWidth = 18
        frame.zPosition = 0.08
        frame.name = "floor-edge-vignette"
        root.addChild(frame)
    }

    private func projectObstacles(_ obstacles: [WorldObstacle], district: DistrictID) {
        // Collision pads are city-tinted blocks. Do NOT squash landmark illustrations
        // onto pad AABBs — that made buildings look broken (wrong crop, busy mid-field).
        // Optional retail mass is the only pad skin; city landmarks stay perimeter-only.
        let useRetail = TextureAssetLoader.isAvailable(GameAssetName.Environment.obstacleRetailMass)
        let padColor = obstaclePadColor(for: district)

        for (index, obstacle) in obstacles.enumerated() {
            let size = CGSize(width: CGFloat(obstacle.halfSize.x * 2), height: CGFloat(obstacle.halfSize.y * 2))
            let position = CGPoint(x: CGFloat(obstacle.center.x), y: CGFloat(obstacle.center.y))

            let pad = SKShapeNode(rectOf: size, cornerRadius: min(8, min(size.width, size.height) * 0.1))
            pad.name = "obstacle-pad"
            pad.position = position
            pad.fillColor = padColor
            pad.strokeColor = SKColor(white: 0.08, alpha: 0.55)
            pad.lineWidth = 1
            pad.zPosition = 1
            root.addChild(pad)

            // Sparse block skin only — not every pad, not city landmark plates.
            if useRetail, index.isMultiple(of: 4),
               let sprite = TextureAssetLoader.sprite(role: .envObstacleRetailMass)
            {
                fitSprite(sprite, inside: size, at: position, z: 1.05, alpha: 0.45)
                root.addChild(sprite)
            }
        }
    }

    /// Solid pad tint keyed to city — identity without busy building wallpaper.
    private func obstaclePadColor(for district: DistrictID) -> SKColor {
        switch district {
        case .wichita:
            return SKColor(red: 0.2, green: 0.19, blue: 0.175, alpha: 0.9)
        case .louisville:
            return SKColor(red: 0.16, green: 0.155, blue: 0.19, alpha: 0.9)
        case .tulsa:
            return SKColor(red: 0.21, green: 0.16, blue: 0.145, alpha: 0.9)
        case .dayton:
            return SKColor(red: 0.155, green: 0.18, blue: 0.21, alpha: 0.9)
        case .oakland:
            return SKColor(red: 0.15, green: 0.18, blue: 0.2, alpha: 0.9)
        case .sanFrancisco:
            return SKColor(red: 0.155, green: 0.17, blue: 0.21, alpha: 0.9)
        case .columbus:
            return SKColor(red: 0.14, green: 0.14, blue: 0.155, alpha: 0.9)
        case .newYorkCity:
            return SKColor(red: 0.155, green: 0.165, blue: 0.2, alpha: 0.9)
        case .losAngeles:
            return SKColor(red: 0.19, green: 0.17, blue: 0.145, alpha: 0.9)
        case .atlanta:
            return SKColor(red: 0.145, green: 0.17, blue: 0.16, alpha: 0.9)
        }
    }

    /// Scales a sprite to fit inside a collision-sized box without distorting aspect ratio.
    private func fitSprite(_ sprite: SKSpriteNode, inside box: CGSize, at position: CGPoint, z: CGFloat, alpha: CGFloat) {
        let native = sprite.size
        let scale = min(box.width / max(native.width, 1), box.height / max(native.height, 1))
        // Keep a little inset so the silhouette reads inside the pad, not over the edge.
        let fitted = scale * 0.88
        sprite.size = CGSize(width: native.width * fitted, height: native.height * fitted)
        sprite.position = position
        sprite.zPosition = z
        sprite.alpha = alpha
    }

    private func scatterDecals(in worldRect: CGRect, district: DistrictID) {
        // At most two ground decals per city — no overlay carpet, no generic sheet.
        // Overlays (radar, redaction, mesh) read as floor noise on phone (operator 2026-08-02).
        let salt = presentationSalt(district: district, worldRect: worldRect)
        switch district {
        case .wichita:
            placeDecal(.wichitaDecalRunwayStripe, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .south)
            placeDecal(.wichitaDecalGrainDust, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
        case .louisville:
            placeDecal(.louisvilleDecalWetBrick, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.louisvilleDecalBourbonStain, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
        case .dayton:
            placeDecal(.daytonDecalGatewayScrape, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.daytonDecalTestLaneStripe, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
        case .tulsa:
            placeDecal(.tulsaDecalRouteMarking, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.tulsaDecalPipelineLeak, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southWest)
        case .oakland:
            placeDecal(.oaklandDecalRailCrossing, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.oaklandDecalContainerRust, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southEast)
        case .sanFrancisco:
            placeDecal(.sanFranciscoDecalDampAsphalt, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.sanFranciscoDecalCableGroove, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
        case .columbus:
            placeDecal(.columbusDecalCapitolStripe, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .north)
            placeDecal(.columbusDecalAgencyBoundary, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southWest)
        case .newYorkCity:
            placeDecal(.newYorkDecalWetAsphalt, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.newYorkDecalScaffoldShadow, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
        case .losAngeles:
            placeDecal(.losAngelesDecalFadedLanePaint, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.losAngelesDecalStudioSpikeMark, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southEast)
        case .atlanta:
            placeDecal(.atlantaDecalBeltlineStripe, alpha: 0.08, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.atlantaDecalHOABoundary, alpha: 0.07, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southEast)
        }
    }

    private enum DecalBias {
        case center, centerEast, north, south, northEast, southEast, southWest, northWest
    }

    private func presentationSalt(district: DistrictID, worldRect: CGRect) -> UInt64 {
        var h: UInt64 = 0xcbf29ce484222325
        for byte in district.rawValue.utf8 {
            h ^= UInt64(byte)
            h &*= 0x100000001b3
        }
        h ^= UInt64(Int(worldRect.width.rounded()))
        h &*= 0x100000001b3
        h ^= UInt64(Int(worldRect.height.rounded()))
        h &*= 0x100000001b3
        return h == 0 ? 0x9E3779B97F4A7C15 : h
    }

    private func jitteredPoint(in worldRect: CGRect, salt: UInt64, index: Int, bias: DecalBias) -> CGPoint {
        let mix = salt &+ UInt64(index &+ 1) &* 0x9E3779B97F4A7C15
        let u = Double(mix % 1000) / 1000.0
        let v = Double((mix / 1000) % 1000) / 1000.0
        let insetX = worldRect.width * 0.12
        let insetY = worldRect.height * 0.12
        let base: CGPoint = {
            switch bias {
            case .center: return CGPoint(x: worldRect.midX, y: worldRect.midY)
            case .centerEast: return CGPoint(x: worldRect.midX + worldRect.width * 0.18, y: worldRect.midY)
            case .north: return CGPoint(x: worldRect.midX, y: worldRect.maxY - insetY)
            case .south: return CGPoint(x: worldRect.midX, y: worldRect.minY + insetY)
            case .northEast: return CGPoint(x: worldRect.maxX - insetX, y: worldRect.maxY - insetY)
            case .southEast: return CGPoint(x: worldRect.maxX - insetX, y: worldRect.minY + insetY)
            case .southWest: return CGPoint(x: worldRect.minX + insetX, y: worldRect.minY + insetY)
            case .northWest: return CGPoint(x: worldRect.minX + insetX, y: worldRect.maxY - insetY)
            }
        }()
        let jx = CGFloat((u - 0.5) * Double(worldRect.width) * 0.12)
        let jy = CGFloat((v - 0.5) * Double(worldRect.height) * 0.12)
        return CGPoint(x: base.x + jx, y: base.y + jy)
    }

    private func placeDecal(
        _ role: VisualAssetMap.Role,
        alpha: CGFloat,
        z: CGFloat,
        worldRect: CGRect,
        salt: UInt64,
        index: Int,
        bias: DecalBias,
        scale: CGFloat? = nil
    ) {
        guard let sprite = TextureAssetLoader.sprite(role: role) else { return }
        if let scale { sprite.setScale(scale) }
        let treatment = VisualAssetMap.entry(role).presentationTreatment
        // Semantic treatment is declared in VisualAssetMap, not inferred from
        // the current PNG's dimensions (which change with art repacks).
        sprite.alpha = treatment == .atmosphericOverlay ? min(alpha, 0.06) : alpha
        sprite.zPosition = z
        sprite.position = jitteredPoint(in: worldRect, salt: salt, index: index, bias: bias)
        root.addChild(sprite)
    }

    private func placeCityLandmarks(in worldRect: CGRect, district: DistrictID) {
        // Perimeter identity only — max two soft landmarks per city so the arena
        // is not a prop dump (operator: buildings messed up / floors too busy).
        func pin(_ role: VisualAssetMap.Role, at position: CGPoint, z: CGFloat = 1.15) {
            guard let sprite = TextureAssetLoader.sprite(role: role) else { return }
            sprite.position = position
            sprite.zPosition = z
            sprite.alpha = 0.5
            sprite.userData = NSMutableDictionary(dictionary: ["visual-role": role.rawValue])
            calmLandmark(sprite)
            root.addChild(sprite)
        }

        if district == .wichita {
            pin(.wichitaLandmarkMonument, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 90), z: 1.2)
            pin(.wichitaLandmarkBridge, at: CGPoint(x: worldRect.maxX - 200, y: worldRect.minY + 100), z: 1.1)
            return
        }

        if district == .louisville {
            pin(.louisvilleLandmarkTwinSpires, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 90), z: 1.2)
            pin(.louisvilleLandmarkRiverfront, at: CGPoint(x: worldRect.midX, y: worldRect.minY + 90), z: 1.1)
            return
        }

        if district == .tulsa {
            pin(.tulsaLandmarkDecoTower, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 90), z: 1.2)
            pin(.tulsaLandmarkOilDerrick, at: CGPoint(x: worldRect.minX + 140, y: worldRect.maxY - 120), z: 1.2)
            return
        }

        if district == .dayton {
            pin(.daytonLandmarkEarlyFlight, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 90), z: 1.2)
            pin(.daytonLandmarkFountain, at: CGPoint(x: worldRect.midX, y: worldRect.minY + 100), z: 1.1)
            return
        }

        if district == .oakland {
            pin(.oaklandLandmarkPortCrane, at: CGPoint(x: worldRect.midX + 40, y: worldRect.maxY - 90), z: 1.2)
            pin(.oaklandLandmarkLakeShoreline, at: CGPoint(x: worldRect.midX, y: worldRect.minY + 95), z: 1.1)
            return
        }

        if district == .sanFrancisco {
            pin(.sanFranciscoLandmarkBridge, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 80), z: 1.15)
            pin(.sanFranciscoLandmarkCommsTower, at: CGPoint(x: worldRect.maxX - 140, y: worldRect.maxY - 110), z: 1.2)
            return
        }

        if district == .columbus {
            pin(.columbusLandmarkOhioStatehouse, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 90), z: 1.2)
            pin(.columbusLandmarkSciotoRiverfront, at: CGPoint(x: worldRect.midX, y: worldRect.minY + 95), z: 1.1)
            return
        }

        if district == .newYorkCity {
            pin(.newYorkLandmarkSuspensionBridge, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 85), z: 1.15)
            pin(.newYorkLandmarkRooftopWaterTower, at: CGPoint(x: worldRect.maxX - 140, y: worldRect.maxY - 120), z: 1.2)
            return
        }

        if district == .losAngeles {
            pin(.losAngelesLandmarkObservatoryHills, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 90), z: 1.2)
            pin(.losAngelesLandmarkPortLogistics, at: CGPoint(x: worldRect.midX, y: worldRect.minY + 95), z: 1.1)
            return
        }

        if district == .atlanta {
            pin(.atlantaLandmarkAirportTerminal, at: CGPoint(x: worldRect.midX, y: worldRect.maxY - 85), z: 1.15)
            pin(.atlantaLandmarkDataCenterCathedral, at: CGPoint(x: worldRect.maxX - 150, y: worldRect.maxY - 120), z: 1.2)
        }
    }

    private func addParkingLines(to root: SKNode, bounds: WorldBounds) {
        // Very sparse lot marks — open center for combat (operator: floors too busy).
        for x in stride(from: bounds.minX + 200, through: bounds.maxX - 200, by: 280) {
            let line = SKShapeNode(rectOf: CGSize(width: 1.5, height: 40))
            line.position = CGPoint(x: CGFloat(x), y: 0)
            line.fillColor = .white.withAlphaComponent(0.07)
            line.strokeColor = .clear
            line.zPosition = 0.4
            root.addChild(line)
        }
    }

    /// Arterial / capitol / fog cities get short lane ticks, not parking bay stripes.
    private func addLaneTicks(to root: SKNode, bounds: WorldBounds, district: DistrictID) {
        let step: Double = district == .newYorkCity || district == .sanFrancisco ? 280 : 260
        let tickHeight: CGFloat = district == .columbus ? 28 : 36
        for x in stride(from: bounds.minX + 220, through: bounds.maxX - 220, by: step) {
            let line = SKShapeNode(rectOf: CGSize(width: 1.25, height: tickHeight))
            line.position = CGPoint(x: CGFloat(x), y: CGFloat((x.truncatingRemainder(dividingBy: 2) == 0) ? 20 : -16))
            line.fillColor = .white.withAlphaComponent(0.05)
            line.strokeColor = .clear
            line.zPosition = 0.4
            root.addChild(line)
        }
    }

    /// City identity must remain readable without relying on texture detail or hue.
    /// These marks also expose infrastructure state with labels and line grammar.
    private func addCityWayfinding(
        in rect: CGRect,
        district: DistrictID,
        state: DistrictState?,
        presentation: CityOverlayPresentation
    ) {
        guard [.wichita, .louisville, .tulsa, .dayton, .oakland, .sanFrancisco, .columbus, .newYorkCity, .losAngeles, .atlanta].contains(district) else { return }
        let group = SKNode()
        group.name = "city-wayfinding-\(district.rawValue)"
        group.zPosition = 0.52
        group.alpha = presentation.overlayAlpha
        root.addChild(group)

        switch district {
        case .wichita:
            let sensor = infrastructureStatus(nodeId: "wichita_sensor_grid", state: state)
            addGuideLine(
                to: group,
                from: CGPoint(x: rect.minX + 100, y: rect.minY + 50),
                to: CGPoint(x: rect.maxX - 100, y: rect.minY + 50),
                color: .white.withAlphaComponent(0.14),
                dash: 40
            )
            addWayfindingLabel("AIR CORRIDOR · \(sensor)", at: CGPoint(x: rect.midX, y: rect.minY + 72), to: group)

        case .louisville:
            let sensor = infrastructureStatus(nodeId: "louisville_sensor_lattice", state: state)
            // Edge redaction plates only — not mid-field stack.
            for (index, xFrac) in [0.22, 0.78].enumerated() {
                let box = SKShapeNode(rectOf: CGSize(width: 160, height: 56), cornerRadius: 6)
                box.position = CGPoint(x: rect.minX + rect.width * CGFloat(xFrac), y: rect.maxY - 70)
                box.fillColor = SKColor(white: 0.03, alpha: 0.12)
                box.strokeColor = .white.withAlphaComponent(0.16)
                box.lineWidth = 1.5
                group.addChild(box)
                addWayfindingLabel("REDACTED \(index + 1)", at: box.position, to: group)
            }
            addWayfindingLabel("MAP INDEX · \(sensor)", at: CGPoint(x: rect.midX, y: rect.minY + 52), to: group)

        case .tulsa:
            let pressure = infrastructureStatus(nodeId: "tulsa_access_boom", state: state)
            addGuideLine(
                to: group,
                from: CGPoint(x: rect.minX + 100, y: rect.minY + 48),
                to: CGPoint(x: rect.maxX - 100, y: rect.minY + 48),
                color: .systemTeal.withAlphaComponent(0.18),
                dash: 36
            )
            addWayfindingLabel("CRUDE FLOW → · \(pressure)", at: CGPoint(x: rect.midX, y: rect.minY + 68), to: group)

        case .dayton:
            let access = state?.node(id: "dayton_access_chain")?.integrity ?? 1
            let gateXs = [rect.minX + rect.width * 0.23, rect.minX + rect.width * 0.44, rect.minX + rect.width * 0.65, rect.minX + rect.width * 0.86]
            for (index, x) in gateXs.enumerated() {
                let threshold = 0.92 - Double(index) * 0.14
                let mode = access < threshold ? "BYPASS" : index == 0 ? "SCAN" : "ARMED"
                let gate = SKShapeNode(rectOf: CGSize(width: 12, height: rect.height * 0.58), cornerRadius: 4)
                gate.position = CGPoint(x: x, y: rect.midY)
                gate.fillColor = .white.withAlphaComponent(mode == "BYPASS" ? 0.06 : 0.18)
                gate.strokeColor = .white.withAlphaComponent(0.34)
                gate.lineWidth = mode == "BYPASS" ? 1 : 3
                group.addChild(gate)
                addWayfindingLabel("G\(index + 1) \(mode)", at: CGPoint(x: x, y: rect.midY + rect.height * 0.34), to: group)
            }
            addGuideLine(
                to: group,
                from: CGPoint(x: rect.minX + 70, y: rect.midY),
                to: CGPoint(x: rect.maxX - 70, y: rect.midY),
                color: .white.withAlphaComponent(0.2),
                dash: 28
            )

        case .oakland:
            let agencies = [
                ("PORT", "oakland_power_yard"),
                ("BART", "oakland_access_gate"),
                ("CITY", "oakland_civilian_tips"),
                ("FED", "oakland_sensor_lattice"),
                ("VENDOR", "oakland_response_unit"),
            ]
            let startX = rect.minX + rect.width * 0.16
            let spacing = rect.width * 0.17
            for (index, agency) in agencies.enumerated() {
                let status = infrastructureStatus(nodeId: agency.1, state: state)
                let x = startX + CGFloat(index) * spacing
                let badge = SKShapeNode(rectOf: CGSize(width: 112, height: 58), cornerRadius: 8)
                badge.position = CGPoint(x: x, y: rect.midY + CGFloat(index.isMultiple(of: 2) ? 112 : -112))
                badge.fillColor = SKColor(white: 0.04, alpha: 0.35)
                badge.strokeColor = .white.withAlphaComponent(0.4)
                badge.lineWidth = status == "ONLINE" ? 2.5 : 1
                group.addChild(badge)
                addWayfindingLabel("\(agency.0) · \(status)", at: badge.position, to: group)
                if index < agencies.count - 1 {
                    let nextX = x + spacing
                    addGuideLine(
                        to: group,
                        from: CGPoint(x: x + 58, y: badge.position.y),
                        to: CGPoint(x: nextX - 58, y: rect.midY + CGFloat((index + 1).isMultiple(of: 2) ? 112 : -112)),
                        color: .white.withAlphaComponent(0.25),
                        dash: 24
                    )
                }
            }
            let contract = state?.node(id: "oakland_fiber_spine")?.status.rawValue.uppercased() ?? "ACTIVE"
            addWayfindingLabel(
                "SANCTUARY POLICY / CONTRACT 04 · \(contract)",
                at: CGPoint(x: rect.midX, y: rect.midY),
                to: group
            )
            addGuideLine(
                to: group,
                from: CGPoint(x: rect.minX + 80, y: rect.midY - 28),
                to: CGPoint(x: rect.maxX - 80, y: rect.midY - 28),
                color: .systemTeal.withAlphaComponent(0.3),
                dash: 36
            )

        case .sanFrancisco:
            let sensorStatus = infrastructureStatus(nodeId: "sf_sensor_grid", state: state)
            let warrantStatus = infrastructureStatus(nodeId: "sf_access_boom", state: state)

            // Steep grade and paired cable grooves remain readable without texture or hue.
            for offset in stride(from: CGFloat(-180), through: 180, by: 90) {
                addGuideLine(
                    to: group,
                    from: CGPoint(x: rect.minX + 80, y: rect.minY + 150 + offset),
                    to: CGPoint(x: rect.maxX - 80, y: rect.maxY - 150 + offset),
                    color: .white.withAlphaComponent(0.16),
                    dash: 0
                )
            }
            for grooveOffset: CGFloat in [-12, 12] {
                addGuideLine(
                    to: group,
                    from: CGPoint(x: rect.minX + 90, y: rect.midY + grooveOffset),
                    to: CGPoint(x: rect.maxX - 90, y: rect.midY + grooveOffset),
                    color: .white.withAlphaComponent(0.26),
                    dash: 30
                )
            }
            addWayfindingLabel("CABLE GRADE ↑", at: CGPoint(x: rect.minX + 180, y: rect.midY + 54), to: group)

            // Fog is concealment with an inspectable boundary, never an unmarked wash.
            addHatchedZone(
                named: "FOG BAND A · \(sensorStatus)",
                rect: CGRect(x: rect.minX + 170, y: rect.midY + 90, width: 430, height: 175),
                to: group
            )
            addHatchedZone(
                named: "FOG BAND B · \(sensorStatus)",
                rect: CGRect(x: rect.maxX - 600, y: rect.midY - 275, width: 430, height: 175),
                to: group
            )

            // Improper-search authority is a separate dashed grammar from fog cover.
            let warrant = SKShapeNode(rectOf: CGSize(width: 520, height: 250), cornerRadius: 18)
            warrant.name = "san-francisco-warrant-zone"
            warrant.position = CGPoint(x: rect.midX + 180, y: rect.midY + 20)
            warrant.fillColor = SKColor(white: 0.04, alpha: 0.08)
            warrant.strokeColor = .white.withAlphaComponent(0.42)
            warrant.lineWidth = warrantStatus == "ONLINE" ? 3 : 1
            group.addChild(warrant)
            addWayfindingLabel("WARRANT COVERAGE · \(warrantStatus)", at: CGPoint(x: warrant.position.x, y: warrant.position.y + 145), to: group)

            // Last-known sensor positions expose provenance even when bodies sit in fog.
            let provenance = [
                ("SENSOR 01 / CITY", CGPoint(x: rect.minX + 150, y: rect.minY + 100)),
                ("SENSOR 02 / CITY", CGPoint(x: rect.maxX - 150, y: rect.maxY - 100)),
                ("SENSOR 03 / VENDOR", CGPoint(x: rect.midX + 300, y: rect.midY)),
            ]
            for (index, marker) in provenance.enumerated() {
                let ring = SKShapeNode(circleOfRadius: 24)
                ring.position = marker.1
                ring.fillColor = SKColor(white: 0.03, alpha: 0.28)
                ring.strokeColor = .white.withAlphaComponent(0.52)
                ring.lineWidth = index == 2 ? 3 : 2
                group.addChild(ring)
                addWayfindingLabel(marker.0, at: CGPoint(x: marker.1.x, y: marker.1.y + 38), to: group)
            }

            // The Algorithmic Moderate's four policies are mechanically linked to
            // distinct infrastructure authorities; every phase still exposes observation.
            let phases = [
                ("PUBLIC SAFETY", "sf_sensor_grid"),
                ("CIVIL LIBERTIES", "sf_civilian_tips"),
                ("TEMP SAFEGUARD", "sf_access_boom"),
                ("INDEPENDENT REVIEW", "sf_response_unit"),
            ]
            let boardY = rect.minY + 62
            for (index, phase) in phases.enumerated() {
                let x = rect.minX + rect.width * CGFloat(0.18 + Double(index) * 0.215)
                let status = infrastructureStatus(nodeId: phase.1, state: state)
                let box = SKShapeNode(rectOf: CGSize(width: 250, height: 48), cornerRadius: 7)
                box.position = CGPoint(x: x, y: boardY)
                box.fillColor = SKColor(white: 0.03, alpha: 0.4)
                box.strokeColor = .white.withAlphaComponent(0.38)
                box.lineWidth = status == "ONLINE" ? 2.5 : 1
                group.addChild(box)
                addWayfindingLabel("\(phase.0) · \(status)", at: box.position, to: group)
            }

        case .columbus:
            // Jurisdictions differ by boundary grammar as well as labels, so the
            // split remains readable in grayscale and reduced presentation.
            let jurisdictions: [(String, String, CGRect, CGFloat)] = [
                ("STATE", "columbus_sensor_cabinets", CGRect(x: rect.minX + 90, y: rect.midY + 35, width: 500, height: 350), 0),
                ("CITY", "columbus_power_plaza", CGRect(x: rect.maxX - 590, y: rect.midY + 35, width: 500, height: 350), 34),
                ("CAMPUS", "columbus_fiber_share", CGRect(x: rect.minX + 90, y: rect.minY + 90, width: 500, height: 330), 16),
                ("SUBURB", "columbus_civilian_tips", CGRect(x: rect.maxX - 590, y: rect.minY + 90, width: 500, height: 330), 48),
                ("AGENCY", "columbus_response_unit", CGRect(x: rect.midX - 210, y: rect.midY - 150, width: 420, height: 300), 24),
            ]
            for jurisdiction in jurisdictions {
                let status = infrastructureStatus(nodeId: jurisdiction.1, state: state)
                addDashedZone(
                    named: "\(jurisdiction.0) · \(status)",
                    rect: jurisdiction.2,
                    dash: jurisdiction.3,
                    to: group
                )
            }

            // Numbered share routes expose which authority is online and which
            // fallback becomes available after an authored cascade.
            let routeHub = CGPoint(x: rect.midX, y: rect.midY + 12)
            let routes: [(String, String, CGPoint, CGFloat)] = [
                ("R1 STATE", "columbus_sensor_cabinets", CGPoint(x: rect.minX + 300, y: rect.maxY - 150), 0),
                ("R2 CITY", "columbus_power_plaza", CGPoint(x: rect.maxX - 300, y: rect.maxY - 150), 32),
                ("R3 CAMPUS", "columbus_fiber_share", CGPoint(x: rect.minX + 300, y: rect.minY + 210), 16),
                ("R4 SUBURB", "columbus_civilian_tips", CGPoint(x: rect.maxX - 300, y: rect.minY + 210), 44),
            ]
            for route in routes {
                let status = infrastructureStatus(nodeId: route.1, state: state)
                addGuideLine(
                    to: group,
                    from: routeHub,
                    to: route.2,
                    color: .white.withAlphaComponent(status == "ONLINE" ? 0.38 : 0.18),
                    dash: route.3
                )
                let marker = SKShapeNode(circleOfRadius: 20)
                marker.position = route.2
                marker.fillColor = SKColor(white: 0.04, alpha: 0.38)
                marker.strokeColor = .white.withAlphaComponent(0.5)
                marker.lineWidth = status == "ONLINE" ? 3 : 1
                group.addChild(marker)
                addWayfindingLabel("\(route.0) · \(status)", at: CGPoint(x: route.2.x, y: route.2.y + 34), to: group)
            }
            addWayfindingLabel("STATEWIDE SHARE ROUTER", at: CGPoint(x: routeHub.x, y: routeHub.y + 34), to: group)

            let hearingStatus = infrastructureStatus(nodeId: "columbus_access_barrier", state: state)
            let reviewStatus = infrastructureStatus(nodeId: "columbus_response_unit", state: state)
            let board = SKShapeNode(rectOf: CGSize(width: 780, height: 58), cornerRadius: 8)
            board.name = "columbus-hearing-schedule"
            board.position = CGPoint(x: rect.midX, y: rect.minY + 58)
            board.fillColor = SKColor(white: 0.03, alpha: 0.45)
            board.strokeColor = .white.withAlphaComponent(0.42)
            board.lineWidth = 2
            group.addChild(board)
            addWayfindingLabel(
                "PUBLIC COMMENT → MEANINGFUL REVIEW → RESCHEDULED → ROUTE TRANSFER · \(hearingStatus)/\(reviewStatus)",
                at: board.position,
                to: group
            )
            addWayfindingLabel(
                "PUBLIC COMMENT QUEUE · \(infrastructureStatus(nodeId: "columbus_civilian_tips", state: state))",
                at: CGPoint(x: rect.midX, y: rect.maxY - 62),
                to: group
            )

        case .newYorkCity:
            // Every borough uses a different boundary cadence, preserving the
            // phase map in grayscale and reduced presentation.
            let boroughs: [(String, String, String, CGRect, CGFloat)] = [
                ("MANHATTAN", "SIGNAGE OBSERVATION", "nyc_sensor_lattice", CGRect(x: rect.midX - 190, y: rect.midY - 210, width: 380, height: 580), 0),
                ("BROOKLYN", "BRIDGE / STREET RELAY", "nyc_power_grid", CGRect(x: rect.minX + 80, y: rect.minY + 70, width: 480, height: 310), 32),
                ("QUEENS", "TRANSIT PREDICTION", "nyc_access_turnstile", CGRect(x: rect.maxX - 560, y: rect.minY + 70, width: 480, height: 310), 16),
                ("BRONX", "OVERHEAD COVERAGE", "nyc_response_unit", CGRect(x: rect.minX + 80, y: rect.maxY - 350, width: 480, height: 280), 46),
                ("STATEN", "DELAYED TRANSFER", "nyc_civilian_tips", CGRect(x: rect.maxX - 560, y: rect.maxY - 350, width: 480, height: 280), 24),
            ]
            for borough in boroughs {
                let status = infrastructureStatus(nodeId: borough.2, state: state)
                addDashedZone(
                    named: "\(borough.0) · \(borough.1) · \(status)",
                    rect: borough.3,
                    dash: borough.4,
                    to: group
                )
            }

            // Brighter avenues, crosswalks, and scaffold rails establish stable
            // city structure beneath the borough overlays.
            for y in [rect.midY - 125, rect.midY + 125] {
                addGuideLine(to: group, from: CGPoint(x: rect.minX + 55, y: y), to: CGPoint(x: rect.maxX - 55, y: y), color: .white.withAlphaComponent(0.25), dash: 0)
            }
            for x in [rect.midX - 330, rect.midX, rect.midX + 330] {
                addGuideLine(to: group, from: CGPoint(x: x, y: rect.minY + 55), to: CGPoint(x: x, y: rect.maxY - 55), color: .white.withAlphaComponent(0.22), dash: 28)
            }

            let syncHub = CGPoint(x: rect.midX, y: rect.midY)
            let routes: [(String, String, CGPoint, CGFloat)] = [
                ("S1 MANHATTAN", "nyc_sensor_lattice", CGPoint(x: rect.midX, y: rect.maxY - 115), 0),
                ("S2 BROOKLYN", "nyc_power_grid", CGPoint(x: rect.minX + 250, y: rect.minY + 160), 32),
                ("S3 QUEENS", "nyc_access_turnstile", CGPoint(x: rect.maxX - 250, y: rect.minY + 160), 16),
                ("S4 BRONX", "nyc_response_unit", CGPoint(x: rect.minX + 250, y: rect.maxY - 155), 46),
                ("S5 STATEN", "nyc_civilian_tips", CGPoint(x: rect.maxX - 250, y: rect.maxY - 155), 24),
            ]
            for route in routes {
                let status = infrastructureStatus(nodeId: route.1, state: state)
                addGuideLine(to: group, from: syncHub, to: route.2, color: .white.withAlphaComponent(status == "ONLINE" ? 0.4 : 0.18), dash: route.3)
                let marker = SKShapeNode(circleOfRadius: 20)
                marker.position = route.2
                marker.fillColor = SKColor(white: 0.03, alpha: 0.42)
                marker.strokeColor = .white.withAlphaComponent(0.55)
                marker.lineWidth = status == "ONLINE" ? 3 : 1
                group.addChild(marker)
                addWayfindingLabel("\(route.0) · \(status)", at: CGPoint(x: route.2.x, y: route.2.y + 34), to: group)
            }
            addWayfindingLabel("BOROUGH SYNC · \(infrastructureStatus(nodeId: "nyc_fiber_sync", state: state))", at: CGPoint(x: syncHub.x, y: syncHub.y + 34), to: group)

            let clock = SKShapeNode(rectOf: CGSize(width: 1040, height: 58), cornerRadius: 8)
            clock.name = "new-york-phase-clock"
            clock.position = CGPoint(x: rect.midX, y: rect.minY + 52)
            clock.fillColor = SKColor(white: 0.025, alpha: 0.5)
            clock.strokeColor = .white.withAlphaComponent(0.46)
            clock.lineWidth = 2
            group.addChild(clock)
            addWayfindingLabel("MANHATTAN → BROOKLYN → QUEENS → BRONX → STATEN → REAL-TIME CITY", at: clock.position, to: group)

        case .losAngeles:
            // Operator boundaries use independent line cadences, keeping the
            // decentralized network readable without hue or animated effects.
            let domains: [(String, String, CGRect, CGFloat)] = [
                ("CITY ARTERIAL", "la_sensor_grid", CGRect(x: rect.minX + 70, y: rect.midY - 115, width: rect.width - 140, height: 230), 0),
                ("STUDIO", "la_power_lot", CGRect(x: rect.minX + 90, y: rect.maxY - 340, width: 520, height: 260), 38),
                ("HOA", "la_civilian_tips", CGRect(x: rect.maxX - 610, y: rect.maxY - 340, width: 520, height: 260), 16),
                ("PORT", "la_fiber_private", CGRect(x: rect.minX + 90, y: rect.minY + 70, width: 520, height: 260), 48),
                ("PARKING VENDOR", "la_access_boom", CGRect(x: rect.maxX - 610, y: rect.minY + 70, width: 520, height: 260), 24),
            ]
            for domain in domains {
                addDashedZone(
                    named: "\(domain.0) · \(infrastructureStatus(nodeId: domain.1, state: state))",
                    rect: domain.2,
                    dash: domain.3,
                    to: group
                )
            }

            // Freeway lanes and private-lot thresholds remain the stable base
            // grammar when reduced presentation suppresses transient effects.
            for offset in [-150.0, -50, 50, 150] {
                addGuideLine(
                    to: group,
                    from: CGPoint(x: rect.minX + 50, y: rect.midY + CGFloat(offset)),
                    to: CGPoint(x: rect.maxX - 50, y: rect.midY + CGFloat(offset)),
                    color: .white.withAlphaComponent(0.24),
                    dash: offset == -50 || offset == 50 ? 34 : 0
                )
            }

            let noOwner = CGPoint(x: rect.midX, y: rect.midY)
            let custodyRoutes: [(String, String, CGPoint, CGFloat)] = [
                ("C1 CITY", "la_sensor_grid", CGPoint(x: rect.minX + 300, y: rect.midY + 25), 0),
                ("C2 STUDIO", "la_power_lot", CGPoint(x: rect.minX + 350, y: rect.maxY - 160), 38),
                ("C3 HOA", "la_civilian_tips", CGPoint(x: rect.maxX - 350, y: rect.maxY - 160), 16),
                ("C4 PORT", "la_fiber_private", CGPoint(x: rect.minX + 350, y: rect.minY + 150), 48),
                ("C5 PARKING", "la_access_boom", CGPoint(x: rect.maxX - 350, y: rect.minY + 150), 24),
            ]
            for route in custodyRoutes {
                let status = infrastructureStatus(nodeId: route.1, state: state)
                addGuideLine(to: group, from: route.2, to: noOwner, color: .white.withAlphaComponent(status == "ONLINE" ? 0.4 : 0.18), dash: route.3)
                addWayfindingLabel("\(route.0) · \(status)", at: CGPoint(x: route.2.x, y: route.2.y + 30), to: group)
            }

            let hub = SKShapeNode(circleOfRadius: 72)
            hub.name = "los-angeles-no-owner-hub"
            hub.position = noOwner
            hub.fillColor = SKColor(white: 0.025, alpha: 0.48)
            hub.strokeColor = .white.withAlphaComponent(0.52)
            hub.lineWidth = 3
            group.addChild(hub)
            addWayfindingLabel("NO RESPONSIBLE PARTY", at: noOwner, to: group)

            let liability = SKShapeNode(rectOf: CGSize(width: 940, height: 58), cornerRadius: 8)
            liability.name = "los-angeles-liability-roll"
            liability.position = CGPoint(x: rect.midX, y: rect.minY + 50)
            liability.fillColor = SKColor(white: 0.025, alpha: 0.48)
            liability.strokeColor = .white.withAlphaComponent(0.44)
            liability.lineWidth = 2
            group.addChild(liability)
            addWayfindingLabel("CITY → PRIVATE OPERATOR → VENDOR → SUBCONTRACTOR → NO RESPONSIBLE PARTY", at: liability.position, to: group)

        case .atlanta:
            // Each source uses a separate boundary cadence so nationwide
            // convergence remains legible in grayscale and reduced presentation.
            let sources: [(String, String, CGRect, CGFloat)] = [
                ("AIRPORT IDENTITY", "atl_access_gate", CGRect(x: rect.minX + 70, y: rect.maxY - 325, width: 480, height: 245), 0),
                ("BELTLINE BEHAVIOR", "atl_sensor_hive", CGRect(x: rect.maxX - 550, y: rect.maxY - 325, width: 480, height: 245), 32),
                ("FILM LOT SECURITY", "atl_power_cathedral", CGRect(x: rect.minX + 70, y: rect.minY + 70, width: 480, height: 245), 16),
                ("HOA MESH", "atl_civilian_tips", CGRect(x: rect.maxX - 550, y: rect.minY + 70, width: 480, height: 245), 48),
                ("DATA CENTER", "atl_fiber_national", CGRect(x: rect.midX - 230, y: rect.midY - 170, width: 460, height: 340), 24),
            ]
            for source in sources {
                addDashedZone(named: "\(source.0) · \(infrastructureStatus(nodeId: source.1, state: state))", rect: source.2, dash: source.3, to: group)
            }

            // BeltLine loop and freeway trenches provide a bounded physical
            // grammar rather than relying on the full-field network echo.
            let beltline = SKShapeNode(ellipseOf: CGSize(width: rect.width * 0.72, height: rect.height * 0.58))
            beltline.name = "atlanta-beltline-loop"
            beltline.position = CGPoint(x: rect.midX, y: rect.midY)
            beltline.fillColor = .clear
            beltline.strokeColor = .white.withAlphaComponent(0.3)
            beltline.lineWidth = 3
            group.addChild(beltline)
            for x in [rect.midX - 300, rect.midX + 300] {
                addGuideLine(to: group, from: CGPoint(x: x, y: rect.minY + 55), to: CGPoint(x: x, y: rect.maxY - 55), color: .white.withAlphaComponent(0.25), dash: 36)
            }

            let cathedral = CGPoint(x: rect.midX, y: rect.midY)
            let scopeRoutes: [(String, String, CGPoint, CGFloat)] = [
                ("N1 LOCAL / AIRPORT", "atl_access_gate", CGPoint(x: rect.minX + 280, y: rect.maxY - 155), 0),
                ("N2 METRO / BELTLINE", "atl_sensor_hive", CGPoint(x: rect.maxX - 280, y: rect.maxY - 155), 32),
                ("N3 STATE / FILM", "atl_power_cathedral", CGPoint(x: rect.minX + 280, y: rect.minY + 145), 16),
                ("N4 REGIONAL / HOA", "atl_civilian_tips", CGPoint(x: rect.maxX - 280, y: rect.minY + 145), 48),
                ("N5 NATIONAL / TRUNK", "atl_fiber_national", CGPoint(x: rect.midX, y: rect.maxY - 95), 24),
            ]
            for route in scopeRoutes {
                let status = infrastructureStatus(nodeId: route.1, state: state)
                addGuideLine(to: group, from: route.2, to: cathedral, color: .white.withAlphaComponent(status == "ONLINE" ? 0.42 : 0.18), dash: route.3)
                addWayfindingLabel("\(route.0) · \(status)", at: CGPoint(x: route.2.x, y: route.2.y + 30), to: group)
            }

            let server = SKShapeNode(circleOfRadius: 76)
            server.name = "atlanta-server-cathedral"
            server.position = cathedral
            server.fillColor = SKColor(white: 0.025, alpha: 0.46)
            server.strokeColor = .white.withAlphaComponent(0.56)
            server.lineWidth = 3
            group.addChild(server)
            addWayfindingLabel("SERVER CATHEDRAL", at: cathedral, to: group)

            let convergence = SKShapeNode(rectOf: CGSize(width: 960, height: 58), cornerRadius: 8)
            convergence.name = "atlanta-convergence-status"
            convergence.position = CGPoint(x: rect.midX, y: rect.minY + 48)
            convergence.fillColor = SKColor(white: 0.025, alpha: 0.5)
            convergence.strokeColor = .white.withAlphaComponent(0.46)
            convergence.lineWidth = 2
            group.addChild(convergence)
            addWayfindingLabel("LOCAL → REGIONAL → NATIONAL → CHIMERA → OBJECTIVE EVIDENCE → SAFETY EVANGELIST", at: convergence.position, to: group)

            addWayfindingLabel(
                "NETWORK COLLAPSE · \(infrastructureStatus(nodeId: "atl_response_unit", state: state))",
                at: CGPoint(x: rect.midX, y: rect.maxY - 48),
                to: group
            )

        default:
            break
        }
    }

    private func infrastructureStatus(nodeId: String, state: DistrictState?) -> String {
        guard let node = state?.node(id: nodeId) else { return "ONLINE" }
        return node.status.rawValue.uppercased()
    }

    private func addWayfindingLabel(_ text: String, at position: CGPoint, to parent: SKNode) {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = CityOverlayPresentation.phoneMinimumLabelSize
        label.fontColor = .white.withAlphaComponent(0.72)
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        label.position = position
        parent.addChild(label)
    }

    private func addHatchedZone(named name: String, rect: CGRect, to parent: SKNode) {
        let boundary = SKShapeNode(rect: rect, cornerRadius: 16)
        boundary.fillColor = SKColor(white: 0.08, alpha: 0.12)
        boundary.strokeColor = .white.withAlphaComponent(0.38)
        boundary.lineWidth = 2
        parent.addChild(boundary)

        let hatch = SKNode()
        hatch.name = "san-francisco-fog-hatch"
        for x in stride(from: rect.minX - rect.height, through: rect.maxX, by: 42) {
            addGuideLine(
                to: hatch,
                from: CGPoint(x: x, y: rect.minY),
                to: CGPoint(x: min(x + rect.height, rect.maxX), y: rect.maxY),
                color: .white.withAlphaComponent(0.12),
                dash: 18
            )
        }
        parent.addChild(hatch)
        addWayfindingLabel(name, at: CGPoint(x: rect.midX, y: rect.maxY + 24), to: parent)
    }

    private func addDashedZone(named name: String, rect: CGRect, dash: CGFloat, to parent: SKNode) {
        let fill = SKShapeNode(rect: rect, cornerRadius: 14)
        fill.fillColor = SKColor(white: 0.08, alpha: 0.07)
        fill.strokeColor = .clear
        parent.addChild(fill)
        addGuideLine(to: parent, from: CGPoint(x: rect.minX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.minY), color: .white.withAlphaComponent(0.32), dash: dash)
        addGuideLine(to: parent, from: CGPoint(x: rect.maxX, y: rect.minY), to: CGPoint(x: rect.maxX, y: rect.maxY), color: .white.withAlphaComponent(0.32), dash: dash)
        addGuideLine(to: parent, from: CGPoint(x: rect.maxX, y: rect.maxY), to: CGPoint(x: rect.minX, y: rect.maxY), color: .white.withAlphaComponent(0.32), dash: dash)
        addGuideLine(to: parent, from: CGPoint(x: rect.minX, y: rect.maxY), to: CGPoint(x: rect.minX, y: rect.minY), color: .white.withAlphaComponent(0.32), dash: dash)
        addWayfindingLabel(name, at: CGPoint(x: rect.midX, y: rect.maxY - 24), to: parent)
    }

    private func addGuideLine(
        to parent: SKNode,
        from start: CGPoint,
        to end: CGPoint,
        color: SKColor,
        dash: CGFloat
    ) {
        let path = CGMutablePath()
        if dash > 0 {
            let distance = hypot(end.x - start.x, end.y - start.y)
            let count = max(1, Int(distance / dash))
            for index in 0..<count where index.isMultiple(of: 2) {
                let a = CGFloat(index) / CGFloat(count)
                let b = CGFloat(min(index + 1, count)) / CGFloat(count)
                path.move(to: CGPoint(x: start.x + (end.x - start.x) * a, y: start.y + (end.y - start.y) * a))
                path.addLine(to: CGPoint(x: start.x + (end.x - start.x) * b, y: start.y + (end.y - start.y) * b))
            }
        } else {
            path.move(to: start)
            path.addLine(to: end)
        }
        let line = SKShapeNode(path: path)
        line.strokeColor = color
        line.lineWidth = 3
        parent.addChild(line)
    }

    private func calmLandmark(_ sprite: SKSpriteNode) {
        let role = sprite.userData?["visual-role"] as? String
        let treatment = role.flatMap(VisualAssetMap.Role.init(rawValue:)).map(VisualAssetMap.entry)?.presentationTreatment ?? .sprite
        let plate = treatment == .landmarkPlate
        sprite.alpha = min(sprite.alpha, plate ? 0.42 : 0.5)
        // Cap silhouette size so perimeter landmarks don't dominate the arena.
        let maxEdge: CGFloat = plate ? 100 : 120
        let longest = max(sprite.size.width, sprite.size.height)
        if longest > maxEdge {
            let s = maxEdge / longest
            sprite.size = CGSize(width: sprite.size.width * s, height: sprite.size.height * s)
        }
        if plate {
            sprite.color = SKColor(white: 0.85, alpha: 1)
            sprite.colorBlendFactor = 0.1
        }
    }
}
