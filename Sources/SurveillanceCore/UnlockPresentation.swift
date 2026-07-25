import Foundation

/// Resolved presentation-only cosmetics from mastery unlocks.
/// Never affects combat stats, damage, or health.
public struct UnlockPresentationProfile: Codable, Equatable, Sendable {
    public var cosmeticPresentationIds: [String]
    public var radioLanguage: String?
    public var weatherLightingModifier: String?
    public var audioMotifId: String?
    public var unlockedItemIds: [String]

    public static let empty = UnlockPresentationProfile(
        cosmeticPresentationIds: [],
        radioLanguage: nil,
        weatherLightingModifier: nil,
        audioMotifId: nil,
        unlockedItemIds: []
    )

    public init(
        cosmeticPresentationIds: [String],
        radioLanguage: String?,
        weatherLightingModifier: String?,
        audioMotifId: String?,
        unlockedItemIds: [String]
    ) {
        self.cosmeticPresentationIds = cosmeticPresentationIds
        self.radioLanguage = radioLanguage
        self.weatherLightingModifier = weatherLightingModifier
        self.audioMotifId = audioMotifId
        self.unlockedItemIds = unlockedItemIds
    }

    public var showsLotGhostTrail: Bool {
        cosmeticPresentationIds.contains("trail_lot_ghost")
    }

    public var showsRedactionVignette: Bool {
        cosmeticPresentationIds.contains("vignette_redaction")
    }

    public var hasAnyPresentation: Bool {
        !cosmeticPresentationIds.isEmpty
            || radioLanguage != nil
            || weatherLightingModifier != nil
            || audioMotifId != nil
    }
}

public enum UnlockPresentationResolver: Sendable {
    /// Prefer the highest-threshold unlock of each kind when multiple qualify.
    public static func resolve(
        unlockedItemIds: [String],
        catalog: UnlockCatalog = .bundled
    ) -> UnlockPresentationProfile {
        let owned = Set(unlockedItemIds)
        let items = catalog.items.filter { owned.contains($0.id) }
        guard !items.isEmpty else { return .empty }

        var cosmetics: [String] = []
        var radio: String?
        var radioScore = -1
        var weather: String?
        var weatherScore = -1
        var motif: String?
        var motifScore = -1

        for item in items {
            let score = item.requiresTotalExtractions
                + item.requiresChallengeCompletions * 2
                + item.requiresDailyBestStreak * 3
            switch item.kind {
            case "cosmetic":
                if let presentationId = item.presentationId, !presentationId.isEmpty {
                    cosmetics.append(presentationId)
                }
            case "radioSet":
                if let language = item.radioLanguage, score >= radioScore {
                    radio = language
                    radioScore = score
                }
            case "weatherPack":
                if let modifier = item.weatherLightingModifier, score >= weatherScore {
                    weather = modifier
                    weatherScore = score
                }
            case "audioMotif":
                if let motifId = item.audioMotifId, score >= motifScore {
                    motif = motifId
                    motifScore = score
                }
            default:
                break
            }
        }

        return UnlockPresentationProfile(
            cosmeticPresentationIds: Array(Set(cosmetics)).sorted(),
            radioLanguage: radio,
            weatherLightingModifier: weather,
            audioMotifId: motif,
            unlockedItemIds: unlockedItemIds.sorted()
        )
    }

    public static func resolve(progress: MasteryProgress, catalog: UnlockCatalog = .bundled) -> UnlockPresentationProfile {
        resolve(unlockedItemIds: progress.unlockedItemIds, catalog: catalog)
    }
}
