import Foundation

/// Los Angeles transfers responsibility across public and private operators as
/// the producer loses health. Observation expands even while ownership vanishes.
public enum LosAngelesLiabilityPhase: String, CaseIterable, Sendable {
    case cityStatement = "City Statement"
    case privateOperator = "Private Operator"
    case vendor = "Vendor"
    case subcontractor = "Subcontractor"
    case noResponsibleParty = "No Responsible Party"

    public static func resolve(health: Double, maximumHealth: Double) -> Self {
        guard maximumHealth > 0 else { return .noResponsibleParty }
        switch max(0, health) / maximumHealth {
        case 0.8...: return .cityStatement
        case 0.6..<0.8: return .privateOperator
        case 0.4..<0.6: return .vendor
        case 0.2..<0.4: return .subcontractor
        default: return .noResponsibleParty
        }
    }

    public var observationMultiplier: Double {
        switch self {
        case .cityStatement: 1.04
        case .privateOperator: 1.07
        case .vendor: 1.1
        case .subcontractor: 1.14
        case .noResponsibleParty: 1.19
        }
    }

    public var movementSpeedMultiplier: Double {
        switch self {
        case .cityStatement: 0.9
        case .privateOperator: 1.05
        case .vendor: 0.84
        case .subcontractor: 1.14
        case .noResponsibleParty: 1.23
        }
    }

    public var contactDamageMultiplier: Double {
        switch self {
        case .cityStatement: 1
        case .privateOperator: 1.05
        case .vendor: 1.09
        case .subcontractor: 1.14
        case .noResponsibleParty: 1.21
        }
    }

    public var orbitWeight: Double {
        switch self {
        case .cityStatement: 0.5
        case .privateOperator: -0.4
        case .vendor: 0.76
        case .subcontractor: -0.68
        case .noResponsibleParty: 0
        }
    }
}
