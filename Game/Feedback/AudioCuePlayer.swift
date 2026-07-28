import Foundation
import SurveillanceCore

/// Maps run events to cataloged cues. Playback stays silent unless approved
/// audio assets are discovered in the app bundle; no system/placeholder sounds.
@MainActor
final class AudioCuePlayer {
    var isEnabled = true

    private var resolver = AudioCueResolver()
    private var assetBank: AudioAssetBank
    private let backend: AudioPlaybackBackend
    private(set) var lastResolvedRequests: [AudioCueResolver.Request] = []
    private(set) var lastPlayedRequests: [AudioCueResolver.Request] = []
    var availableAssets: Set<String> { assetBank.availableAssets }

    init(assetBank: AudioAssetBank = AudioAssetBank(), backend: AudioPlaybackBackend = AVFoundationAudioPlaybackBackend()) {
        self.assetBank = assetBank
        self.backend = backend
    }

    func setAssetBank(_ assetBank: AudioAssetBank) {
        self.assetBank = assetBank
    }

    /// Resolves cues for the given simulation tick and plays only cues with approved
    /// bundle assets. Returns the number of real playback requests sent to the backend.
    @discardableResult
    func play(events: [RunEvent], atTick tick: UInt64, suspicionTier: SuspicionTier = .backgroundNoise) -> Int {
        guard isEnabled, !events.isEmpty else {
            lastResolvedRequests = []
            lastPlayedRequests = []
            return 0
        }
        // Coalesce same-tick stingers: completion beats open; defeat beats damage.
        var playbackEvents = events
        if playbackEvents.contains(where: { $0.kind == .extractionCompleted }) {
            playbackEvents = playbackEvents.filter { $0.kind != .extractionOpened }
        }
        if playbackEvents.contains(where: { $0.kind == .playerDefeated }) {
            playbackEvents = playbackEvents.filter { $0.kind != .playerDamaged }
        }
        lastResolvedRequests = resolver.resolve(
            events: playbackEvents,
            atTick: tick,
            suspicionTier: suspicionTier
        )
        lastPlayedRequests = []
        for request in lastResolvedRequests {
            guard let entry = assetBank.entry(for: request.assetName) else { continue }
            backend.play(url: entry.url, gain: request.gain)
            lastPlayedRequests.append(request)
        }
        return lastPlayedRequests.count
    }
}
