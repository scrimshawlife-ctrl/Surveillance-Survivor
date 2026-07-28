import SpriteKit
import SurveillanceCore

/// Projects world layout only. Never owns collision or gameplay truth.
@MainActor
final class WorldProjector {
    private let root = SKNode()
    private var renderedKey: String?

    func synchronize(
        layout: WorldLayout,
        district: DistrictID,
        landmark: LandmarkEncounterState = .idle,
        districtState: DistrictState? = nil,
        in scene: SKScene
    ) {
        let stateKey = districtState?.nodes
            .map { "\($0.id):\(Int(($0.integrity * 100).rounded()))" }
            .joined(separator: ",") ?? "-"
        let key = "\(district.rawValue)|\(layout.bounds.minX),\(layout.bounds.minY),\(layout.bounds.maxX),\(layout.bounds.maxY)|\(layout.obstacles.count)|\(landmark.isPlayerInside)|\(landmark.activeEncounterId ?? "-")|\(stateKey)"
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
        addCityWayfinding(in: worldRect, district: district, state: districtState)
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
        // Hallmark M3: per-city asphalt base tint (still dark; small ΔL for identity).
        let base = asphaltBaseColor(for: district)
        let asphalt = SKShapeNode(rect: worldRect)
        asphalt.fillColor = base
        asphalt.strokeColor = SKColor(white: 0.28, alpha: 0.85)
        asphalt.lineWidth = 3
        asphalt.zPosition = 0
        root.addChild(asphalt)

        // Primary terrain stamps — broken grid rhythm (Hallmark M1).
        stampTerrainLayer(
            role: VisualAssetMap.terrainRole(for: district),
            in: worldRect,
            baseSize: 300,
            alpha: 0.24,
            z: 0.05,
            phase: 0
        )
        // Secondary city terrain at larger scale / lower alpha (Hallmark M2).
        if let secondary = VisualAssetMap.secondaryTerrainRole(for: district) {
            stampTerrainLayer(
                role: secondary,
                in: worldRect,
                baseSize: 420,
                alpha: 0.12,
                z: 0.06,
                phase: 1
            )
        }
    }

    /// District asphalt tint from city identity (presentation only).
    private func asphaltBaseColor(for district: DistrictID) -> SKColor {
        // Keep playfield dark; shift hue slightly so cities don't share one gray slab.
        // Informed by city weather/lighting labels in city_systemic_rules.
        switch district {
        case .wichita:
            return SKColor(red: 0.165, green: 0.17, blue: 0.175, alpha: 1) // prairie dry asphalt
        case .louisville:
            return SKColor(red: 0.145, green: 0.15, blue: 0.17, alpha: 1) // wet brick cool
        case .tulsa:
            return SKColor(red: 0.17, green: 0.15, blue: 0.14, alpha: 1) // warm industrial
        case .dayton:
            return SKColor(red: 0.15, green: 0.165, blue: 0.185, alpha: 1) // overcast research
        case .oakland:
            return SKColor(red: 0.145, green: 0.165, blue: 0.18, alpha: 1) // marine cool
        case .sanFrancisco:
            return SKColor(red: 0.145, green: 0.16, blue: 0.185, alpha: 1) // legible fog cool
        case .columbus:
            return SKColor(red: 0.12, green: 0.12, blue: 0.125, alpha: 1) // fluorescent civic
        case .newYorkCity:
            return SKColor(red: 0.145, green: 0.155, blue: 0.18, alpha: 1) // legible steam/scaffold
        case .losAngeles:
            return SKColor(red: 0.15, green: 0.14, blue: 0.125, alpha: 1) // legible sunbleached warm
        case .atlanta:
            return SKColor(red: 0.11, green: 0.125, blue: 0.12, alpha: 1) // humid canopy
        }
    }

