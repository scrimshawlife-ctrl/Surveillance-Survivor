import Foundation

/// San Francisco's authority encounter reframes each health band as a new policy
/// while continuing to expand observation. The names are presentation-safe and
/// the multipliers are explicit simulation levers, not hidden difficulty scaling.
public enum SanFranciscoPolicyPhase: String, CaseIterable, Sendable {
    case publicSafety = "Public Safety"
    case civilLiberties = "Civil Liberties"
    case temporarySafeguard = "Temporary Safeguard"
    case independentReview = "Independent Review"

    public static func resolve(health: Double, maximumHealth: Double) -> Self {
        guard maximumHealth > 0 else { return .independentReview }
        switch max(0, health) / maximumHealth {
        case 0.75...:
            return .publicSafety
        case 0.5..<0.75:
            return .civilLiberties
        case 0.25..<0.5:
            return .temporarySafeguard
        default:
            return .independentReview
        }
    }

    /// Every phase expands observation, even when its language sounds protective.
    public var observationMultiplier: Double {
        switch self {
        case .publicSafety: 1.05
        case .civilLiberties: 1.08
        case .temporarySafeguard: 1.12
        case .independentReview: 1.16
        }
    }

    public var movementSpeedMultiplier: Double {
        switch self {
        case .publicSafety: 1
        case .civilLiberties: 0.9
        case .temporarySafeguard: 1.18
        case .independentReview: 1.04
        }
    }

    public var contactDamageMultiplier: Double {
        switch self {
        case .publicSafety: 1
        case .civilLiberties: 1.04
        case .temporarySafeguard: 1.1
        case .independentReview: 1.16
        }
    }

    /// A non-zero weight makes the authority circle while claiming restraint.
    public var orbitWeight: Double {
        switch self {
        case .publicSafety: 0
        case .civilLiberties: 0.72
        case .temporarySafeguard: 0.18
        case .independentReview: -0.55
        }
    }
}
