import Foundation

/// Columbus turns each authority health band into another procedural review state.
/// Every state retains an observation expansion while changing pursuit and contact.
public enum ColumbusReviewPhase: String, CaseIterable, Sendable {
    case publicComment = "Public Comment"
    case meaningfulReview = "Meaningful Review"
    case rescheduled = "Rescheduled"
    case routeTransfer = "Route Transfer"

    public static func resolve(health: Double, maximumHealth: Double) -> Self {
        guard maximumHealth > 0 else { return .routeTransfer }
        switch max(0, health) / maximumHealth {
        case 0.75...:
            return .publicComment
        case 0.5..<0.75:
            return .meaningfulReview
        case 0.25..<0.5:
            return .rescheduled
        default:
            return .routeTransfer
        }
    }

    public var observationMultiplier: Double {
        switch self {
        case .publicComment: 1.04
        case .meaningfulReview: 1.07
        case .rescheduled: 1.11
        case .routeTransfer: 1.15
        }
    }

    public var movementSpeedMultiplier: Double {
        switch self {
        case .publicComment: 0.92
        case .meaningfulReview: 1
        case .rescheduled: 0.84
        case .routeTransfer: 1.17
        }
    }

    public var contactDamageMultiplier: Double {
        switch self {
        case .publicComment: 1
        case .meaningfulReview: 1.05
        case .rescheduled: 1.09
        case .routeTransfer: 1.15
        }
    }

    /// Route changes visibly alter pursuit direction, not just numeric pressure.
    public var orbitWeight: Double {
        switch self {
        case .publicComment: 0.62
        case .meaningfulReview: 0.18
        case .rescheduled: -0.7
        case .routeTransfer: 0
        }
    }
}
