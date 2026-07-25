import CoreGraphics
import SpriteKit
import SurveillanceCore

/// Presentation z-order constants shared by existing projectors
/// (`EntityProjector`, `WorldProjector`, `GhostTrailPresenter`).
/// Simulation never reads these values. Not a second render pipeline.
enum VisualCombatLayers {
    /// Soft landmark encounter ring — under combat entities.
    static let landmarkZone: CGFloat = 0.85

    static let deployable: CGFloat = 16
    static let securityGuard: CGFloat = 20
    static let cameraPole: CGFloat = 21
    static let boss: CGFloat = 22
    static let extraction: CGFloat = 24
    /// Matches prior GhostTrailPresenter constant (25).
    static let ghostTrail: CGFloat = 25
    /// Matches prior EntityProjector player layer (30).
    static let player: CGFloat = 30
    /// Above bodies so shots never hide under guards.
    static let projectile: CGFloat = 35

    /// Extends the previous binary `player ? 30 : 20` hierarchy without
    /// inventing a new scene graph.
    static func entityLayer(for kind: EntityKind) -> CGFloat {
        switch kind {
        case .player: return player
        case .projectile: return projectile
        case .securityGuard: return securityGuard
        case .cameraPole: return cameraPole
        case .boss: return boss
        case .extraction: return extraction
        case .mirrorArray, .signalFlood: return deployable
        }
    }
}

/// Shared SpriteKit combat colors used by `EntityProjector` fallbacks and
/// cone/flood soft-out. HUD stays on `VisualDesignTokens` (SwiftUI).
/// Avoid pure `systemPurple` as a primary category color (collides with status).
enum VisualCombatPalette {
    static let playerStroke = SKColor(red: 0.35, green: 0.85, blue: 0.9, alpha: 1)
    static let playerFill = SKColor.white
    static let processingTint = SKColor(red: 0.75, green: 0.45, blue: 0.95, alpha: 1)
    static let disruptTint = SKColor.systemYellow
    /// Municipal charcoal + alarm red badge (replaces purple boss fill).
    static let bossFill = SKColor(red: 0.22, green: 0.24, blue: 0.28, alpha: 1)
    static let bossStroke = SKColor(red: 0.9, green: 0.25, blue: 0.28, alpha: 1)
    static let kineticFill = SKColor.cyan
    static let redactionFill = SKColor.black
    static let redactionStroke = SKColor.cyan
    static let spoofFill = SKColor.systemCyan.withAlphaComponent(0.55)
    static let foiaFill = SKColor.systemYellow
    /// Dim cyan so landmark rings do not compete with Blind Spot extraction cyan.
    static let landmarkZoneCyan = SKColor(red: 0.35, green: 0.75, blue: 0.85, alpha: 1)

    static func hostileConeFill(densityScale: CGFloat) -> SKColor {
        .systemRed.withAlphaComponent(0.12 * densityScale)
    }

    static func hostileConeStroke(densityScale: CGFloat) -> SKColor {
        .systemRed.withAlphaComponent(0.45 * densityScale)
    }

    static func spoofConeFill(densityScale: CGFloat) -> SKColor {
        .systemCyan.withAlphaComponent(0.10 * densityScale)
    }

    static func spoofConeStroke(densityScale: CGFloat) -> SKColor {
        .systemCyan.withAlphaComponent(0.55 * densityScale)
    }

    static func floodFill(reducedFlash: Bool, densityScale: CGFloat) -> SKColor {
        if reducedFlash {
            return .systemTeal.withAlphaComponent(0.08)
        }
        return .systemYellow.withAlphaComponent(0.18 * densityScale)
    }

    static func floodStroke(reducedFlash: Bool, densityScale: CGFloat) -> SKColor {
        if reducedFlash {
            return .systemTeal.withAlphaComponent(0.32)
        }
        return .systemYellow.withAlphaComponent(0.55 * densityScale)
    }

    static func landmarkZoneStroke(inside: Bool) -> SKColor {
        landmarkZoneCyan.withAlphaComponent(inside ? 0.4 : 0.18)
    }

    static func landmarkZoneFill(inside: Bool) -> SKColor {
        landmarkZoneCyan.withAlphaComponent(inside ? 0.05 : 0.02)
    }

    /// Density softens area effects so stacked fields don't white-out the field.
    static func densityScale(entityCount: Int) -> CGFloat {
        switch entityCount {
        case ..<40: return 1.0
        case 40..<70: return 0.85
        case 70..<100: return 0.7
        default: return 0.55
        }
    }
}
