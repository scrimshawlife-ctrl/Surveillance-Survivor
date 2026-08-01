import Foundation
import SurveillanceCore

/// Maps deterministic run events to approved audio assets. The full bank is
/// activated explicitly by the app so tests and unsupported environments stay silent.
@MainActor
final class AudioCuePlayer {
    var isEnabled = true

    private var resolver = AudioCueResolver()
    private var assetBank: AudioAssetBank
    private let backend: AudioPlaybackBackend
    private var bank: AudioBank?
    private(set) var lastResolvedRequests: [AudioCueResolver.Request] = []
    private(set) var lastPlayedRequests: [AudioCueResolver.Request] = []
    /// App-driven playback suspension intent. This remains observable even when
    /// no bank is active, which keeps lifecycle behavior deterministic in tests.
    private(set) var isPlaybackSuspended = false

    var availableAssets: Set<String> {
        assetBank.availableAssets.union(bank?.loadedAssetNames ?? [])
    }

    init(
        assetBank: AudioAssetBank = AudioAssetBank(entries: []),
        backend: AudioPlaybackBackend = AVFoundationAudioPlaybackBackend()
    ) {
        self.assetBank = assetBank
        self.backend = backend
    }

    func setAssetBank(_ assetBank: AudioAssetBank) {
        self.assetBank = assetBank
    }

    /// Loads the approved delivery bank and enables real output. Assets that fail
    /// to load remain silent rather than being replaced with placeholders.
    @discardableResult
    func activateBank() -> Set<String> {
        let bank = self.bank ?? AudioBank()
        self.bank = bank
        let loaded = bank.start()
        if isPlaybackSuspended {
            bank.suspend()
        }
        return loaded
    }

    func applyAudioSettings(
        muted: Bool,
        sfxVolume: Double,
        musicVolume: Double,
        ambienceVolume: Double
    ) {
        bank?.isMuted = muted
        bank?.sfxVolume = Float(max(0, min(1, sfxVolume)))
        bank?.musicVolume = Float(max(0, min(1, musicVolume)))
        bank?.ambienceVolume = Float(max(0, min(1, ambienceVolume)))
    }

    /// Projects looping ambience and music from run state. The bank ignores
    /// unchanged slots, so calling this every frame does not restart loops.
    func applyScene(for state: RunState) {
        guard let scenes = AudioEventCatalog.bundled.scenes else { return }
        bank?.apply(AudioSceneProjector.scene(for: state, catalog: scenes))
    }

    func suspendPlayback() {
        isPlaybackSuspended = true
        bank?.suspend()
    }

    func resumePlayback() {
        isPlaybackSuspended = false
        bank?.resume()
    }

    /// Resolves cues and sends only approved, available assets to playback.
    @discardableResult
    func play(
        events: [RunEvent],
        atTick tick: UInt64,
        suspicionTier: SuspicionTier = .backgroundNoise,
        district: DistrictID? = nil
    ) -> Int {
        guard isEnabled, !events.isEmpty else {
            lastResolvedRequests = []
            lastPlayedRequests = []
            return 0
        }

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
            suspicionTier: suspicionTier,
            district: district
        )
        lastPlayedRequests = []

        if let bank {
            lastPlayedRequests = bank.play(lastResolvedRequests)
        } else {
            for request in lastResolvedRequests {
                guard let entry = assetBank.entry(for: request.assetName) else { continue }
                backend.play(url: entry.url, gain: request.gain)
                lastPlayedRequests.append(request)
            }
        }

        return lastPlayedRequests.count
    }
}
