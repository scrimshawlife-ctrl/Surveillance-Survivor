import Foundation

/// New York routes authority through five borough systems before fusing them into
/// the Real-Time City. Each health band changes pursuit while observation expands.
public enum NewYorkBoroughPhase: String, CaseIterable, Sendable {
    case manhattan = "Manhattan"
    case brooklyn = "Brooklyn"
    case queens = "Queens"
    case bronx = "Bronx"
    case statenIsland = "Staten Island"
    case realTimeCity = "Real-Time City"

    public static func resolve(health: Double, maximumHealth: Double) -> Self {
        guard maximumHealth > 0 else { return .realTimeCity }
        switch max(0, health) / maximumHealth {
        case (5.0 / 6.0)...:
            return .manhattan
        case (4.0 / 6.0)..<(5.0 / 6.0):
            return .brooklyn
        case (3.0 / 6.0)..<(4.0 / 6.0):
            return .queens
        case (2.0 / 6.0)..<(3.0 / 6.0):
            return .bronx
        case (1.0 / 6.0)..<(2.0 / 6.0):
            return .statenIsland
        default:
            return .realTimeCity
        }
    }

    public var observationMultiplier: Double {
        switch self {
        case .manhattan: 1.03
        case .brooklyn: 1.06
        case .queens: 1.09
        case .bronx: 1.12
        case .statenIsland: 1.15
        case .realTimeCity: 1.2
        }
    }

    public var movementSpeedMultiplier: Double {
        switch self {
        case .manhattan: 0.94
        case .brooklyn: 1.04
        case .queens: 0.88
        case .bronx: 1.12
        case .statenIsland: 0.8
        case .realTimeCity: 1.22
        }
    }

    public var contactDamageMultiplier: Double {
        switch self {
        case .manhattan: 1
        case .brooklyn: 1.04
        case .queens: 1.08
        case .bronx: 1.12
        case .statenIsland: 1.16
        case .realTimeCity: 1.22
        }
    }

    /// Borough routing produces recognizable approach vectors before fusion.
    public var orbitWeight: Double {
        switch self {
        case .manhattan: 0.58
        case .brooklyn: -0.42
        case .queens: 0.24
        case .bronx: -0.72
        case .statenIsland: 0.84
        case .realTimeCity: 0
        }
    }
}
