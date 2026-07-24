import CoreGraphics
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test func visualAssetMapRolesAreUniqueAndCovered() {
    let roles = VisualAssetMap.entries.map(\.role)
    #expect(Set(roles).count == roles.count)
    #expect(Set(roles) == Set(VisualAssetMap.Role.allCases))
}

@Test func visualAssetMapAssetNamesAreUnique() {
    let names = VisualAssetMap.allAssetNames
    #expect(Set(names).count == names.count)
}

@Test func visualAssetMapRequiredAssetsMatchAttachedMVPSprites() {
    let required = Set(VisualAssetMap.requiredAssetNames)
    let expected: Set<String> = [
        "player_idle_down", "player_idle_left", "player_idle_up", "player_idle_right",
        "player_walk_down", "player_walk_left", "player_walk_up", "player_walk_right",
        "lpr_intact", "lpr_damaged", "lpr_destroyed",
        "blind_spot_decal"
    ]
    #expect(required == expected)
}

@Test func visualAssetMapPlayerFacingBuckets() {
    // Right / idle uses heading when nearly still.
    #expect(VisualAssetMap.playerRole(velocityX: 0, velocityY: 0, heading: 0) == .playerIdleRight)
    #expect(VisualAssetMap.playerRole(velocityX: 0, velocityY: 0, heading: .pi / 2) == .playerIdleUp)
    #expect(VisualAssetMap.playerRole(velocityX: 0, velocityY: 0, heading: .pi) == .playerIdleLeft)
    #expect(VisualAssetMap.playerRole(velocityX: 0, velocityY: 0, heading: -.pi / 2) == .playerIdleDown)

    // Moving prefers velocity over heading.
    #expect(VisualAssetMap.playerRole(velocityX: 40, velocityY: 0, heading: .pi) == .playerWalkRight)
    #expect(VisualAssetMap.playerRole(velocityX: 0, velocityY: 40, heading: 0) == .playerWalkUp)
    #expect(VisualAssetMap.playerRole(velocityX: -40, velocityY: 0, heading: 0) == .playerWalkLeft)
    #expect(VisualAssetMap.playerRole(velocityX: 0, velocityY: -40, heading: 0) == .playerWalkDown)
}

@Test func visualAssetMapLPRHealthRoles() {
    #expect(VisualAssetMap.lprRole(health: 60) == .lprIntact)
    #expect(VisualAssetMap.lprRole(health: 29) == .lprDamaged)
    #expect(VisualAssetMap.lprRole(health: 0) == .lprDestroyed)
    #expect(VisualAssetMap.lprRole(health: -1) == .lprDestroyed)
}

@Test func visualAssetMapSuspicionTierClamps() {
    #expect(VisualAssetMap.suspicionRole(tier: -3) == .suspicionTier0)
    #expect(VisualAssetMap.suspicionRole(tier: 0) == .suspicionTier0)
    #expect(VisualAssetMap.suspicionRole(tier: 3) == .suspicionTier3)
    #expect(VisualAssetMap.suspicionRole(tier: 5) == .suspicionTier5)
    #expect(VisualAssetMap.suspicionRole(tier: 99) == .suspicionTier5)
    #expect(VisualAssetMap.assetName(.suspicionTier2) == "suspicion_tier_2")
}

@Test func visualAssetMapPrimaryRolesCoverEntityKinds() {
    let kinds: [EntityKind] = [
        .player, .securityGuard, .cameraPole, .projectile,
        .boss, .extraction, .mirrorArray, .signalFlood
    ]
    for kind in kinds {
        #expect(VisualAssetMap.primaryRole(for: kind) != nil)
    }
}

@Test func visualAssetMapPlayerEntriesMatchAtlasManifest() {
    let mapNames = Set(
        VisualAssetMap.entries
            .filter { $0.role.rawValue.hasPrefix("player") }
            .map(\.assetName)
    )
    let atlasNames = Set(PlayerAtlasManifest.sequences.map(\.assetName))
    #expect(mapNames == atlasNames)
    #expect(PlayerAtlasManifest.validate())
}

@Test func visualAssetMapGameAssetNameNamespacesAlign() {
    for name in GameAssetName.Player.all {
        #expect(VisualAssetMap.allAssetNames.contains(name))
    }
    for name in GameAssetName.LPRCamera.all {
        #expect(VisualAssetMap.allAssetNames.contains(name))
    }
    for name in GameAssetName.SuspicionTierIcon.all {
        #expect(VisualAssetMap.allAssetNames.contains(name))
    }
    #expect(VisualAssetMap.assetName(.blindSpotDecal) == GameAssetName.Environment.blindSpotDecal)
    for name in GameAssetName.optionalEntitySprites {
        #expect(VisualAssetMap.allAssetNames.contains(name))
        #expect(!VisualAssetMap.requiredAssetNames.contains(name))
    }
    for name in GameAssetName.reservedFuture {
        #expect(VisualAssetMap.allAssetNames.contains(name))
        #expect(!VisualAssetMap.requiredAssetNames.contains(name))
    }
}
