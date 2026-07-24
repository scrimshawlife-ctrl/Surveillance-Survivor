import CoreGraphics
import Foundation
import SurveillanceCore

/// Authoritative mapping from simulation presentation roles to runtime texture
/// names. Projection code should resolve through this map rather than hard-coding
/// strings. Missing binaries keep shape-node fallbacks.
enum VisualAssetMap {
    enum Role: String, CaseIterable, Sendable {
        case playerIdleDown
        case playerIdleLeft
        case playerIdleUp
        case playerIdleRight
        case playerWalkDown
        case playerWalkLeft
        case playerWalkUp
        case playerWalkRight
        case lprIntact
        case lprDamaged
        case lprDestroyed
        case blindSpotDecal
        case suspicionTier0
        case suspicionTier1
        case suspicionTier2
        case suspicionTier3
        case suspicionTier4
        case suspicionTier5
        case guardDefault
        case bossDefault
        case projectileDefault
        case mirrorArray
        case signalFlood
        // Environment package (optional; WorldProjector falls back to shapes)
        case envTileAsphalt
        case envTileDowntown
        case envTileGated
        case envTileCampus
        case envTileWarehouse
        case envParallaxSkyline
        case envObstacleRetailMass
        case envPropSheetMunicipal
        case envPropSheetRetail
        case envDecalSheet
        // Wichita city pack (optional)
        case wichitaTerrainArterial
        case wichitaTerrainPrairieEdge
        case wichitaSkyline
        case wichitaLandmarkMonument
        case wichitaLandmarkGrainElevator
        case wichitaLandmarkHangar
        case wichitaLandmarkBridge
        case wichitaPropTornadoSiren
        case wichitaOverlayRadarSweep
        case wichitaOverlayStormAlert
        case wichitaOverlayAircraftShadow
        case wichitaDecalRunwayStripe
        case wichitaDecalGrainDust
        // Louisville city pack
        case louisvilleTerrainBrickArterial
        case louisvilleTerrainHistoricStreet
        case louisvilleSkyline
        case louisvilleLandmarkTwinSpires
        case louisvilleLandmarkRiverfront
        case louisvilleLandmarkWarehouse
        case louisvilleLandmarkVictorian
        case louisvillePropIronGate
        case louisvilleOverlayMapRedaction
        case louisvilleOverlayHiddenCameraGlint
        case louisvilleOverlayRiverHaze
        case louisvilleDecalBourbonStain
        case louisvilleDecalWetBrick
        // Dayton city pack
        case daytonTerrainGatewayApproach
        case daytonTerrainIndustrialCorridor
        case daytonSkyline
        case daytonLandmarkEarlyFlight
        case daytonLandmarkFountain
        case daytonLandmarkFactory
        case daytonLandmarkNavigationLab
        case daytonPropNeighborhoodGateway
        case daytonOverlayCopiedRoute
        case daytonOverlayCheckpointPulse
        case daytonOverlayFountainMist
        case daytonDecalGatewayScrape
        case daytonDecalTestLaneStripe
    }

    struct Entry: Equatable, Sendable {
        let role: Role
        let assetName: String
        /// Logical presentation size in points (independent of collision radius).
        let displaySize: CGSize
        let anchor: CGPoint
        /// When false, missing binary is expected and fallback is the product look.
        let requiredForMVP: Bool
    }

