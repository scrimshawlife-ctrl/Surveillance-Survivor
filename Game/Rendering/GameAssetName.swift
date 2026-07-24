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

    /// Optional environment package (shape/world fallback if a build omits them).
    static var optionalEnvironment: [String] { Environment.environmentPackage }

    /// Names reserved for later art families (shape fallback until attached).
    static var reservedFuture: [String] {
        [Projectile.default, Deployable.mirrorArray, Deployable.signalFlood]
    }
}
