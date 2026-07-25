import Foundation

/// Presentation-only quality ladder. Never affects simulation authority.
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
}
