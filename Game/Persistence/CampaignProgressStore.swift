import Foundation
import SurveillanceCore

/// Persists campaign unlocks offline. Simulation never reads this store.
final class CampaignProgressStore {
    static let storageKey = "surveillance.campaignProgress"

    private let defaults: UserDefaults
    private(set) var progress: CampaignProgress

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode(CampaignProgress.self, from: data) {
            progress = decoded
        } else {
            progress = .initial
        }
    }

    func save(_ progress: CampaignProgress) {
        self.progress = progress
        guard let data = try? JSONEncoder().encode(progress) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    @discardableResult
    func applyRunOutcome(district: DistrictID, extractionCompleted: Bool) -> CampaignProgress {
        var updated = progress
        updated.recordRunOutcome(district: district, extractionCompleted: extractionCompleted)
        save(updated)
        return updated
    }
}
