import CoreGraphics
import Foundation
import SurveillanceCore

/// Presentation-only quality ladder. Never affects simulation authority.
/// Shared by `PresentationPipeline`, `EntityProjector`, and camera follow.
enum PresentationQualityTier: String, CaseIterable, Sendable, Equatable {
    case full
    case reduced
    case minimal

    /// Derives a tier from accessibility toggles without mutating gameplay.
    static func resolve(reducedMotion: Bool, reducedFlash: Bool, forced: PresentationQualityTier? = nil) -> PresentationQualityTier {
        if let forced { return forced }
        if reducedMotion { return .minimal }
        if reducedFlash { return .reduced }
        return .full
    }

    /// 0…1 blend of previous→current snapshot. Full uses true alpha; reduced snaps more; minimal snaps.
    func snapshotBlend(rawAlpha: CGFloat) -> CGFloat {
        let a = max(0, min(1, rawAlpha))
        switch self {
        case .full: return a
        case .reduced: return a < 0.5 ? 0 : 1
        case .minimal: return 1
        }
    }

    var secondaryMotionScale: CGFloat {
        switch self {
        case .full: 1
        case .reduced: 0.35
        case .minimal: 0
        }
    }

    var allowCameraSmoothing: Bool {
        self == .full
    }

    /// Softens scan cones / flood fills when the field is crowded.
    /// Crowd bands are presentation-only; the high band is calibrated to
    /// `CombatLimits.maximumProjectiles` so soft-out aligns with existing caps,
    /// without changing sim spawn/cull behavior.
    func densityScale(entityCount: Int) -> CGFloat {
        let projectileCap = CombatLimits.maximumProjectiles
        let crowd: CGFloat
        switch entityCount {
        case ..<(projectileCap / 2):
            crowd = 1.0
        case (projectileCap / 2)..<((projectileCap * 3) / 4):
            crowd = 0.85
        case ((projectileCap * 3) / 4)..<projectileCap:
            crowd = 0.7
        default:
            crowd = 0.55
        }
        switch self {
        case .full:
            return crowd
        case .reduced:
            return crowd * 0.85
        case .minimal:
            // Prefer calmer area FX under reduced motion / flash.
            return min(crowd, 0.7) * 0.75
        }
    }
}
