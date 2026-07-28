import Foundation

/// Authoritative, city-specific phase identity for an active boss encounter.
/// Presentation consumes this value but never derives phase thresholds itself.
public struct BossPhase: Codable, Equatable, Sendable {
    public var district: DistrictID
    public var id: String
    public var displayName: String
    public var ordinal: Int
    public var count: Int

    public init(district: DistrictID, id: String, displayName: String, ordinal: Int, count: Int) {
        self.district = district
        self.id = id
        self.displayName = displayName
        self.ordinal = ordinal
        self.count = count
    }

    public static func resolve(district: DistrictID, health: Double, maximumHealth: Double) -> BossPhase? {
        switch district {
        case .sanFrancisco:
            return make(SanFranciscoPolicyPhase.resolve(health: health, maximumHealth: maximumHealth), district: district)
        case .columbus:
            return make(ColumbusReviewPhase.resolve(health: health, maximumHealth: maximumHealth), district: district)
        case .newYorkCity:
            return make(NewYorkBoroughPhase.resolve(health: health, maximumHealth: maximumHealth), district: district)
        case .losAngeles:
            return make(LosAngelesLiabilityPhase.resolve(health: health, maximumHealth: maximumHealth), district: district)
        case .atlanta:
            return make(AtlantaConvergencePhase.resolve(health: health, maximumHealth: maximumHealth), district: district)
        default:
            return nil
        }
    }

    private static func make<Phase: RawRepresentable & CaseIterable>(_ phase: Phase, district: DistrictID) -> BossPhase
    where Phase.RawValue == String, Phase.AllCases: RandomAccessCollection, Phase.AllCases.Element == Phase {
        let phases = Array(Phase.allCases)
        let ordinal = phases.firstIndex(where: { $0.rawValue == phase.rawValue }) ?? 0
        return BossPhase(
            district: district,
            id: phase.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"),
            displayName: phase.rawValue,
            ordinal: ordinal,
            count: phases.count
        )
    }
}

public struct BossPhaseSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var phase: BossPhase

    public init(tick: UInt64, phase: BossPhase) {
        self.tick = tick
        self.phase = phase
    }
}