    /// Irregular tile stamps — dual sizes, phase offset, slight rotation (M1).
    private func stampTerrainLayer(
        role: VisualAssetMap.Role,
        in worldRect: CGRect,
        baseSize: CGFloat,
        alpha: CGFloat,
        z: CGFloat,
        phase: Int
    ) {
        guard let image = TextureAssetLoader.image(named: VisualAssetMap.assetName(role)) else { return }
        let texture = SKTexture(image: image)
        // Soft terrain reads better linear; keep nearest for characters elsewhere (m1).
        texture.filteringMode = .linear
        let sizes: [CGFloat] = phase == 0 ? [baseSize, baseSize * 1.15, baseSize * 0.88] : [baseSize, baseSize * 0.92]
        var row = 0
        var y = worldRect.minY - baseSize * 0.15
        while y < worldRect.maxY + baseSize * 0.2 {
            var col = 0
            // Phase offsets break the lattice so cities don't look wallpapered.
            let rowOffset = (phase == 0 ? CGFloat(row % 3) * 37 : CGFloat((row + 1) % 2) * 55)
            var x = worldRect.minX - baseSize * 0.2 + rowOffset
            while x < worldRect.maxX + baseSize * 0.2 {
                let size = sizes[(row + col + phase) % sizes.count]
                let node = SKSpriteNode(texture: texture, size: CGSize(width: size, height: size))
                node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
                node.position = CGPoint(x: x + size * 0.5, y: y + size * 0.5)
                // Tiny rotation breaks tile-edge seams without spinning the world.
                let twist = CGFloat(((row * 3 + col * 5 + phase * 7) % 5) - 2) * 0.012
                node.zRotation = twist
                node.zPosition = z
                node.alpha = alpha
                root.addChild(node)
                x += size * 0.78
                col += 1
            }
            y += baseSize * 0.72
            row += 1
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
        let hangarAvailable = district == .wichita
            && TextureAssetLoader.isAvailable(GameAssetName.Wichita.landmarkHangar)
        let warehouseAvailable = district == .louisville
            && TextureAssetLoader.isAvailable(GameAssetName.Louisville.landmarkWarehouse)
        let factoryAvailable = district == .dayton
            && TextureAssetLoader.isAvailable(GameAssetName.Dayton.landmarkFactory)
        let pumpjackAvailable = district == .tulsa
            && TextureAssetLoader.isAvailable(GameAssetName.Tulsa.landmarkPumpjack)
        let containerAvailable = district == .oakland
            && TextureAssetLoader.isAvailable(GameAssetName.Oakland.landmarkContainerStack)
        let victorianAvailable = district == .sanFrancisco
            && TextureAssetLoader.isAvailable(GameAssetName.SanFrancisco.landmarkVictorian)
        let hearingAvailable = district == .columbus
            && TextureAssetLoader.isAvailable(GameAssetName.Columbus.landmarkHearingChamber)
        let scaffoldAvailable = district == .newYorkCity
            && TextureAssetLoader.isAvailable(GameAssetName.NewYork.landmarkScaffoldShed)
        let studioBacklotAvailable = district == .losAngeles
            && TextureAssetLoader.isAvailable(GameAssetName.LosAngeles.landmarkStudioBacklot)
        let campusAvailable = district == .atlanta
            && TextureAssetLoader.isAvailable(GameAssetName.Atlanta.landmarkCorporateCampus)
        let useRetail = TextureAssetLoader.isAvailable(GameAssetName.Environment.obstacleRetailMass)

        for (index, obstacle) in obstacles.enumerated() {
            let size = CGSize(width: CGFloat(obstacle.halfSize.x * 2), height: CGFloat(obstacle.halfSize.y * 2))
            let position = CGPoint(x: CGFloat(obstacle.center.x), y: CGFloat(obstacle.center.y))

            // Collision pad first — readable solid that matches sim AABB exactly.
            let pad = SKShapeNode(rectOf: size, cornerRadius: min(10, min(size.width, size.height) * 0.12))
            pad.position = position
            pad.fillColor = SKColor(white: 0.18, alpha: 0.92)
            pad.strokeColor = SKColor(white: 0.55, alpha: 0.35)
            pad.lineWidth = 2
            pad.zPosition = 1
            root.addChild(pad)

            let artRole: VisualAssetMap.Role? = {
                if hangarAvailable, index.isMultiple(of: 2) { return .wichitaLandmarkHangar }
                if warehouseAvailable, index.isMultiple(of: 2) { return .louisvilleLandmarkWarehouse }
                if factoryAvailable, index.isMultiple(of: 2) { return .daytonLandmarkFactory }
                if pumpjackAvailable, index.isMultiple(of: 2) { return .tulsaLandmarkPumpjack }
                if containerAvailable, index.isMultiple(of: 2) { return .oaklandLandmarkContainerStack }
                if victorianAvailable, index.isMultiple(of: 2) { return .sanFranciscoLandmarkVictorian }
                if hearingAvailable, index.isMultiple(of: 2) { return .columbusLandmarkHearingChamber }
                if scaffoldAvailable, index.isMultiple(of: 2) { return .newYorkLandmarkScaffoldShed }
                if studioBacklotAvailable, index.isMultiple(of: 2) { return .losAngelesLandmarkStudioBacklot }
                if campusAvailable, index.isMultiple(of: 2) { return .atlantaLandmarkCorporateCampus }
                if useRetail { return .envObstacleRetailMass }
                return nil
            }()

            if let role = artRole, let sprite = TextureAssetLoader.sprite(role: role) {
                // Aspect-fit inside the collision pad — never stretch art to the hitbox.
                // Hallmark m4: keep obstacle art under floor-primary read (≤0.75).
                fitSprite(sprite, inside: size, at: position, z: 1.05, alpha: 0.75)
                root.addChild(sprite)
            }
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
        // Sparse, low-alpha stamps. Positions are district-stable hashes so
        // floors differ by city without hard-coded mid-field clones (Hallmark m2).
        let salt = presentationSalt(district: district, worldRect: worldRect)
        if let stamp = TextureAssetLoader.sprite(role: .envDecalSheet) {
            stamp.setScale(0.28)
            stamp.alpha = 0.12
            stamp.zPosition = 0.5
            stamp.position = jitteredPoint(in: worldRect, salt: salt, index: 0, bias: .centerEast)
            root.addChild(stamp)
        }

        if district == .wichita {
            if let runway = TextureAssetLoader.sprite(role: .wichitaDecalRunwayStripe) {
                runway.alpha = 0.11
                runway.zPosition = 0.45
                runway.position = jitteredPoint(in: worldRect, salt: salt, index: 1, bias: .center)
                root.addChild(runway)
            }
            if let dust = TextureAssetLoader.sprite(role: .wichitaDecalGrainDust) {
                dust.alpha = 0.09
                dust.zPosition = 0.45
                dust.position = jitteredPoint(in: worldRect, salt: salt, index: 2, bias: .southEast)
                root.addChild(dust)
            }
            if let shadow = TextureAssetLoader.sprite(role: .wichitaOverlayAircraftShadow) {
                shadow.alpha = 0.08
                shadow.zPosition = 0.7
                shadow.position = jitteredPoint(in: worldRect, salt: salt, index: 3, bias: .north)
                root.addChild(shadow)
            }
            if let radar = TextureAssetLoader.sprite(role: .wichitaOverlayRadarSweep) {
                radar.alpha = 0.1
                radar.zPosition = 0.75
                radar.position = jitteredPoint(in: worldRect, salt: salt, index: 4, bias: .center)
                root.addChild(radar)
            }
        }

        if district == .louisville {
            if let stain = TextureAssetLoader.sprite(role: .louisvilleDecalBourbonStain) {
                stain.alpha = 0.1
                stain.zPosition = 0.45
                stain.position = jitteredPoint(in: worldRect, salt: salt, index: 1, bias: .southWest)
                root.addChild(stain)
            }
            if let wet = TextureAssetLoader.sprite(role: .louisvilleDecalWetBrick) {
                wet.alpha = 0.09
                wet.zPosition = 0.45
                wet.position = jitteredPoint(in: worldRect, salt: salt, index: 2, bias: .centerEast)
                root.addChild(wet)
            }
            if let haze = TextureAssetLoader.sprite(role: .louisvilleOverlayRiverHaze) {
                haze.alpha = 0.1
                haze.zPosition = 0.7
                haze.position = jitteredPoint(in: worldRect, salt: salt, index: 3, bias: .south)
                root.addChild(haze)
            }
            if let glint = TextureAssetLoader.sprite(role: .louisvilleOverlayHiddenCameraGlint) {
                glint.alpha = 0.11
                glint.zPosition = 0.8
                glint.position = jitteredPoint(in: worldRect, salt: salt, index: 4, bias: .center)
                root.addChild(glint)
            }
            if let redaction = TextureAssetLoader.sprite(role: .louisvilleOverlayMapRedaction) {
                redaction.alpha = 0.09
                redaction.zPosition = 0.85
                redaction.position = jitteredPoint(in: worldRect, salt: salt, index: 5, bias: .northEast)
                root.addChild(redaction)
            }
        }

        if district == .dayton {
            placeDecal(.daytonDecalGatewayScrape, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.daytonDecalTestLaneStripe, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
            placeDecal(.daytonOverlayFountainMist, alpha: 0.11, z: 0.7, worldRect: worldRect, salt: salt, index: 3, bias: .south)
            placeDecal(.daytonOverlayCopiedRoute, alpha: 0.1, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.daytonOverlayCheckpointPulse, alpha: 0.1, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .tulsa {
            placeDecal(.tulsaDecalPipelineLeak, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.tulsaDecalRouteMarking, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
            placeDecal(.tulsaOverlayRefineryHaze, alpha: 0.1, z: 0.7, worldRect: worldRect, salt: salt, index: 3, bias: .south)
            placeDecal(.tulsaOverlayBehavioralCrudeFlow, alpha: 0.1, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.tulsaOverlayNeonGlow, alpha: 0.09, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .oakland {
            placeDecal(.oaklandDecalContainerRust, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.oaklandDecalRailCrossing, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
            placeDecal(.oaklandOverlayMarineHaze, alpha: 0.1, z: 0.7, worldRect: worldRect, salt: salt, index: 3, bias: .south)
            placeDecal(.oaklandOverlayBorrowedJurisdiction, alpha: 0.1, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.oaklandOverlayContractRenewal, alpha: 0.09, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .sanFrancisco {
            placeDecal(.sanFranciscoDecalCableGroove, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.sanFranciscoDecalDampAsphalt, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
            placeDecal(.sanFranciscoOverlayFogBand, alpha: 0.055, z: 0.75, worldRect: worldRect, salt: salt, index: 3, bias: .north)
            placeDecal(.sanFranciscoOverlayPredictionHaze, alpha: 0.06, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.sanFranciscoOverlayImproperSearch, alpha: 0.06, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .columbus {
            placeDecal(.columbusDecalCapitolStripe, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .north)
            placeDecal(.columbusDecalAgencyBoundary, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southWest)
            placeDecal(.columbusOverlayJurisdictionSplit, alpha: 0.1, z: 0.8, worldRect: worldRect, salt: salt, index: 3, bias: .center)
            placeDecal(.columbusOverlayStatewideShare, alpha: 0.09, z: 0.82, worldRect: worldRect, salt: salt, index: 4, bias: .centerEast)
            placeDecal(.columbusOverlayHearingReschedule, alpha: 0.09, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .newYorkCity {
            placeDecal(.newYorkDecalWetAsphalt, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .southWest)
            placeDecal(.newYorkDecalScaffoldShadow, alpha: 0.09, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .northEast)
            placeDecal(.newYorkOverlaySubwaySteam, alpha: 0.11, z: 0.7, worldRect: worldRect, salt: salt, index: 3, bias: .south)
            placeDecal(.newYorkOverlayBoroughPhase, alpha: 0.09, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.newYorkOverlayOmnigazeFusion, alpha: 0.08, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .losAngeles {
            placeDecal(.losAngelesDecalFadedLanePaint, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.losAngelesDecalStudioSpikeMark, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southEast)
            placeDecal(.losAngelesOverlayMarineLayerHaze, alpha: 0.11, z: 0.7, worldRect: worldRect, salt: salt, index: 3, bias: .south)
            placeDecal(.losAngelesOverlayPrivateOperatorMesh, alpha: 0.1, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.losAngelesOverlayContractVoid, alpha: 0.09, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        if district == .atlanta {
            placeDecal(.atlantaDecalBeltlineStripe, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 1, bias: .center)
            placeDecal(.atlantaDecalHOABoundary, alpha: 0.1, z: 0.45, worldRect: worldRect, salt: salt, index: 2, bias: .southEast)
            placeDecal(.atlantaOverlayNetworkEcho, alpha: 0.11, z: 0.7, worldRect: worldRect, salt: salt, index: 3, bias: .south)
            placeDecal(.atlantaOverlayNationwideMesh, alpha: 0.1, z: 0.8, worldRect: worldRect, salt: salt, index: 4, bias: .center)
            placeDecal(.atlantaOverlayPublicPrivateState, alpha: 0.09, z: 0.85, worldRect: worldRect, salt: salt, index: 5, bias: .northEast)
        }

        // Prop sheet is dense art; keep it rare and faint.
        if district.definition.level <= 2 {
            placeDecal(.envPropSheetRetail, alpha: 0.1, z: 0.6, worldRect: worldRect, salt: salt, index: 9, bias: .northWest, scale: 0.22)
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
        sprite.alpha = alpha
        sprite.zPosition = z
        sprite.position = jitteredPoint(in: worldRect, salt: salt, index: index, bias: bias)
        root.addChild(sprite)
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

        if district == .louisville {
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
            return
        }

        if district == .tulsa {
            if let tower = TextureAssetLoader.sprite(role: .tulsaLandmarkDecoTower) {
                tower.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 90)
                tower.zPosition = 1.2
                root.addChild(tower)
            }
            if let watchman = TextureAssetLoader.sprite(role: .tulsaLandmarkIndustrialWatchman) {
                watchman.position = CGPoint(x: worldRect.maxX - 160, y: worldRect.midY + 40)
                watchman.zPosition = 1.25
                root.addChild(watchman)
            }
            if let derrick = TextureAssetLoader.sprite(role: .tulsaLandmarkOilDerrick) {
                derrick.position = CGPoint(x: worldRect.minX + 140, y: worldRect.maxY - 120)
                derrick.zPosition = 1.2
                root.addChild(derrick)
            }
            if let motel = TextureAssetLoader.sprite(role: .tulsaPropMotelSignFrame) {
                motel.position = CGPoint(x: worldRect.midX - 180, y: worldRect.minY + 110)
                motel.zPosition = 1.15
                root.addChild(motel)
            }
            return
        }

        if district == .dayton {
            if let flight = TextureAssetLoader.sprite(role: .daytonLandmarkEarlyFlight) {
                flight.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 90)
                flight.zPosition = 1.2
                root.addChild(flight)
            }
            if let fountain = TextureAssetLoader.sprite(role: .daytonLandmarkFountain) {
                fountain.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 100)
                fountain.zPosition = 1.1
                root.addChild(fountain)
            }
            if let lab = TextureAssetLoader.sprite(role: .daytonLandmarkNavigationLab) {
                lab.position = CGPoint(x: worldRect.minX + 140, y: worldRect.maxY - 130)
                lab.zPosition = 1.2
                root.addChild(lab)
            }
            if let gateway = TextureAssetLoader.sprite(role: .daytonPropNeighborhoodGateway) {
                gateway.position = CGPoint(x: worldRect.maxX - 160, y: worldRect.midY)
                gateway.zPosition = 1.15
                root.addChild(gateway)
            }
            return
        }

        if district == .oakland {
            if let crane = TextureAssetLoader.sprite(role: .oaklandLandmarkPortCrane) {
                crane.position = CGPoint(x: worldRect.midX + 40, y: worldRect.maxY - 90)
                crane.zPosition = 1.2
                root.addChild(crane)
            }
            if let lake = TextureAssetLoader.sprite(role: .oaklandLandmarkLakeShoreline) {
                lake.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 95)
                lake.zPosition = 1.1
                root.addChild(lake)
            }
            if let viaduct = TextureAssetLoader.sprite(role: .oaklandLandmarkTransitViaduct) {
                viaduct.position = CGPoint(x: worldRect.minX + 150, y: worldRect.maxY - 130)
                viaduct.zPosition = 1.2
                root.addChild(viaduct)
            }
            if let mural = TextureAssetLoader.sprite(role: .oaklandPropMuralWall) {
                mural.position = CGPoint(x: worldRect.maxX - 150, y: worldRect.midY)
                mural.zPosition = 1.15
                root.addChild(mural)
            }
            return
        }

        if district == .sanFrancisco {
            if let bridge = TextureAssetLoader.sprite(role: .sanFranciscoLandmarkBridge) {
                bridge.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 80)
                bridge.zPosition = 1.15
                root.addChild(bridge)
            }
            if let tower = TextureAssetLoader.sprite(role: .sanFranciscoLandmarkCommsTower) {
                tower.position = CGPoint(x: worldRect.maxX - 140, y: worldRect.maxY - 110)
                tower.zPosition = 1.25
                root.addChild(tower)
            }
            if let cable = TextureAssetLoader.sprite(role: .sanFranciscoLandmarkCableTrack) {
                cable.position = CGPoint(x: worldRect.midX - 40, y: worldRect.midY - 20)
                cable.zPosition = 1.05
                root.addChild(cable)
            }
            if let av = TextureAssetLoader.sprite(role: .sanFranciscoPropAVShell) {
                av.position = CGPoint(x: worldRect.minX + 160, y: worldRect.minY + 120)
                av.zPosition = 1.15
                root.addChild(av)
            }
            return
        }

        if district == .columbus {
            if let statehouse = TextureAssetLoader.sprite(role: .columbusLandmarkOhioStatehouse) {
                statehouse.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 90)
                statehouse.zPosition = 1.2
                root.addChild(statehouse)
            }
            if let river = TextureAssetLoader.sprite(role: .columbusLandmarkSciotoRiverfront) {
                river.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 95)
                river.zPosition = 1.1
                root.addChild(river)
            }
            if let arch = TextureAssetLoader.sprite(role: .columbusLandmarkShortNorthArch) {
                arch.position = CGPoint(x: worldRect.minX + 150, y: worldRect.maxY - 130)
                arch.zPosition = 1.2
                root.addChild(arch)
            }
            if let podium = TextureAssetLoader.sprite(role: .columbusPropPublicCommentPodium) {
                podium.position = CGPoint(x: worldRect.maxX - 150, y: worldRect.midY)
                podium.zPosition = 1.15
                root.addChild(podium)
            }
            return
        }

        if district == .newYorkCity {
            if let bridge = TextureAssetLoader.sprite(role: .newYorkLandmarkSuspensionBridge) {
                bridge.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 85)
                bridge.zPosition = 1.15
                root.addChild(bridge)
            }
            if let subway = TextureAssetLoader.sprite(role: .newYorkLandmarkSubwayEntrance) {
                subway.position = CGPoint(x: worldRect.midX - 120, y: worldRect.midY + 40)
                subway.zPosition = 1.2
                root.addChild(subway)
            }
            if let tower = TextureAssetLoader.sprite(role: .newYorkLandmarkRooftopWaterTower) {
                tower.position = CGPoint(x: worldRect.maxX - 140, y: worldRect.maxY - 120)
                tower.zPosition = 1.25
                root.addChild(tower)
            }
            if let sign = TextureAssetLoader.sprite(role: .newYorkPropDigitalSignagePanel) {
                sign.position = CGPoint(x: worldRect.minX + 150, y: worldRect.midY)
                sign.zPosition = 1.15
                root.addChild(sign)
            }
            return
        }

        if district == .losAngeles {
            if let observatory = TextureAssetLoader.sprite(role: .losAngelesLandmarkObservatoryHills) {
                observatory.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 90)
                observatory.zPosition = 1.2
                root.addChild(observatory)
            }
            if let port = TextureAssetLoader.sprite(role: .losAngelesLandmarkPortLogistics) {
                port.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 95)
                port.zPosition = 1.1
                root.addChild(port)
            }
            if let gate = TextureAssetLoader.sprite(role: .losAngelesLandmarkGatedCommunityGate) {
                gate.position = CGPoint(x: worldRect.minX + 150, y: worldRect.maxY - 130)
                gate.zPosition = 1.2
                root.addChild(gate)
            }
            if let booth = TextureAssetLoader.sprite(role: .losAngelesPropParkingBooth) {
                booth.position = CGPoint(x: worldRect.maxX - 150, y: worldRect.midY)
                booth.zPosition = 1.15
                root.addChild(booth)
            }
            return
        }

        guard district == .atlanta else { return }
        if let airport = TextureAssetLoader.sprite(role: .atlantaLandmarkAirportTerminal) {
            airport.position = CGPoint(x: worldRect.midX, y: worldRect.maxY - 85)
            airport.zPosition = 1.15
            root.addChild(airport)
        }
        if let cathedral = TextureAssetLoader.sprite(role: .atlantaLandmarkDataCenterCathedral) {
            cathedral.position = CGPoint(x: worldRect.maxX - 150, y: worldRect.maxY - 120)
            cathedral.zPosition = 1.25
            root.addChild(cathedral)
        }
        if let soundstage = TextureAssetLoader.sprite(role: .atlantaLandmarkFilmLotSoundstage) {
            soundstage.position = CGPoint(x: worldRect.minX + 150, y: worldRect.maxY - 130)
            soundstage.zPosition = 1.2
            root.addChild(soundstage)
        }
        if let gate = TextureAssetLoader.sprite(role: .atlantaLandmarkHOASubdivisionGate) {
            gate.position = CGPoint(x: worldRect.maxX - 160, y: worldRect.midY)
            gate.zPosition = 1.15
            root.addChild(gate)
        }
    }

    private func addParkingLines(to root: SKNode, bounds: WorldBounds) {
        // Sparse lot marks — only for lot/parking topology cities (M4).
        for x in stride(from: bounds.minX + 140, through: bounds.maxX - 140, by: 160) {
            let line = SKShapeNode(rectOf: CGSize(width: 2, height: 56))
            line.position = CGPoint(x: CGFloat(x), y: 0)
            line.fillColor = .white.withAlphaComponent(0.12)
            line.strokeColor = .clear
            line.zPosition = 0.4
            root.addChild(line)
        }
    }

    /// Arterial / capitol / fog cities get short lane ticks, not parking bay stripes.
    private func addLaneTicks(to root: SKNode, bounds: WorldBounds, district: DistrictID) {
        let step: Double = district == .newYorkCity || district == .sanFrancisco ? 200 : 180
        let tickHeight: CGFloat = district == .columbus ? 36 : 48
        for x in stride(from: bounds.minX + 160, through: bounds.maxX - 160, by: step) {
            let line = SKShapeNode(rectOf: CGSize(width: 1.5, height: tickHeight))
            line.position = CGPoint(x: CGFloat(x), y: CGFloat((x.truncatingRemainder(dividingBy: 2) == 0) ? 24 : -18))
            line.fillColor = .white.withAlphaComponent(0.08)
            line.strokeColor = .clear
            line.zPosition = 0.4
            root.addChild(line)
        }
    }

    /// City identity must remain readable without relying on texture detail or hue.
    /// These marks also expose infrastructure state with labels and line grammar.
    private func addCityWayfinding(in rect: CGRect, district: DistrictID, state: DistrictState?) {
        guard [.wichita, .louisville, .tulsa, .dayton, .oakland, .sanFrancisco, .columbus, .newYorkCity, .losAngeles].contains(district) else { return }
        let group = SKNode()
        group.name = "city-wayfinding-\(district.rawValue)"
        group.zPosition = 0.52
        root.addChild(group)

        switch district {
        case .wichita:
            let sensor = infrastructureStatus(nodeId: "wichita_sensor_grid", state: state)
            addGuideLine(
                to: group,
                from: CGPoint(x: rect.minX + 80, y: rect.midY),
                to: CGPoint(x: rect.maxX - 80, y: rect.midY),
                color: .white.withAlphaComponent(0.24),
                dash: 34
            )
            for (index, x) in [rect.minX + rect.width * 0.28, rect.midX, rect.minX + rect.width * 0.72].enumerated() {
                let ring = SKShapeNode(circleOfRadius: CGFloat(34 + index * 12))
                ring.position = CGPoint(x: x, y: rect.midY)
                ring.strokeColor = .systemCyan.withAlphaComponent(0.28)
                ring.lineWidth = 2
                ring.fillColor = .clear
                group.addChild(ring)
            }
            addWayfindingLabel("AIR CORRIDOR · \(sensor)", at: CGPoint(x: rect.midX, y: rect.midY + 74), to: group)

        case .louisville:
            let sensor = infrastructureStatus(nodeId: "louisville_sensor_lattice", state: state)
            for index in 0..<3 {
                let box = SKShapeNode(rectOf: CGSize(width: 190, height: 74), cornerRadius: 6)
                box.position = CGPoint(x: rect.minX + rect.width * CGFloat(0.28 + Double(index) * 0.22), y: rect.midY + CGFloat(index - 1) * 94)
                box.fillColor = SKColor(white: 0.03, alpha: 0.18)
                box.strokeColor = .white.withAlphaComponent(0.28)
                box.lineWidth = 2
                group.addChild(box)
                addWayfindingLabel("REDACTED \(index + 1)", at: box.position, to: group)
            }
            addWayfindingLabel("MAP INDEX · \(sensor)", at: CGPoint(x: rect.midX, y: rect.minY + 58), to: group)

        case .tulsa:
            let pressure = infrastructureStatus(nodeId: "tulsa_access_boom", state: state)
            for (index, y) in [rect.midY - 125, rect.midY, rect.midY + 125].enumerated() {
                addGuideLine(
                    to: group,
                    from: CGPoint(x: rect.minX + 80, y: y),
                    to: CGPoint(x: rect.maxX - 80, y: y),
                    color: .systemTeal.withAlphaComponent(0.32),
                    dash: index == 1 ? 0 : 42
                )
                for x in stride(from: rect.minX + 220, through: rect.maxX - 180, by: 320) {
                    let valve = SKShapeNode(circleOfRadius: 13)
                    valve.position = CGPoint(x: x, y: y)
                    valve.fillColor = SKColor(white: 0.08, alpha: 0.7)
                    valve.strokeColor = .white.withAlphaComponent(0.5)
                    valve.lineWidth = 2
                    group.addChild(valve)
                }
            }
            addWayfindingLabel("CRUDE FLOW → · \(pressure)", at: CGPoint(x: rect.midX, y: rect.midY + 42), to: group)

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
        label.fontSize = 15
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
        sprite.alpha = min(sprite.alpha, 0.72)
        // Prefer authored display size over full-bleed scale explosions.
        let maxEdge: CGFloat = 140
        let longest = max(sprite.size.width, sprite.size.height)
        if longest > maxEdge {
            let s = maxEdge / longest
            sprite.size = CGSize(width: sprite.size.width * s, height: sprite.size.height * s)
        }
    }
}