    /// Full map of known presentation roles.
    static let entries: [Entry] = [
        .init(role: .playerIdleDown, assetName: GameAssetName.Player.idleDown, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerIdleLeft, assetName: GameAssetName.Player.idleLeft, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerIdleUp, assetName: GameAssetName.Player.idleUp, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerIdleRight, assetName: GameAssetName.Player.idleRight, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerWalkDown, assetName: GameAssetName.Player.walkDown, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerWalkLeft, assetName: GameAssetName.Player.walkLeft, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerWalkUp, assetName: GameAssetName.Player.walkUp, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .playerWalkRight, assetName: GameAssetName.Player.walkRight, displaySize: CGSize(width: 54, height: 72), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .lprIntact, assetName: GameAssetName.LPRCamera.intact, displaySize: CGSize(width: 48, height: 96), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .lprDamaged, assetName: GameAssetName.LPRCamera.damaged, displaySize: CGSize(width: 48, height: 96), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .lprDestroyed, assetName: GameAssetName.LPRCamera.destroyed, displaySize: CGSize(width: 48, height: 96), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: true),
        .init(role: .blindSpotDecal, assetName: GameAssetName.Environment.blindSpotDecal, displaySize: CGSize(width: 120, height: 120), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: true),
        .init(role: .suspicionTier0, assetName: GameAssetName.SuspicionTierIcon.name(for: 0), displaySize: CGSize(width: 34, height: 34), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .suspicionTier1, assetName: GameAssetName.SuspicionTierIcon.name(for: 1), displaySize: CGSize(width: 34, height: 34), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .suspicionTier2, assetName: GameAssetName.SuspicionTierIcon.name(for: 2), displaySize: CGSize(width: 34, height: 34), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .suspicionTier3, assetName: GameAssetName.SuspicionTierIcon.name(for: 3), displaySize: CGSize(width: 34, height: 34), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .suspicionTier4, assetName: GameAssetName.SuspicionTierIcon.name(for: 4), displaySize: CGSize(width: 34, height: 34), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .suspicionTier5, assetName: GameAssetName.SuspicionTierIcon.name(for: 5), displaySize: CGSize(width: 34, height: 34), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        // Guard / boss: pixel-art defaults attached; shape fallback if missing.
        .init(role: .guardDefault, assetName: GameAssetName.Guard.default, displaySize: CGSize(width: 40, height: 52), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: false),
        .init(role: .bossDefault, assetName: GameAssetName.Boss.default, displaySize: CGSize(width: 72, height: 90), anchor: CGPoint(x: 0.5, y: 0.12), requiredForMVP: false),
        // Remaining shape-first roles until art intake.
        .init(role: .projectileDefault, assetName: GameAssetName.Projectile.default, displaySize: CGSize(width: 12, height: 12), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .mirrorArray, assetName: GameAssetName.Deployable.mirrorArray, displaySize: CGSize(width: 48, height: 48), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .signalFlood, assetName: GameAssetName.Deployable.signalFlood, displaySize: CGSize(width: 96, height: 96), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        // Environment — optional production batch; not required for MVP playability.
        .init(role: .envTileAsphalt, assetName: GameAssetName.Environment.tileAsphalt, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envTileDowntown, assetName: GameAssetName.Environment.tileDowntown, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envTileGated, assetName: GameAssetName.Environment.tileGated, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envTileCampus, assetName: GameAssetName.Environment.tileCampus, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envTileWarehouse, assetName: GameAssetName.Environment.tileWarehouse, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envParallaxSkyline, assetName: GameAssetName.Environment.parallaxSkyline, displaySize: CGSize(width: 1024, height: 384), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envObstacleRetailMass, assetName: GameAssetName.Environment.obstacleRetailMass, displaySize: CGSize(width: 160, height: 100), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envPropSheetMunicipal, assetName: GameAssetName.Environment.propSheetMunicipal, displaySize: CGSize(width: 256, height: 144), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envPropSheetRetail, assetName: GameAssetName.Environment.propSheetRetail, displaySize: CGSize(width: 256, height: 160), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .envDecalSheet, assetName: GameAssetName.Environment.decalSheet, displaySize: CGSize(width: 256, height: 144), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        // Wichita — The Panopticon of the Plains
        .init(role: .wichitaTerrainArterial, assetName: GameAssetName.Wichita.terrainArterial, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaTerrainPrairieEdge, assetName: GameAssetName.Wichita.terrainPrairieEdge, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaSkyline, assetName: GameAssetName.Wichita.skyline, displaySize: CGSize(width: 1024, height: 384), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaLandmarkMonument, assetName: GameAssetName.Wichita.landmarkMonument, displaySize: CGSize(width: 72, height: 110), anchor: CGPoint(x: 0.5, y: 0.1), requiredForMVP: false),
        .init(role: .wichitaLandmarkGrainElevator, assetName: GameAssetName.Wichita.landmarkGrainElevator, displaySize: CGSize(width: 90, height: 140), anchor: CGPoint(x: 0.5, y: 0.1), requiredForMVP: false),
        .init(role: .wichitaLandmarkHangar, assetName: GameAssetName.Wichita.landmarkHangar, displaySize: CGSize(width: 180, height: 100), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaLandmarkBridge, assetName: GameAssetName.Wichita.landmarkBridge, displaySize: CGSize(width: 200, height: 80), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaPropTornadoSiren, assetName: GameAssetName.Wichita.propTornadoSiren, displaySize: CGSize(width: 28, height: 56), anchor: CGPoint(x: 0.5, y: 0.1), requiredForMVP: false),
        .init(role: .wichitaOverlayRadarSweep, assetName: GameAssetName.Wichita.overlayRadarSweep, displaySize: CGSize(width: 220, height: 220), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaOverlayStormAlert, assetName: GameAssetName.Wichita.overlayStormAlert, displaySize: CGSize(width: 400, height: 400), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaOverlayAircraftShadow, assetName: GameAssetName.Wichita.overlayAircraftShadow, displaySize: CGSize(width: 160, height: 64), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaDecalRunwayStripe, assetName: GameAssetName.Wichita.decalRunwayStripe, displaySize: CGSize(width: 120, height: 48), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .wichitaDecalGrainDust, assetName: GameAssetName.Wichita.decalGrainDust, displaySize: CGSize(width: 96, height: 96), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        // Louisville — Derby Day Data Dragnet
        .init(role: .louisvilleTerrainBrickArterial, assetName: GameAssetName.Louisville.terrainBrickArterial, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleTerrainHistoricStreet, assetName: GameAssetName.Louisville.terrainHistoricStreet, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleSkyline, assetName: GameAssetName.Louisville.skyline, displaySize: CGSize(width: 1024, height: 384), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleLandmarkTwinSpires, assetName: GameAssetName.Louisville.landmarkTwinSpires, displaySize: CGSize(width: 80, height: 120), anchor: CGPoint(x: 0.5, y: 0.1), requiredForMVP: false),
        .init(role: .louisvilleLandmarkRiverfront, assetName: GameAssetName.Louisville.landmarkRiverfront, displaySize: CGSize(width: 200, height: 90), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleLandmarkWarehouse, assetName: GameAssetName.Louisville.landmarkWarehouse, displaySize: CGSize(width: 180, height: 110), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleLandmarkVictorian, assetName: GameAssetName.Louisville.landmarkVictorian, displaySize: CGSize(width: 70, height: 110), anchor: CGPoint(x: 0.5, y: 0.1), requiredForMVP: false),
        .init(role: .louisvillePropIronGate, assetName: GameAssetName.Louisville.propIronGate, displaySize: CGSize(width: 90, height: 56), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleOverlayMapRedaction, assetName: GameAssetName.Louisville.overlayMapRedaction, displaySize: CGSize(width: 280, height: 280), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleOverlayHiddenCameraGlint, assetName: GameAssetName.Louisville.overlayHiddenCameraGlint, displaySize: CGSize(width: 200, height: 200), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleOverlayRiverHaze, assetName: GameAssetName.Louisville.overlayRiverHaze, displaySize: CGSize(width: 360, height: 360), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleDecalBourbonStain, assetName: GameAssetName.Louisville.decalBourbonStain, displaySize: CGSize(width: 96, height: 96), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .louisvilleDecalWetBrick, assetName: GameAssetName.Louisville.decalWetBrick, displaySize: CGSize(width: 96, height: 96), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        // Dayton — Gateway City: Every Camera Counts
        .init(role: .daytonTerrainGatewayApproach, assetName: GameAssetName.Dayton.terrainGatewayApproach, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonTerrainIndustrialCorridor, assetName: GameAssetName.Dayton.terrainIndustrialCorridor, displaySize: CGSize(width: 256, height: 256), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonSkyline, assetName: GameAssetName.Dayton.skyline, displaySize: CGSize(width: 1024, height: 384), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonLandmarkEarlyFlight, assetName: GameAssetName.Dayton.landmarkEarlyFlight, displaySize: CGSize(width: 72, height: 110), anchor: CGPoint(x: 0.5, y: 0.1), requiredForMVP: false),
        .init(role: .daytonLandmarkFountain, assetName: GameAssetName.Dayton.landmarkFountain, displaySize: CGSize(width: 160, height: 100), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonLandmarkFactory, assetName: GameAssetName.Dayton.landmarkFactory, displaySize: CGSize(width: 180, height: 110), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonLandmarkNavigationLab, assetName: GameAssetName.Dayton.landmarkNavigationLab, displaySize: CGSize(width: 160, height: 100), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonPropNeighborhoodGateway, assetName: GameAssetName.Dayton.propNeighborhoodGateway, displaySize: CGSize(width: 100, height: 64), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonOverlayCopiedRoute, assetName: GameAssetName.Dayton.overlayCopiedRoute, displaySize: CGSize(width: 280, height: 280), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonOverlayCheckpointPulse, assetName: GameAssetName.Dayton.overlayCheckpointPulse, displaySize: CGSize(width: 240, height: 240), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonOverlayFountainMist, assetName: GameAssetName.Dayton.overlayFountainMist, displaySize: CGSize(width: 360, height: 360), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonDecalGatewayScrape, assetName: GameAssetName.Dayton.decalGatewayScrape, displaySize: CGSize(width: 96, height: 96), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false),
        .init(role: .daytonDecalTestLaneStripe, assetName: GameAssetName.Dayton.decalTestLaneStripe, displaySize: CGSize(width: 140, height: 56), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false)
    ]

    static var byRole: [Role: Entry] {
        Dictionary(uniqueKeysWithValues: entries.map { ($0.role, $0) })
    }

    static var allAssetNames: [String] {
        entries.map(\.assetName)
    }

    static var requiredAssetNames: [String] {
        entries.filter(\.requiredForMVP).map(\.assetName)
    }

    static func entry(_ role: Role) -> Entry {
        byRole[role]!
    }

    static func playerRole(moving: Bool, direction: String) -> Role {
        switch (moving, direction) {
        case (false, "left"): return .playerIdleLeft
        case (false, "up"): return .playerIdleUp
        case (false, "right"): return .playerIdleRight
        case (false, _): return .playerIdleDown
        case (true, "left"): return .playerWalkLeft
        case (true, "up"): return .playerWalkUp
        case (true, "right"): return .playerWalkRight
        case (true, _): return .playerWalkDown
        }
    }

    /// Map simulation velocity (or last heading when idle) onto four-direction atlas roles.
    /// Simulation is Y-up; cardinal buckets keep top-down sprites readable.
    static func playerRole(velocityX: Double, velocityY: Double, heading: Double) -> Role {
        let speed = hypot(velocityX, velocityY)
        let moving = speed > 8
        let angle = moving ? atan2(velocityY, velocityX) : heading
        let deg = angle * 180 / .pi
        let direction: String
        if deg >= -45 && deg < 45 {
            direction = "right"
        } else if deg >= 45 && deg < 135 {
            direction = "up"
        } else if deg >= -135 && deg < -45 {
            direction = "down"
        } else {
            direction = "left"
        }
        return playerRole(moving: moving, direction: direction)
    }

    static func lprRole(health: Double) -> Role {
        if health <= 0 { return .lprDestroyed }
        if health < 30 { return .lprDamaged }
        return .lprIntact
    }

    static func suspicionRole(tier: Int) -> Role {
        switch min(5, max(0, tier)) {
        case 0: return .suspicionTier0
        case 1: return .suspicionTier1
        case 2: return .suspicionTier2
        case 3: return .suspicionTier3
        case 4: return .suspicionTier4
        default: return .suspicionTier5
        }
    }

    /// Primary texture role for an entity kind (state-independent default).
    static func primaryRole(for kind: EntityKind) -> Role? {
        switch kind {
        case .player: return .playerIdleDown
        case .securityGuard: return .guardDefault
        case .cameraPole: return .lprIntact
        case .projectile: return .projectileDefault
        case .boss: return .bossDefault
        case .extraction: return .blindSpotDecal
        case .mirrorArray: return .mirrorArray
        case .signalFlood: return .signalFlood
        }
    }

    /// Asset name for a role; projectors should prefer this over hard-coded strings.
    static func assetName(_ role: Role) -> String {
        entry(role).assetName
    }

    /// Ground tile role for a campaign district. Levels 1–5 map to the five
    /// environment biomes; later cities reuse the dense/downtown or asphalt kits
    /// so the package stays a single coherent city batch.
    static func terrainRole(for district: DistrictID) -> Role {
        if district == .wichita {
            return .wichitaTerrainArterial
        }
        if district == .louisville {
            return .louisvilleTerrainBrickArterial
        }
        if district == .dayton {
            return .daytonTerrainGatewayApproach
        }
        switch district.definition.level {
        case 1: return .envTileAsphalt
        case 2: return .envTileDowntown
        case 3: return .envTileGated
        case 4: return .envTileCampus
        case 5: return .envTileWarehouse
        case 6, 7: return .envTileDowntown
        case 8, 9: return .envTileDowntown
        default: return .envTileAsphalt
        }
    }

    /// Optional city skyline role when a city pack is attached.
    static func skylineRole(for district: DistrictID) -> Role {
        if district == .wichita { return .wichitaSkyline }
        if district == .louisville { return .louisvilleSkyline }
        if district == .dayton { return .daytonSkyline }
        return .envParallaxSkyline
    }
}
