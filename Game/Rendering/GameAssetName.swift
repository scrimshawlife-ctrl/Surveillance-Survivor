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
    }

    enum LPRCamera {
        static let intact = "lpr_intact"
        static let damaged = "lpr_damaged"
        static let destroyed = "lpr_destroyed"
    }

    enum SuspicionTierIcon {
        static func name(for tier: Int) -> String {
            "suspicion_tier_\(min(5, max(0, tier)))"
        }
    }

    enum Environment {
        static let blindSpotDecal = "blind_spot_decal"
    }

    enum Marketing {
        static let keyArt = "key_art_promo_banner"
        static let conceptIllustration = "concept_illustration_cinematic"
    }
}
