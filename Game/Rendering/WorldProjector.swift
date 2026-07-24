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
            } else if factoryAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .daytonLandmarkFactory) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if pumpjackAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .tulsaLandmarkPumpjack) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if containerAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .oaklandLandmarkContainerStack) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if victorianAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .sanFranciscoLandmarkVictorian) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if hearingAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .columbusLandmarkHearingChamber) {
                sprite.position = position
                sprite.size = size
                sprite.zPosition = 1
                root.addChild(sprite)
            } else if scaffoldAvailable, index.isMultiple(of: 2),
                      let sprite = TextureAssetLoader.sprite(role: .newYorkLandmarkScaffoldShed) {
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

        if district == .dayton {
            if let scrape = TextureAssetLoader.sprite(role: .daytonDecalGatewayScrape) {
                scrape.alpha = 0.4
                scrape.zPosition = 0.45
                scrape.position = CGPoint(x: worldRect.midX - 100, y: worldRect.midY - 40)
                root.addChild(scrape)
            }
            if let lane = TextureAssetLoader.sprite(role: .daytonDecalTestLaneStripe) {
                lane.alpha = 0.5
                lane.zPosition = 0.45
                lane.position = CGPoint(x: worldRect.midX + 120, y: worldRect.midY + 80)
                root.addChild(lane)
            }
            if let mist = TextureAssetLoader.sprite(role: .daytonOverlayFountainMist) {
                mist.alpha = 0.22
                mist.zPosition = 0.7
                mist.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 130)
                root.addChild(mist)
            }
            if let route = TextureAssetLoader.sprite(role: .daytonOverlayCopiedRoute) {
                route.alpha = 0.2
                route.zPosition = 0.8
                route.position = CGPoint(x: worldRect.midX + 20, y: worldRect.midY)
                root.addChild(route)
            }
            if let pulse = TextureAssetLoader.sprite(role: .daytonOverlayCheckpointPulse) {
                pulse.alpha = 0.18
                pulse.zPosition = 0.85
                pulse.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 140)
                root.addChild(pulse)
            }
        }

        if district == .tulsa {
            if let leak = TextureAssetLoader.sprite(role: .tulsaDecalPipelineLeak) {
                leak.alpha = 0.4
                leak.zPosition = 0.45
                leak.position = CGPoint(x: worldRect.midX - 110, y: worldRect.midY - 45)
                root.addChild(leak)
            }
            if let mark = TextureAssetLoader.sprite(role: .tulsaDecalRouteMarking) {
                mark.alpha = 0.5
                mark.zPosition = 0.45
                mark.position = CGPoint(x: worldRect.midX + 110, y: worldRect.midY + 70)
                root.addChild(mark)
            }
            if let haze = TextureAssetLoader.sprite(role: .tulsaOverlayRefineryHaze) {
                haze.alpha = 0.2
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 125)
                root.addChild(haze)
            }
            if let crude = TextureAssetLoader.sprite(role: .tulsaOverlayBehavioralCrudeFlow) {
                crude.alpha = 0.18
                crude.zPosition = 0.8
                crude.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(crude)
            }
            if let neon = TextureAssetLoader.sprite(role: .tulsaOverlayNeonGlow) {
                neon.alpha = 0.16
                neon.zPosition = 0.85
                neon.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 145)
                root.addChild(neon)
            }
        }

        if district == .oakland {
            if let rust = TextureAssetLoader.sprite(role: .oaklandDecalContainerRust) {
                rust.alpha = 0.4
                rust.zPosition = 0.45
                rust.position = CGPoint(x: worldRect.midX - 120, y: worldRect.midY - 50)
                root.addChild(rust)
            }
            if let rail = TextureAssetLoader.sprite(role: .oaklandDecalRailCrossing) {
                rail.alpha = 0.5
                rail.zPosition = 0.45
                rail.position = CGPoint(x: worldRect.midX + 100, y: worldRect.midY + 70)
                root.addChild(rail)
            }
            if let haze = TextureAssetLoader.sprite(role: .oaklandOverlayMarineHaze) {
                haze.alpha = 0.2
                haze.zPosition = 0.7
                haze.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 120)
                root.addChild(haze)
            }
            if let borrow = TextureAssetLoader.sprite(role: .oaklandOverlayBorrowedJurisdiction) {
                borrow.alpha = 0.18
                borrow.zPosition = 0.8
                borrow.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(borrow)
            }
            if let renewal = TextureAssetLoader.sprite(role: .oaklandOverlayContractRenewal) {
                renewal.alpha = 0.16
                renewal.zPosition = 0.85
                renewal.position = CGPoint(x: worldRect.maxX - 190, y: worldRect.maxY - 150)
                root.addChild(renewal)
            }
        }

        if district == .sanFrancisco {
            if let groove = TextureAssetLoader.sprite(role: .sanFranciscoDecalCableGroove) {
                groove.alpha = 0.5
                groove.zPosition = 0.45
                groove.position = CGPoint(x: worldRect.midX, y: worldRect.midY - 30)
                root.addChild(groove)
            }
            if let damp = TextureAssetLoader.sprite(role: .sanFranciscoDecalDampAsphalt) {
                damp.alpha = 0.4
                damp.zPosition = 0.45
                damp.position = CGPoint(x: worldRect.midX + 120, y: worldRect.midY + 80)
                root.addChild(damp)
            }
            if let fog = TextureAssetLoader.sprite(role: .sanFranciscoOverlayFogBand) {
                fog.alpha = 0.28
                fog.zPosition = 0.75
                fog.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 40)
                root.addChild(fog)
            }
            if let predict = TextureAssetLoader.sprite(role: .sanFranciscoOverlayPredictionHaze) {
                predict.alpha = 0.16
                predict.zPosition = 0.8
                predict.position = CGPoint(x: worldRect.midX - 40, y: worldRect.midY)
                root.addChild(predict)
            }
            if let search = TextureAssetLoader.sprite(role: .sanFranciscoOverlayImproperSearch) {
                search.alpha = 0.14
                search.zPosition = 0.85
                search.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(search)
            }
        }

        if district == .columbus {
            if let stripe = TextureAssetLoader.sprite(role: .columbusDecalCapitolStripe) {
                stripe.alpha = 0.5
                stripe.zPosition = 0.45
                stripe.position = CGPoint(x: worldRect.midX, y: worldRect.midY + 30)
                root.addChild(stripe)
            }
            if let boundary = TextureAssetLoader.sprite(role: .columbusDecalAgencyBoundary) {
                boundary.alpha = 0.4
                boundary.zPosition = 0.45
                boundary.position = CGPoint(x: worldRect.midX - 130, y: worldRect.midY - 50)
                root.addChild(boundary)
            }
            if let split = TextureAssetLoader.sprite(role: .columbusOverlayJurisdictionSplit) {
                split.alpha = 0.18
                split.zPosition = 0.8
                split.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(split)
            }
            if let share = TextureAssetLoader.sprite(role: .columbusOverlayStatewideShare) {
                share.alpha = 0.16
                share.zPosition = 0.82
                share.position = CGPoint(x: worldRect.midX + 40, y: worldRect.midY + 60)
                root.addChild(share)
            }
            if let reschedule = TextureAssetLoader.sprite(role: .columbusOverlayHearingReschedule) {
                reschedule.alpha = 0.15
                reschedule.zPosition = 0.85
                reschedule.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(reschedule)
            }
        }

        if district == .newYorkCity {
            if let wet = TextureAssetLoader.sprite(role: .newYorkDecalWetAsphalt) {
                wet.alpha = 0.4
                wet.zPosition = 0.45
                wet.position = CGPoint(x: worldRect.midX - 100, y: worldRect.midY - 40)
                root.addChild(wet)
            }
            if let shadow = TextureAssetLoader.sprite(role: .newYorkDecalScaffoldShadow) {
                shadow.alpha = 0.35
                shadow.zPosition = 0.45
                shadow.position = CGPoint(x: worldRect.midX + 110, y: worldRect.midY + 50)
                root.addChild(shadow)
            }
            if let steam = TextureAssetLoader.sprite(role: .newYorkOverlaySubwaySteam) {
                steam.alpha = 0.22
                steam.zPosition = 0.7
                steam.position = CGPoint(x: worldRect.midX, y: worldRect.minY + 130)
                root.addChild(steam)
            }
            if let phase = TextureAssetLoader.sprite(role: .newYorkOverlayBoroughPhase) {
                phase.alpha = 0.16
                phase.zPosition = 0.8
                phase.position = CGPoint(x: worldRect.midX, y: worldRect.midY)
                root.addChild(phase)
            }
            if let fusion = TextureAssetLoader.sprite(role: .newYorkOverlayOmnigazeFusion) {
                fusion.alpha = 0.14
                fusion.zPosition = 0.85
                fusion.position = CGPoint(x: worldRect.maxX - 180, y: worldRect.maxY - 150)
                root.addChild(fusion)
            }
        }

        if district.definition.level <= 2 || district == .dayton || district == .tulsa || district == .oakland || district == .sanFrancisco || district == .columbus || district == .newYorkCity,
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

        guard district == .newYorkCity else { return }
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
