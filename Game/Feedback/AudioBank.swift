import AVFoundation
import Foundation
import SurveillanceCore

/// Loads the approved delivery bank and plays resolved cues through per-bus mixers.
///
/// The simulation stays authoritative: this reads `AudioCueResolver.Request` values
/// and never influences `RunState`. Buffers are loaded once at start-up so the
/// fixed-step path performs no file I/O.
@MainActor
final class AudioBank {
    /// Voice ceiling per bus. Mirrors the storm risk in the event map: mirror arrays
    /// can emit dozens of `countermeasureHit` events per second, and the resolver's
    /// cooldowns thin but do not eliminate that.
    private static let voicesPerBus: [AudioBus: Int] = [.sfx: 8, .ui: 4, .music: 2]

    private let engine = AVAudioEngine()
    private var busMixers: [AudioBus: AVAudioMixerNode] = [:]
    private var players: [AudioBus: [AVAudioPlayerNode]] = [:]
    private var nextVoice: [AudioBus: Int] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var started = false

    /// Looping slots. Each holds two nodes so a scene change crossfades rather
    /// than cutting: one plays out while the other fades in.
    private enum LoopSlot: CaseIterable { case ambience, music, overlay }
    private var loopNodes: [LoopSlot: [AVAudioPlayerNode]] = [:]
    private var loopActive: [LoopSlot: Int] = [:]
    private var loopAsset: [LoopSlot: String?] = [:]
    private var loopTarget: [LoopSlot: Float] = [:]

    private(set) var loadedAssetNames: Set<String> = []

    var isMuted = false {
        didSet { applyLevels() }
    }
    var sfxVolume: Float = 1.0 {
        didSet { applyLevels() }
    }
    var musicVolume: Float = 1.0 {
        didSet { applyLevels() }
    }

    // MARK: - Lifecycle

    /// Loads every `.caf` in the delivery bank and starts the engine.
    /// Returns the asset names that resolved, so the caller can gate playback on
    /// what genuinely exists rather than on what the catalog hopes for.
    @discardableResult
    func start() -> Set<String> {
        guard !started else { return loadedAssetNames }
        configureSession()
        buildGraph()
        loadBank()
        do {
            try engine.start()
            started = true
        } catch {
            // A dead engine must not take the game down; the run continues silent.
            NSLog("AudioBank: engine failed to start — \(error.localizedDescription)")
            return []
        }
        applyLevels()
        observeInterruptions()
        let expected = Set(AudioEventCatalog.bundled.cues.map(\.assetName))
        let missing = expected.subtracting(loadedAssetNames).sorted()
        NSLog("AudioBank: started — \(loadedAssetNames.count)/\(expected.count) cue assets loaded"
              + (missing.isEmpty ? "" : ", missing: \(missing.joined(separator: ", "))"))
        return loadedAssetNames
    }

    func stop() {
        guard started else { return }
        engine.stop()
        started = false
    }

    /// Interruption and background handling: pause the graph without tearing down
    /// buffers so resume is instant.
    func suspend() {
        guard started else { return }
        engine.pause()
    }

