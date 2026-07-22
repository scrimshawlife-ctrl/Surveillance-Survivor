import Foundation

/// Logical names for visual resources. Runtime systems should reference assets
/// through this namespace rather than embedding catalog strings throughout code.
enum GameAssetName {
    enum Player {
        static let downIdle = "player_down_idle_0"
        static let downWalk = "player_down_walk_0"
        static let leftIdle = "player_left_idle_0"
        static let leftWalk = "player_left_walk_0"
        static let upIdle = "player_up_idle_0"
        static let upWalk = "player_up_walk_0"
        static let rightIdle = "player_right_idle_0"
        static let rightWalk = "player_right_walk_0"
    }

    enum LPRCamera {
        static let intact = "lpr_intact"
        static let damaged = "lpr_damaged"
        static let destroyed = "lpr_destroyed"
    }

    enum Marketing {
        static let keyArt = "key_art_promo_banner"
        static let conceptIllustration = "concept_illustration_cinematic"
    }
}
