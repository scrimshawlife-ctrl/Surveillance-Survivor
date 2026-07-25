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
        in scene: SKScene
    ) {
        let key = "\(district.rawValue)|\(layout.bounds.minX),\(layout.bounds.minY),\(layout.bounds.maxX),\(layout.bounds.maxY)|\(layout.obstacles.count)|\(landmark.isPlayerInside)|\(landmark.activeEncounterId ?? "-")"
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
        ring.strokeColor = .cyan.withAlphaComponent(landmark.isPlayerInside ? 0.55 : 0.22)
        ring.fillColor = .cyan.withAlphaComponent(landmark.isPlayerInside ? 0.08 : 0.03)
        ring.lineWidth = landmark.isPlayerInside ? 2.5 : 1.25
        ring.zPosition = 0.9
        ring.glowWidth = 0
        root.addChild(ring)
    }

    private func updateLandmarkZone(district: DistrictID, landmark: LandmarkEncounterState) {
        guard let ring = root.childNode(withName: "landmark-zone") as? SKShapeNode else { return }
        ring.strokeColor = .cyan.withAlphaComponent(landmark.isPlayerInside ? 0.55 : 0.22)
        ring.fillColor = .cyan.withAlphaComponent(landmark.isPlayerInside ? 0.08 : 0.03)
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
            return SKColor(red: 0.12, green: 0.125, blue: 0.13, alpha: 1) // prairie dry asphalt
        case .louisville:
            return SKColor(red: 0.105, green: 0.11, blue: 0.13, alpha: 1) // wet brick cool
        case .tulsa:
            return SKColor(red: 0.13, green: 0.115, blue: 0.11, alpha: 1) // warm industrial
        case .dayton:
            return SKColor(red: 0.11, green: 0.12, blue: 0.135, alpha: 1) // overcast research
        case .oakland:
            return SKColor(red: 0.1, green: 0.12, blue: 0.135, alpha: 1) // marine cool
        case .sanFrancisco:
            return SKColor(red: 0.1, green: 0.115, blue: 0.14, alpha: 1) // fog cool
        case .columbus:
            return SKColor(red: 0.12, green: 0.12, blue: 0.125, alpha: 1) // fluorescent civic
        case .newYorkCity:
            return SKColor(red: 0.105, green: 0.11, blue: 0.125, alpha: 1) // steam/scaffold
        case .losAngeles:
            return SKColor(red: 0.135, green: 0.125, blue: 0.11, alpha: 1) // sunbleached warm
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
        // Sparse, low-alpha stamps only — city terrain already provides identity.
        if let stamp = TextureAssetLoader.sprite(role: .envDecalSheet) {
            stamp.setScale(0.28)
            stamp.alpha = 0.12
            stamp.zPosition = 0.5
            stamp.position = CGPoint(x: worldRect.midX + 180, y: worldRect.midY - 120)
            root.addChild(stamp)
        }

        if district == .wichita {
            if let runway = TextureAssetLoader.sprite(role: .wichitaDecalRunwayStripe) {
                runway.alpha = 0.11
                runway.zPosition = 0.45
                runway.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 40)
                root.addChild(runway)
            }
            if let dust = TextureAssetLoader.sprite(role: .wichitaDecalGrainDust) {
                dust.alpha = 0.09
                dust.zPosition = 0.45
                dust.position = CGPoint(x: worldRect.maxX - 220, y: worldRect.minY + 180)
                root.addChild(dust)
            }
            if let shadow = TextureAssetLoader.sprite(role: .wichitaOverlayAircraftShadow) {
                shadow.alpha = 0.08
                shadow.zPosition = 0.7
                shadow.position = CGPoint(x: worldRect.midX - 100, y: worldRect.midY + 160)
                root.addChild(shadow)
            }
            if let radar = TextureAssetLoader.sprite(role: .wichitaOverlayRadarSweep) {
                radar.alpha = 0.1
                radar.zPosition = 0.75
                radar.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(radar)
            }
        }

        if district == .louisville {
            if let stain = TextureAssetLoader.sprite(role: .louisvilleDecalBourbonStain) {
                stain.alpha = 0.1
                stain.zPosition = 0.45
                stain.position = CGPoint(x: worldRect.midX - 160, y: worldRect.midY - 80)
                root.addChild(stain)
            }
            if let wet = TextureAssetLoader.sprite(role: .louisvilleDecalWetBrick) {
                wet.alpha = 0.09
                wet.zPosition = 0.45
                wet.position = CGPoint(x: worldRect.midX + 140, y: worldRect.midY + 60)
                root.addChild(wet)
            }
            if let haze = TextureAssetLoader.sprite(role: .louisvilleOverlayRiverHaze) {
                haze.alpha = 0.1
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 120)
                root.addChild(haze)
            }
            if let glint = TextureAssetLoader.sprite(role: .louisvilleOverlayHiddenCameraGlint) {
                glint.alpha = 0.11
                glint.zPosition = 0.8
                glint.position = CGPoint(x: worldRect.midX + 40, y: worldRect.midY + 40)
                root.addChild(glint)
            }
            if let redaction = TextureAssetLoader.sprite(role: .louisvilleOverlayMapRedaction) {
                redaction.alpha = 0.09
                redaction.zPosition = 0.85
                redaction.position = CGPoint(x: worldRect.maxX - 200, y: worldRect.maxY - 160)
                root.addChild(redaction)
            }
        }

        if district == .dayton {
            if let scrape = TextureAssetLoader.sprite(role: .daytonDecalGatewayScrape) {
                scrape.alpha = 0.1
                scrape.zPosition = 0.45
                scrape.position = CGPoint(x: worldRect.midX - 100, y: worldRect.midY - 40)
                root.addChild(scrape)
            }
            if let lane = TextureAssetLoader.sprite(role: .daytonDecalTestLaneStripe) {
                lane.alpha = 0.1
                lane.zPosition = 0.45
                lane.position = CGPoint(x: worldRect.midX + 120, y: worldRect.midY + 80)
                root.addChild(lane)
            }
            if let mist = TextureAssetLoader.sprite(role: .daytonOverlayFountainMist) {
                mist.alpha = 0.11
                mist.zPosition = 0.7
                mist.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 130)
                root.addChild(mist)
            }
            if let route = TextureAssetLoader.sprite(role: .daytonOverlayCopiedRoute) {
                route.alpha = 0.1
                route.zPosition = 0.8
                route.position = CGPoint(x: worldRect.midX + 20, y: worldRect.midY)
                root.addChild(route)
            }
            if let pulse = TextureAssetLoader.sprite(role: .daytonOverlayCheckpointPulse) {
                pulse.alpha = 0.1
                pulse.zPosition = 0.85
                pulse.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 140)
                root.addChild(pulse)
            }
        }

        if district == .tulsa {
            if let leak = TextureAssetLoader.sprite(role: .tulsaDecalPipelineLeak) {
                leak.alpha = 0.1
                leak.zPosition = 0.45
                leak.position = CGPoint(x: worldRect.midX - 110, y: worldRect.midY - 45)
                root.addChild(leak)
            }
            if let mark = TextureAssetLoader.sprite(role: .tulsaDecalRouteMarking) {
                mark.alpha = 0.1
                mark.zPosition = 0.45
                mark.position = CGPoint(x: worldRect.midX + 110, y: worldRect.midY + 70)
                root.addChild(mark)
            }
            if let haze = TextureAssetLoader.sprite(role: .tulsaOverlayRefineryHaze) {
                haze.alpha = 0.1
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 125)
                root.addChild(haze)
            }
            if let crude = TextureAssetLoader.sprite(role: .tulsaOverlayBehavioralCrudeFlow) {
                crude.alpha = 0.1
                crude.zPosition = 0.8
                crude.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(crude)
            }
            if let neon = TextureAssetLoader.sprite(role: .tulsaOverlayNeonGlow) {
                neon.alpha = 0.09
                neon.zPosition = 0.85
                neon.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 145)
                root.addChild(neon)
            }
        }

        if district == .oakland {
            if let rust = TextureAssetLoader.sprite(role: .oaklandDecalContainerRust) {
                rust.alpha = 0.1
                rust.zPosition = 0.45
                rust.position = CGPoint(x: worldRect.midX - 120, y: worldRect.midY - 50)
                root.addChild(rust)
            }
            if let rail = TextureAssetLoader.sprite(role: .oaklandDecalRailCrossing) {
                rail.alpha = 0.1
                rail.zPosition = 0.45
                rail.position = CGPoint(x: worldRect.midX + 100, y: worldRect.midY + 70)
                root.addChild(rail)
            }
            if let haze = TextureAssetLoader.sprite(role: .oaklandOverlayMarineHaze) {
                haze.alpha = 0.1
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 120)
                root.addChild(haze)
            }
            if let borrow = TextureAssetLoader.sprite(role: .oaklandOverlayBorrowedJurisdiction) {
                borrow.alpha = 0.1
                borrow.zPosition = 0.8
                borrow.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(borrow)
            }
            if let renewal = TextureAssetLoader.sprite(role: .oaklandOverlayContractRenewal) {
                renewal.alpha = 0.09
                renewal.zPosition = 0.85
                renewal.position = CGPoint(x: worldRect.maxX - 190, y: worldRect.maxY - 150)
                root.addChild(renewal)
            }
        }

        if district == .sanFrancisco {
            if let groove = TextureAssetLoader.sprite(role: .sanFranciscoDecalCableGroove) {
                groove.alpha = 0.1
                groove.zPosition = 0.45
                groove.position = CGPoint(x: worldRect.midX, y: worldRect.midY - 30)
                root.addChild(groove)
            }
            if let damp = TextureAssetLoader.sprite(role: .sanFranciscoDecalDampAsphalt) {
                damp.alpha = 0.1
                damp.zPosition = 0.45
                damp.position = CGPoint(x: worldRect.midX + 120, y: worldRect.midY + 80)
                root.addChild(damp)
            }
            if let fog = TextureAssetLoader.sprite(role: .sanFranciscoOverlayFogBand) {
                fog.alpha = 0.08
                fog.zPosition = 0.75
                fog.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 40)
                root.addChild(fog)
            }
            if let predict = TextureAssetLoader.sprite(role: .sanFranciscoOverlayPredictionHaze) {
                predict.alpha = 0.09
                predict.zPosition = 0.8
                predict.position = CGPoint(x: worldRect.midX - 40, y: worldRect.midY)
                root.addChild(predict)
            }
            if let search = TextureAssetLoader.sprite(role: .sanFranciscoOverlayImproperSearch) {
                search.alpha = 0.08
                search.zPosition = 0.85
                search.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(search)
            }
        }

        if district == .columbus {
            if let stripe = TextureAssetLoader.sprite(role: .columbusDecalCapitolStripe) {
                stripe.alpha = 0.1
                stripe.zPosition = 0.45
                stripe.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 30)
                root.addChild(stripe)
            }
            if let boundary = TextureAssetLoader.sprite(role: .columbusDecalAgencyBoundary) {
                boundary.alpha = 0.1
                boundary.zPosition = 0.45
                boundary.position = CGPoint(x: worldRect.midX - 130, y: worldRect.midY - 50)
                root.addChild(boundary)
            }
            if let split = TextureAssetLoader.sprite(role: .columbusOverlayJurisdictionSplit) {
                split.alpha = 0.1
                split.zPosition = 0.8
                split.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(split)
            }
            if let share = TextureAssetLoader.sprite(role: .columbusOverlayStatewideShare) {
                share.alpha = 0.09
                share.zPosition = 0.82
                share.position = CGPoint(x: worldRect.midX + 40, y: worldRect.midY + 60)
                root.addChild(share)
            }
            if let reschedule = TextureAssetLoader.sprite(role: .columbusOverlayHearingReschedule) {
                reschedule.alpha = 0.09
                reschedule.zPosition = 0.85
                reschedule.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(reschedule)
            }
        }

        if district == .newYorkCity {
            if let wet = TextureAssetLoader.sprite(role: .newYorkDecalWetAsphalt) {
                wet.alpha = 0.1
                wet.zPosition = 0.45
                wet.position = CGPoint(x: worldRect.midX - 100, y: worldRect.midY - 40)
                root.addChild(wet)
            }
            if let shadow = TextureAssetLoader.sprite(role: .newYorkDecalScaffoldShadow) {
                shadow.alpha = 0.09
                shadow.zPosition = 0.45
                shadow.position = CGPoint(x: worldRect.midX + 110, y: worldRect.midY + 50)
                root.addChild(shadow)
            }
            if let steam = TextureAssetLoader.sprite(role: .newYorkOverlaySubwaySteam) {
                steam.alpha = 0.11
                steam.zPosition = 0.7
                steam.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 130)
                root.addChild(steam)
            }
            if let phase = TextureAssetLoader.sprite(role: .newYorkOverlayBoroughPhase) {
                phase.alpha = 0.09
                phase.zPosition = 0.8
                phase.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(phase)
            }
            if let fusion = TextureAssetLoader.sprite(role: .newYorkOverlayOmnigazeFusion) {
                fusion.alpha = 0.08
                fusion.zPosition = 0.85
                fusion.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(fusion)
            }
        }

        if district == .losAngeles {
            if let lane = TextureAssetLoader.sprite(role: .losAngelesDecalFadedLanePaint) {
                lane.alpha = 0.1
                lane.zPosition = 0.45
                lane.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 20)
                root.addChild(lane)
            }
            if let spike = TextureAssetLoader.sprite(role: .losAngelesDecalStudioSpikeMark) {
                spike.alpha = 0.1
                spike.zPosition = 0.45
                spike.position = CGPoint(x: worldRect.midX + 110, y: worldRect.midY - 40)
                root.addChild(spike)
            }
            if let haze = TextureAssetLoader.sprite(role: .losAngelesOverlayMarineLayerHaze) {
                haze.alpha = 0.11
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 120)
                root.addChild(haze)
            }
            if let mesh = TextureAssetLoader.sprite(role: .losAngelesOverlayPrivateOperatorMesh) {
                mesh.alpha = 0.1
                mesh.zPosition = 0.8
                mesh.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(mesh)
            }
            if let contractVoid = TextureAssetLoader.sprite(role: .losAngelesOverlayContractVoid) {
                contractVoid.alpha = 0.09
                contractVoid.zPosition = 0.85
                contractVoid.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(contractVoid)
            }
        }

        if district == .atlanta {
            if let stripe = TextureAssetLoader.sprite(role: .atlantaDecalBeltlineStripe) {
                stripe.alpha = 0.1
                stripe.zPosition = 0.45
                stripe.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 20)
                root.addChild(stripe)
            }
            if let boundary = TextureAssetLoader.sprite(role: .atlantaDecalHOABoundary) {
                boundary.alpha = 0.1
                boundary.zPosition = 0.45
                boundary.position = CGPoint(x: worldRect.midX + 110, y: worldRect.midY - 40)
                root.addChild(boundary)
            }
            if let echo = TextureAssetLoader.sprite(role: .atlantaOverlayNetworkEcho) {
                echo.alpha = 0.11
                echo.zPosition = 0.7
                echo.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 120)
                root.addChild(echo)
            }
            if let mesh = TextureAssetLoader.sprite(role: .atlantaOverlayNationwideMesh) {
                mesh.alpha = 0.1
                mesh.zPosition = 0.8
                mesh.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(mesh)
            }
            if let publicPrivate = TextureAssetLoader.sprite(role: .atlantaOverlayPublicPrivateState) {
                publicPrivate.alpha = 0.09
                publicPrivate.zPosition = 0.85
                publicPrivate.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(publicPrivate)
            }
        }

        // Prop sheet is dense art; keep it rare and faint.
        if district.definition.level <= 2,
           let prop = TextureAssetLoader.sprite(role: .envPropSheetRetail) {
            prop.setScale(0.22)
            prop.alpha = 0.1
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