    func resume() {
        guard started else { return }
        do {
            try engine.start()
        } catch {
            NSLog("AudioBank: resume failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Playback

    func play(_ requests: [AudioCueResolver.Request]) {
        guard started, !isMuted else { return }
        for request in requests {
            guard let buffer = buffers[request.assetName] else { continue }
            guard let voice = checkoutVoice(on: request.bus) else { continue }
            voice.volume = Float(max(0, min(1.5, request.gain)))
            voice.stop()
            voice.scheduleBuffer(buffer, at: nil, options: .interrupts)
            voice.play()
        }
    }

    /// Applies a projected scene. Unchanged slots are left alone so a loop keeps
    /// playing across ticks instead of restarting every frame.
    func apply(_ scene: AudioScene) {
        guard started else { return }
        set(.ambience, scene.ambience)
        set(.music, scene.music)
        set(.overlay, scene.overlay)
    }

    private func set(_ slot: LoopSlot, _ asset: String?) {
        guard (loopAsset[slot] ?? nil) != asset else { return }
        loopAsset[slot] = asset
        guard let pair = loopNodes[slot] else { return }
        let activeIndex = loopActive[slot] ?? 0
        let outgoing = pair[activeIndex]
        let incoming = pair[1 - activeIndex]
        loopActive[slot] = 1 - activeIndex

        fade(outgoing, to: 0, over: Self.crossfadeSeconds, stopAfter: true)
        guard let asset, let buffer = buffers[asset] else { return }
        incoming.stop()
        incoming.volume = 0
        incoming.scheduleBuffer(buffer, at: nil, options: [.loops])
        incoming.play()
        fade(incoming, to: loopTarget[slot] ?? 1.0, over: Self.crossfadeSeconds, stopAfter: false)
    }

    private static let crossfadeSeconds = 1.5

    /// Ramps a node's volume in small steps. Cheap and adequate for scene changes,
    /// which are rare compared with one-shot cues.
    private func fade(_ node: AVAudioPlayerNode, to target: Float,
                      over seconds: Double, stopAfter: Bool) {
        let steps = 30
        let start = node.volume
        for step in 1...steps {
            let delay = seconds * Double(step) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak node] in
                guard let node else { return }
                node.volume = start + (target - start) * Float(step) / Float(steps)
                if stopAfter, step == steps, target == 0 { node.stop() }
            }
        }
    }

    /// Round-robins the bus pool. Oldest voice is reused when the pool is saturated,
    /// which is the standard trade: a clipped tail beats a dropped cue.
    private func checkoutVoice(on bus: AudioBus) -> AVAudioPlayerNode? {
        guard let pool = players[bus], !pool.isEmpty else { return nil }
        if let idle = pool.first(where: { !$0.isPlaying }) {
            return idle
        }
        let index = (nextVoice[bus] ?? 0) % pool.count
        nextVoice[bus] = index + 1
        return pool[index]
    }

    // MARK: - Setup

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            // `.ambient` respects the hardware silent switch and leaves other apps'
            // audio playing — correct for a premium offline single-player title with
            // no voice content.
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            NSLog("AudioBank: session setup failed — \(error.localizedDescription)")
        }
    }

    private func buildGraph() {
        let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 2)
        for bus in [AudioBus.sfx, .ui, .music] {
            let mixer = AVAudioMixerNode()
            engine.attach(mixer)
            engine.connect(mixer, to: engine.mainMixerNode, format: format)
            busMixers[bus] = mixer

            var pool: [AVAudioPlayerNode] = []
            for _ in 0..<(Self.voicesPerBus[bus] ?? 4) {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: mixer, format: format)
                pool.append(node)
            }
            players[bus] = pool
            nextVoice[bus] = 0
        }
        // Two looping nodes per slot, routed to the bus that slot belongs to.
        for slot in LoopSlot.allCases {
            let bus: AudioBus = slot == .music ? .music : .sfx
            var pair: [AVAudioPlayerNode] = []
            for _ in 0..<2 {
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: busMixers[bus] ?? engine.mainMixerNode, format: format)
                node.volume = 0
                pair.append(node)
            }
            loopNodes[slot] = pair
            loopActive[slot] = 0
            loopAsset[slot] = nil
            loopTarget[slot] = slot == .ambience ? 0.9 : 1.0
        }
        engine.prepare()
    }

    private func loadBank() {
        // Delivery derivatives are flattened into the bundle root by the resources
        // build phase, so look them up by name rather than by path.
        var wanted = Set(AudioEventCatalog.bundled.cues.map(\.assetName))
        if let scenes = AudioEventCatalog.bundled.scenes {
            wanted.formUnion(scenes.districts.flatMap { definition -> [String] in
                var names = [definition.ambienceAsset, definition.runAsset]
                if let boss = definition.bossAsset { names.append(boss) }
                names.append(contentsOf: definition.bossPhaseAssets ?? [])
                return names
            })
            if let overlay = scenes.overlayExtractionAsset { wanted.insert(overlay) }
            if let sweep = scenes.scanSweepAsset { wanted.insert(sweep) }
        }
        for name in wanted.sorted() {
            guard let url = Bundle.main.url(forResource: name, withExtension: "caf")
                ?? Bundle.main.url(forResource: name, withExtension: "wav") else { continue }
            guard let file = try? AVAudioFile(forReading: url) else { continue }
            let format = file.processingFormat
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                                frameCapacity: AVAudioFrameCount(file.length)) else { continue }
            do {
                try file.read(into: buffer)
                buffers[name] = buffer
                loadedAssetNames.insert(name)
            } catch {
                NSLog("AudioBank: failed to read \(name) — \(error.localizedDescription)")
            }
        }
    }

    private func applyLevels() {
        let master: Float = isMuted ? 0 : 1
        busMixers[.sfx]?.outputVolume = master * sfxVolume
        busMixers[.ui]?.outputVolume = master * sfxVolume
        busMixers[.music]?.outputVolume = master * musicVolume
    }

    private func observeInterruptions() {
        let centre = NotificationCenter.default
        centre.addObserver(forName: AVAudioSession.interruptionNotification,
                           object: AVAudioSession.sharedInstance(), queue: .main) { [weak self] note in
            // Read everything needed off the notification here; only Sendable
            // values may cross into the actor-isolated hop below.
            guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
            let shouldResume = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) } ?? false
            MainActor.assumeIsolated {
                switch type {
                case .began:
                    self?.suspend()
                case .ended:
                    // Only resume when the system says we may.
                    if shouldResume { self?.resume() }
                @unknown default:
                    break
                }
            }
        }
        centre.addObserver(forName: AVAudioSession.routeChangeNotification,
                           object: AVAudioSession.sharedInstance(), queue: .main) { [weak self] note in
            guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
            MainActor.assumeIsolated {
                // Headphone unplug must not blast the speaker.
                if reason == .oldDeviceUnavailable { self?.suspend() }
            }
        }
    }
}
