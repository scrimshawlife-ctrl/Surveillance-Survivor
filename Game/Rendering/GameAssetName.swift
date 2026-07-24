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

    /// Names reserved for later art families (shape fallback until attached).
    static var reservedFuture: [String] {
        [Guard.default, Boss.default, Projectile.default, Deployable.mirrorArray, Deployable.signalFlood]
    }
}
