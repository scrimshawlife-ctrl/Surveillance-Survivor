import Foundation

/// Atlanta expands a local observation node into the campaign's nationwide
/// doctrine. The Chimera transition precedes the Safety Evangelist finale.
public enum AtlantaConvergencePhase: String, CaseIterable, Sendable {
    case localNode = "Local Node"
    case regionalPartner = "Regional Partner"
    case nationalSearch = "National Search"
    case partnershipChimera = "Partnership Chimera"
    case objectiveEvidence = "Objective Evidence Doctrine"
    case safetyEvangelist = "Safety Evangelist"

    public static func resolve(health: Double, maximumHealth: Double) -> Self {
        guard maximumHealth > 0 else { return .safetyEvangelist }
        switch max(0, health) / maximumHealth {
        case (5.0 / 6.0)...: return .localNode
        case (4.0 / 6.0)..<(5.0 / 6.0): return .regionalPartner
        case (3.0 / 6.0)..<(4.0 / 6.0): return .nationalSearch
        case (2.0 / 6.0)..<(3.0 / 6.0): return .partnershipChimera
        case (1.0 / 6.0)..<(2.0 / 6.0): return .objectiveEvidence
        default: return .safetyEvangelist
        }
    }

    public var observationMultiplier: Double {
        switch self {
        case .localNode: 1.04
        case .regionalPartner: 1.08
        case .nationalSearch: 1.12
        case .partnershipChimera: 1.16
        case .objectiveEvidence: 1.21
        case .safetyEvangelist: 1.27
        }
    }

    public var movementSpeedMultiplier: Double {
        switch self {
        case .localNode: 0.9
        case .regionalPartner: 1.02
        case .nationalSearch: 0.84
        case .partnershipChimera: 1.12
        case .objectiveEvidence: 0.96
        case .safetyEvangelist: 1.25
        }
    }

    public var contactDamageMultiplier: Double {
        switch self {
        case .localNode: 1
        case .regionalPartner: 1.05
        case .nationalSearch: 1.1
        case .partnershipChimera: 1.16
        case .objectiveEvidence: 1.22
        case .safetyEvangelist: 1.3
        }
    }

    public var orbitWeight: Double {
        switch self {
        case .localNode: 0.42
        case .regionalPartner: -0.38
        case .nationalSearch: 0.7
        case .partnershipChimera: -0.76
        case .objectiveEvidence: 0.2
        case .safetyEvangelist: 0
        }
    }
}
