import Foundation

/// Local campaign unlock state. Pure value type so the core can enforce order
/// without reading UserDefaults or files from the fixed-step loop.
public struct CampaignProgress: Codable, Equatable, Sendable {
    public static let schemaVersion = 1

    /// Highest campaign level the player may enter (1...district count).
    public var highestUnlockedLevel: Int
    /// Districts that have completed a successful Blind Spot extraction.
    public var completedDistricts: [DistrictID]
    /// Last district that finished a run (win or defeat).
    public var lastPlayedDistrict: DistrictID?

    public static var initial: CampaignProgress {
        CampaignProgress(
            highestUnlockedLevel: DistrictID.campaignOpener.definition.level,
            completedDistricts: [],
            lastPlayedDistrict: nil
        )
    }

    public init(
        highestUnlockedLevel: Int,
        completedDistricts: [DistrictID],
        lastPlayedDistrict: DistrictID?
    ) {
        self.highestUnlockedLevel = highestUnlockedLevel
        self.completedDistricts = completedDistricts
        self.lastPlayedDistrict = lastPlayedDistrict
    }

    public var maxCampaignLevel: Int { DistrictCatalog.bundled.districts.map(\.level).max() ?? 1 }

    /// Campaign districts ordered by roster level.
    public static var orderedDistricts: [DistrictDefinition] {
        DistrictCatalog.bundled.districts.sorted { $0.level < $1.level }
    }

    public func isUnlocked(_ id: DistrictID) -> Bool {
        id.definition.level <= highestUnlockedLevel
    }

    public var unlockedDistricts: [DistrictDefinition] {
        Self.orderedDistricts.filter { isUnlocked($0.id) }
    }

    /// Next district to offer after a successful extraction of `district`.
    /// Returns the same district if it is the campaign finale.
    public func nextDistrict(after district: DistrictID) -> DistrictID {
        let nextLevel = district.definition.level + 1
        return Self.orderedDistricts.first { $0.level == nextLevel }?.id ?? district
    }

    public mutating func recordRunOutcome(district: DistrictID, extractionCompleted: Bool) {
        lastPlayedDistrict = district
        guard extractionCompleted else { return }

        if !completedDistricts.contains(district) {
            completedDistricts.append(district)
        }

        let completedLevel = district.definition.level
        if completedLevel >= highestUnlockedLevel {
            highestUnlockedLevel = min(completedLevel + 1, maxCampaignLevel)
        }
    }

    /// Clamps a preferred district selection onto something currently unlocked.
    /// Locked preferences fall through to the highest unlocked campaign city.
    public func resolveSelection(_ preferred: DistrictID?) -> DistrictID {
        if let preferred, isUnlocked(preferred) {
            return preferred
        }
        return unlockedDistricts.last?.id ?? .campaignOpener
    }
}
