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

    /// World-space effects that describe the ground rather than a body: boss
    /// telegraphs and redaction fields. Below every entity, so a telegraph reads as
    /// something the boss is standing on and a field never masks what it affects.
    static let groundEffect: CGFloat = 1.5
    /// Effects that happen *to* something: impact sparks, the Blind Spot opening.
    /// Above projectiles so a hit is never hidden by the shot that caused it.
    static let overlayEffect: CGFloat = 40

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

    // Cones now draw each sensor's real detection volume, so some are larger than
    // the old one-size wedge and several can overlap. Weight moved from fill to
    // edge: what the player needs is where detection *stops*, and a boundary reads
    // better as a line than as stacked translucent fills washing the floor.
    static func hostileConeFill(densityScale: CGFloat) -> SKColor {
        .systemRed.withAlphaComponent(0.08 * densityScale)
    }

    static func hostileConeStroke(densityScale: CGFloat) -> SKColor {
        .systemRed.withAlphaComponent(0.58 * densityScale)
    }

    static func spoofConeFill(densityScale: CGFloat) -> SKColor {
        .systemCyan.withAlphaComponent(0.10 * densityScale)
    }

    static func spoofConeStroke(densityScale: CGFloat) -> SKColor {
        .systemCyan.withAlphaComponent(0.55 * densityScale)
    }

    /// Cool teal haze — deliberately not FOIA `systemYellow` (Art QA F-P3-01).
    static func floodFill(reducedFlash: Bool, densityScale: CGFloat) -> SKColor {
        if reducedFlash {
            return .systemTeal.withAlphaComponent(0.07)
        }
        return SKColor(red: 0.22, green: 0.70, blue: 0.76, alpha: 0.16 * densityScale)
    }

    static func floodStroke(reducedFlash: Bool, densityScale: CGFloat) -> SKColor {
        if reducedFlash {
            return .systemTeal.withAlphaComponent(0.28)
        }
        return SKColor(red: 0.28, green: 0.78, blue: 0.82, alpha: 0.50 * densityScale)
    }

    static func landmarkZoneStroke(inside: Bool) -> SKColor {
        landmarkZoneCyan.withAlphaComponent(inside ? 0.4 : 0.18)
    }

    static func landmarkZoneFill(inside: Bool) -> SKColor {
        landmarkZoneCyan.withAlphaComponent(inside ? 0.05 : 0.02)
    }

    /// Non-color status grammar for processing vs disrupt (Art QA F-P2-02).
    /// Dash pattern + silhouette differ even if color vision is limited.
    enum StatusRingKind: String, Sendable {
        case processing
        case disrupt
    }

    static func statusRingKind(processing: Bool, disrupted: Bool) -> StatusRingKind? {
        if processing { return .processing }
        if disrupted { return .disrupt }
        return nil
    }

    /// Rounded stamp (processing) vs open ellipse (disrupt).
    static func statusRingPath(kind: StatusRingKind, radius: CGFloat = 18) -> CGPath {
        switch kind {
        case .processing:
            let side = radius * 2
            return CGPath(
                roundedRect: CGRect(x: -radius, y: -radius, width: side, height: side),
                cornerWidth: 4,
                cornerHeight: 4,
                transform: nil
            )
        case .disrupt:
            return CGPath(
                ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
                transform: nil
            )
        }
    }

    static func statusRingStroke(kind: StatusRingKind) -> SKColor {
        switch kind {
        case .processing: return processingTint
        case .disrupt: return disruptTint
        }
    }

    static func statusRingLineWidth(kind: StatusRingKind) -> CGFloat {
        switch kind {
        case .processing: return 2.5
        case .disrupt: return 2.0
        }
    }
}
