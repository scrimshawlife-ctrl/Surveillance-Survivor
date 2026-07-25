import Foundation

/// P10 — city `upgradeWeightingTags` bias for upgrade drafts.
/// Explicit preference only (weighted picks); never damage/HP scaling.
public enum UpgradeOfferBias: Sendable {
    /// Relative weight for upgrades tagged with any city weighting tag.
    public static let preferredWeight = 3
    /// Relative weight for all other eligible upgrades.
    public static let neutralWeight = 1
    public static let defaultOfferCount = 3

    public static func isPreferred(
        _ choice: UpgradeChoice,
        weightingTags: [String],
        build: BuildEngineCatalog = .bundled
    ) -> Bool {
        guard !weightingTags.isEmpty else { return false }
        let tags = Set(build.tags(for: choice))
        return weightingTags.contains { tags.contains($0) }
    }

    /// Deterministic weighted sample without replacement.
    /// Preferred upgrades are `preferredWeight`× more likely than neutral ones.
    public static func pickOffers(
        eligible: [UpgradeChoice],
        weightingTags: [String],
        count: Int = defaultOfferCount,
        build: BuildEngineCatalog = .bundled,
        rng: inout DeterministicRNG
    ) -> (offers: [UpgradeChoice], preferredCount: Int) {
        guard !eligible.isEmpty, count > 0 else { return ([], 0) }
        var pool = eligible
        var picks: [UpgradeChoice] = []
        let target = min(count, pool.count)
        while picks.count < target {
            let weights = pool.map { choice -> Int in
                isPreferred(choice, weightingTags: weightingTags, build: build)
                    ? preferredWeight
                    : neutralWeight
            }
            let total = weights.reduce(0, +)
            guard total > 0 else { break }
            var roll = Int(rng.next() % UInt64(total))
            var index = 0
            for (i, weight) in weights.enumerated() {
                roll -= weight
                if roll < 0 {
                    index = i
                    break
                }
            }
            picks.append(pool.remove(at: index))
        }
        let preferred = picks.filter {
            isPreferred($0, weightingTags: weightingTags, build: build)
        }.count
        return (picks, preferred)
    }
}

/// Receipt sample for one city-biased upgrade offer (audit trail).
public struct UpgradeOfferBiasSample: Codable, Equatable, Sendable {
    public var tick: UInt64
    public var weightingTags: [String]
    public var preferredOfferedCount: Int
    public var totalOffered: Int
    public var offeredIds: [String]

    public init(
        tick: UInt64,
        weightingTags: [String],
        preferredOfferedCount: Int,
        totalOffered: Int,
        offeredIds: [String]
    ) {
        self.tick = tick
        self.weightingTags = weightingTags
        self.preferredOfferedCount = preferredOfferedCount
        self.totalOffered = totalOffered
        self.offeredIds = offeredIds
    }
}
