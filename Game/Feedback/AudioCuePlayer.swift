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
    /// Real playback. Absent until `activateBank()` succeeds, so tests and the
    /// emulator keep the original silent dry-run behaviour.
    private var bank: AudioBank?

    func setAvailableAssets(_ assets: Set<String>) {
        availableAssets = assets
    }

    /// Loads the approved delivery bank and enables real output. Assets that fail
    /// to load stay out of `availableAssets`, so a partial bank plays what it has
    /// and stays silent for the rest rather than substituting anything.
    @discardableResult
    func activateBank() -> Set<String> {
        let bank = self.bank ?? AudioBank()
        self.bank = bank
        let loaded = bank.start()
        availableAssets.formUnion(loaded)
        return loaded
    }

    func applyAudioSettings(muted: Bool, sfxVolume: Double, musicVolume: Double,
                            ambienceVolume: Double) {
        bank?.isMuted = muted
        bank?.sfxVolume = Float(max(0, min(1, sfxVolume)))
        bank?.musicVolume = Float(max(0, min(1, musicVolume)))
        bank?.ambienceVolume = Float(max(0, min(1, ambienceVolume)))
    }

    /// Projects looping ambience and music from run state. Cheap to call every
    /// frame: the bank ignores slots whose asset has not changed.
    func applyScene(for state: RunState) {
        guard let scenes = AudioEventCatalog.bundled.scenes else { return }
        bank?.apply(AudioSceneProjector.scene(for: state, catalog: scenes))
    }

    func suspendPlayback() { bank?.suspend() }
    func resumePlayback() { bank?.resume() }

    /// Resolves cues for the given simulation tick. Returns how many cues would
    /// play if their assets were attached.
    @discardableResult
    func play(events: [RunEvent], atTick tick: UInt64, suspicionTier: SuspicionTier = .backgroundNoise,
              district: DistrictID? = nil) -> Int {
        guard isEnabled, !events.isEmpty else {
            lastResolvedRequests = []
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
            suspicionTier: suspicionTier,
            district: district
        )
        // Product audio must not use system beeps. Without an approved bank we
        // only record the resolved requests for diagnostics and tests.
        let playable = lastResolvedRequests.filter { availableAssets.contains($0.assetName) }
        bank?.play(playable)
        return playable.count
    }
}
