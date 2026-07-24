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
        .init(role: .signalFlood, assetName: GameAssetName.Deployable.signalFlood, displaySize: CGSize(width: 96, height: 96), anchor: CGPoint(x: 0.5, y: 0.5), requiredForMVP: false)
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
}
