import Foundation
import SurveillanceCore

/// Maps run events to cataloged cues. Playback stays disabled until approved
/// audio assets exist — this never falls back to system/placeholder sounds.
@MainActor
final class AudioCuePlayer {
    var isEnabled = true

    private var resolver = AudioCueResolver()
    private(set) var lastResolvedRequests: [AudioCueResolver.Request] = []
    /// Asset names the bank is known to contain. Empty means silent dry-run mode.
    private(set) var availableAssets: Set<String> = []

    func setAvailableAssets(_ assets: Set<String>) {
        availableAssets = assets
    }

    /// Resolves cues for the given simulation tick. Returns how many cues would
    /// play if their assets were attached.
    @discardableResult
    func play(events: [RunEvent], atTick tick: UInt64) -> Int {
        guard isEnabled, !events.isEmpty else {
            lastResolvedRequests = []
            return 0
        }
        lastResolvedRequests = resolver.resolve(events: events, atTick: tick)
        // Product audio must not use system beeps. Without an approved bank we
        // only record the resolved requests for diagnostics and tests.
        return lastResolvedRequests.filter { availableAssets.contains($0.assetName) }.count
    }
}
