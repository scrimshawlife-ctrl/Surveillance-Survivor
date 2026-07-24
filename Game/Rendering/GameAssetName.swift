import Foundation

/// Logical names for visual resources. Runtime systems should reference assets
/// through this namespace rather than embedding catalog strings throughout code.
enum GameAssetName {
    enum Player {
        static let idleDown = "player_idle_down"
        static let idleLeft = "player_idle_left"
        static let idleUp = "player_idle_up"
        static let idleRight = "player_idle_right"
        static let walkDown = "player_walk_down"
        static let walkLeft = "player_walk_left"
        static let walkUp = "player_walk_up"
        static let walkRight = "player_walk_right"

        static var all: [String] {
            [idleDown, idleLeft, idleUp, idleRight, walkDown, walkLeft, walkUp, walkRight]
        }
    }

    enum LPRCamera {
        static let intact = "lpr_intact"
        static let damaged = "lpr_damaged"
        static let destroyed = "lpr_destroyed"

        static var all: [String] { [intact, damaged, destroyed] }
    }

    enum SuspicionTierIcon {
        static func name(for tier: Int) -> String {
            "suspicion_tier_\(min(5, max(0, tier)))"
        }

        static var all: [String] { (0...5).map { name(for: $0) } }
    }

    enum Environment {
        static let blindSpotDecal = "blind_spot_decal"

        // Seamless ground tiles (256²) — district biomes
        static let tileAsphalt = "env_tile_asphalt"
        static let tileDowntown = "env_tile_downtown"
        static let tileGated = "env_tile_gated"
        static let tileCampus = "env_tile_campus"
        static let tileWarehouse = "env_tile_warehouse"

        static let parallaxSkyline = "env_parallax_skyline"
        static let obstacleRetailMass = "env_obstacle_retail_mass"
        static let propSheetMunicipal = "env_prop_sheet_municipal"
        static let propSheetRetail = "env_prop_sheet_retail"
        static let decalSheet = "env_decal_sheet"

        static var terrainTiles: [String] {
            [tileAsphalt, tileDowntown, tileGated, tileCampus, tileWarehouse]
        }

        static var environmentPackage: [String] {
            terrainTiles + [
                parallaxSkyline, obstacleRetailMass,
                propSheetMunicipal, propSheetRetail, decalSheet
            ]
        }
    }

    /// City-specific packs (optional). Naming: `{city}_{role}_{variant}_{nn}`.
    enum Wichita {
        // Runtime presentation assets only (identity/palette boards live under docs/).
        static let terrainArterial = "wichita_terrain_asphalt_arterial_01"
        static let terrainPrairieEdge = "wichita_terrain_prairie_edge_01"
        static let skyline = "wichita_skyline_parallax_01"
        static let landmarkMonument = "wichita_landmark_river_monument_distant_01"
        static let landmarkGrainElevator = "wichita_landmark_grain_elevator_midground_01"
        static let landmarkHangar = "wichita_landmark_aircraft_hangar_01"
        static let landmarkBridge = "wichita_landmark_bridge_span_01"
        static let propTornadoSiren = "wichita_prop_tornado_siren_01"
        static let overlayRadarSweep = "wichita_overlay_radar_sweep_01"
        static let overlayStormAlert = "wichita_overlay_storm_alert_01"
        static let overlayAircraftShadow = "wichita_overlay_aircraft_shadow_01"
        static let decalRunwayStripe = "wichita_decal_runway_stripe_01"
        static let decalGrainDust = "wichita_decal_grain_dust_01"

        static var all: [String] {
            [
                terrainArterial, terrainPrairieEdge, skyline,
                landmarkMonument, landmarkGrainElevator, landmarkHangar, landmarkBridge,
                propTornadoSiren, overlayRadarSweep, overlayStormAlert, overlayAircraftShadow,
                decalRunwayStripe, decalGrainDust
            ]
        }
    }

    enum Guard {
        static let `default` = "guard_default"
    }

    enum Boss {
        static let `default` = "boss_default"
    }

    enum Projectile {
        static let `default` = "projectile_default"
    }

    enum Deployable {
        static let mirrorArray = "deployable_mirror_array"
        static let signalFlood = "deployable_signal_flood"
    }

    enum Marketing {
        static let keyArt = "key_art_promo_banner"
        static let conceptIllustration = "concept_illustration_cinematic"
    }

    /// Names the intake contract treats as optional glyph replacements.
    static var optionalSuspicionTier: [String] { SuspicionTierIcon.all }

    /// Attached optional entity sprites (shape fallback if a build omits them).
    static var optionalEntitySprites: [String] {
        [Guard.default, Boss.default]
    }

    /// City pack — Louisville (Derby Day Data Dragnet). Docs boards are not runtime.
    enum Louisville {
        static let terrainBrickArterial = "louisville_terrain_brick_arterial_01"
        static let terrainHistoricStreet = "louisville_terrain_historic_street_01"
        static let skyline = "louisville_skyline_parallax_01"
        static let landmarkTwinSpires = "louisville_landmark_twin_spires_distant_01"
        static let landmarkRiverfront = "louisville_landmark_riverfront_floodwall_01"
        static let landmarkWarehouse = "louisville_landmark_bourbon_warehouse_01"
        static let landmarkVictorian = "louisville_landmark_victorian_facade_01"
        static let propIronGate = "louisville_prop_wrought_iron_gate_01"
        static let overlayMapRedaction = "louisville_overlay_map_redaction_01"
        static let overlayHiddenCameraGlint = "louisville_overlay_hidden_camera_glint_01"
        static let overlayRiverHaze = "louisville_overlay_river_haze_01"
        static let decalBourbonStain = "louisville_decal_bourbon_stain_01"
        static let decalWetBrick = "louisville_decal_wet_brick_01"

        static var all: [String] {
            [
                terrainBrickArterial, terrainHistoricStreet, skyline,
                landmarkTwinSpires, landmarkRiverfront, landmarkWarehouse, landmarkVictorian,
                propIronGate, overlayMapRedaction, overlayHiddenCameraGlint, overlayRiverHaze,
                decalBourbonStain, decalWetBrick
            ]
        }
    }

    /// Optional environment package (shape/world fallback if a build omits them).
    static var optionalEnvironment: [String] {
        Environment.environmentPackage + Wichita.all + Louisville.all
    }

    /// Names reserved for later art families (shape fallback until attached).
    static var reservedFuture: [String] {
        [Projectile.default, Deployable.mirrorArray, Deployable.signalFlood]
    }
}
