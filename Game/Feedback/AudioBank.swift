import AVFoundation
import Foundation
import SurveillanceCore

/// Discovers the approved delivery bank and plays resolved cues through per-bus mixers.
///
/// The simulation stays authoritative: this reads `AudioCueResolver.Request` values
/// and never influences `RunState`. Only short shared one-shots are decoded at start.
/// District cues are decoded when their scene becomes active, while long ambience
/// and music use file-backed players instead of retained PCM buffers.
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
    private var assetURLs: [String: URL] = [:]
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var activeDistrict: DistrictID?
    private var graphBuilt = false
    private var started = false

    /// Looping slots use two file-backed players so a scene change crossfades rather
    /// than cutting. `AVPlayerLooper` streams local delivery files and avoids retaining
    /// the decoded ambience/music bank in memory.
    private enum LoopSlot: CaseIterable { case foundation, ambience, music, overlay }
    private var loopPlayers: [LoopSlot: [AVQueuePlayer]] = [:]
    private var loopLoopers: [LoopSlot: [AVPlayerLooper?]] = [:]
    private var loopGains: [LoopSlot: [Float]] = [:]
    private var loopActive: [LoopSlot: Int] = [:]
    private var loopAsset: [LoopSlot: String?] = [:]
    private var loopTarget: [LoopSlot: Float] = [:]
    private var loopTransition: [LoopSlot: Int] = [:]

    /// Assets that resolved to readable, nonempty delivery files. This remains the
    /// availability contract used by `AudioCuePlayer`; it does not imply PCM residency.
    private(set) var loadedAssetNames: Set<String> = []
    /// Whether playback is currently held. Observable so the lifecycle contract can
    /// be asserted against real engine state rather than against the caller's intent.
    private(set) var isSuspended = false

    /// Test/diagnostic visibility into the bounded resident one-shot cache.
    var bufferedAssetNames: Set<String> { Set(buffers.keys) }

    /// The currently selected file-backed loops, excluding missing/silent fallbacks.
    var streamingAssetNames: Set<String> {
        Set(LoopSlot.allCases.compactMap { slot in
            let activeIndex = loopActive[slot] ?? 0
            guard loopLoopers[slot]?[activeIndex] != nil else { return nil }
            return loopAsset[slot] ?? nil
        })
    }

    var isMuted = false {
        didSet { applyLevels() }
    }
    var sfxVolume: Float = 1.0 {
        didSet { applyLevels() }
    }
    var musicVolume: Float = 1.0 {
        didSet { applyLevels() }
    }
    var ambienceVolume: Float = 0.40 {
        didSet { applyLevels() }
    }

    // MARK: - Lifecycle

    /// Discovers every addressable `.caf`, decodes only shared one-shots, and starts
    /// the engine. Returns the readable asset names so callers preserve the existing
    /// silent-fallback availability contract without forcing full-bank residency.
    @discardableResult
    func start() -> Set<String> {
        guard !started else { return loadedAssetNames }
        configureSession()
        if !graphBuilt {
            buildGraph()
            graphBuilt = true
        }
        if assetURLs.isEmpty {
            discoverBank()
            preloadSharedCues()
        }
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
        // Count both mechanisms: cues fire on events, scenes are state-projected.
        let requested = requestedAssetNames()
        let missing = requested.subtracting(loadedAssetNames).sorted()
        NSLog(
            "AudioBank: started — \(loadedAssetNames.count)/\(requested.count) assets available, "
                + "\(buffers.count) shared cues buffered"
                + (missing.isEmpty ? "" : ", missing: \(missing.joined(separator: ", "))")
        )
        return loadedAssetNames
    }

    func stop() {
        guard started else { return }
        engine.stop()
        stopAllLoops()
        started = false
    }

    /// Interruption and background handling pauses both the one-shot engine and the
    /// streamed loops without tearing down the bounded shared cue cache.
    func suspend() {
        guard started else { return }
        isSuspended = true
        engine.pause()
        for pair in loopPlayers.values {
            pair.forEach { $0.pause() }
        }
    }

    func resume() {
        guard started else { return }
        isSuspended = false
        do {
            try engine.start()
            for slot in LoopSlot.allCases {
                let activeIndex = loopActive[slot] ?? 0
                guard loopLoopers[slot]?[activeIndex] != nil else { continue }
                loopPlayers[slot]?[activeIndex].play()
            }
        } catch {
            NSLog("AudioBank: resume failed — \(error.localizedDescription)")
        }
    }

    // MARK: - Playback

    /// Returns only requests whose one-shot buffer was genuinely available. Muting
    /// affects output volume, not resolution diagnostics, matching prior behavior.
    @discardableResult
    func play(_ requests: [AudioCueResolver.Request]) -> [AudioCueResolver.Request] {
        guard started else { return [] }
        var played: [AudioCueResolver.Request] = []
        for request in requests {
            guard loadedAssetNames.contains(request.assetName) else { continue }
            guard let buffer = buffers[request.assetName] ?? loadBuffer(named: request.assetName) else {
                continue
            }
            played.append(request)
            guard !isMuted, let voice = checkoutVoice(on: request.bus) else { continue }
            voice.volume = Float(max(0, min(1.5, request.gain)))
            voice.stop()
            voice.scheduleBuffer(buffer, at: nil, options: .interrupts)
            voice.play()
        }
        return played
    }

    /// Applies a projected scene. Unchanged slots are left alone so a loop keeps
    /// playing across ticks instead of restarting every frame.
    func apply(_ scene: AudioScene) {
        guard started else { return }
        if let district = district(for: scene) {
            prepareDistrict(district)
        }
        set(.foundation, scene.foundation)
        set(.ambience, scene.ambience)
        set(.music, scene.music)
        set(.overlay, scene.overlay)
    }

    private func set(_ slot: LoopSlot, _ asset: String?) {
        guard (loopAsset[slot] ?? nil) != asset else { return }
        loopAsset[slot] = asset
        guard let pair = loopPlayers[slot] else { return }

        let generation = (loopTransition[slot] ?? 0) + 1
        loopTransition[slot] = generation
        let activeIndex = loopActive[slot] ?? 0
        let incomingIndex = 1 - activeIndex
        loopActive[slot] = incomingIndex

        fade(slot, index: activeIndex, to: 0, over: Self.crossfadeSeconds,
             stopAfter: true, generation: generation)
        releaseLoop(slot, index: incomingIndex)
        guard let asset, let url = assetURLs[asset] else { return }

        let incoming = pair[incomingIndex]
        let item = AVPlayerItem(url: url)
        let looper = AVPlayerLooper(player: incoming, templateItem: item)
        setLooper(looper, slot: slot, index: incomingIndex)
        setLoopGain(0, slot: slot, index: incomingIndex)
        incoming.play()
        fade(slot, index: incomingIndex, to: loopTarget[slot] ?? 1.0,
             over: Self.crossfadeSeconds, stopAfter: false, generation: generation)
    }

    private static let crossfadeSeconds = 1.5

    /// Ramps a streamed player's relative gain in small steps. Absolute user levels
    /// are applied separately, so changing settings during a crossfade stays correct.
    private func fade(_ slot: LoopSlot, index: Int, to target: Float,
                      over seconds: Double, stopAfter: Bool, generation: Int) {
        let steps = 30
        let start = loopGains[slot]?[index] ?? 0
        for step in 1...steps {
            let delay = seconds * Double(step) / Double(steps)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                MainActor.assumeIsolated {
                    guard let self, self.loopTransition[slot] == generation else { return }
                    let value = start + (target - start) * Float(step) / Float(steps)
                    self.setLoopGain(value, slot: slot, index: index)
                    if stopAfter, step == steps, target == 0 {
                        self.releaseLoop(slot, index: index)
                    }
                }
            }
        }
    }

    private func setLoopGain(_ value: Float, slot: LoopSlot, index: Int) {
        var gains = loopGains[slot] ?? [0, 0]
        gains[index] = value
        loopGains[slot] = gains
        applyLoopLevel(slot, index: index)
    }

    private func setLooper(_ looper: AVPlayerLooper?, slot: LoopSlot, index: Int) {
        var loopers = loopLoopers[slot] ?? [nil, nil]
        loopers[index] = looper
        loopLoopers[slot] = loopers
    }

    private func releaseLoop(_ slot: LoopSlot, index: Int) {
        guard let player = loopPlayers[slot]?[index] else { return }
        player.pause()
        player.removeAllItems()
        setLooper(nil, slot: slot, index: index)
        setLoopGain(0, slot: slot, index: index)
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

        for slot in LoopSlot.allCases {
            let pair = [AVQueuePlayer(), AVQueuePlayer()]
            pair.forEach {
                $0.actionAtItemEnd = .advance
                $0.volume = 0
            }
            loopPlayers[slot] = pair
            loopLoopers[slot] = [nil, nil]
            loopGains[slot] = [0, 0]
            loopActive[slot] = 0
            loopAsset[slot] = nil
            loopTransition[slot] = 0
            // Relative balance within the ambience group; absolute level is the
            // player's Ambience slider. The shared foundation sits behind the city bed.
            switch slot {
            case .foundation: loopTarget[slot] = 0.65
            default: loopTarget[slot] = 1.0
            }
        }
        engine.prepare()
    }

    /// Every asset either mechanism can address: event cues plus scene loops.
    private func requestedAssetNames() -> Set<String> {
        var wanted = Set(AudioEventCatalog.bundled.cues.map(\.assetName))
        guard let scenes = AudioEventCatalog.bundled.scenes else { return wanted }
        wanted.formUnion(scenes.districts.flatMap { definition -> [String] in
            var names = [definition.ambienceAsset, definition.runAsset]
            if let foundation = definition.foundationAsset { names.append(foundation) }
            if let boss = definition.bossAsset { names.append(boss) }
            names.append(contentsOf: definition.bossPhaseAssets ?? [])
            return names
        })
        if let overlay = scenes.overlayExtractionAsset { wanted.insert(overlay) }
        if let sweep = scenes.scanSweepAsset { wanted.insert(sweep) }
        return wanted
    }

    /// Resolves and header-checks every addressable file without retaining decoded
    /// audio. Delivery derivatives are flattened into the app bundle root.
    private func discoverBank() {
        for name in requestedAssetNames().sorted() {
            guard let url = Bundle.main.url(forResource: name, withExtension: "caf") else { continue }
            guard let file = try? AVAudioFile(forReading: url), file.length > 0 else { continue }
            assetURLs[name] = url
            loadedAssetNames.insert(name)
        }
    }

    /// Shared event cues are short and latency-sensitive, so they are the only assets
    /// decoded during activation. District cues are handled by `prepareDistrict`.
    private func preloadSharedCues() {
        let shared = AudioEventCatalog.bundled.cues
            .filter { $0.districtId == nil }
            .map(\.assetName)
        for name in Set(shared).sorted() {
            _ = loadBuffer(named: name)
        }
    }

    private func loadBuffer(named name: String) -> AVAudioPCMBuffer? {
        guard let url = assetURLs[name], let file = try? AVAudioFile(forReading: url) else {
            return nil
        }
        let format = file.processingFormat
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else { return nil }
        do {
            try file.read(into: buffer)
            guard buffer.frameLength > 0 else { return nil }
            buffers[name] = buffer
            return buffer
        } catch {
            NSLog("AudioBank: failed to read \(name) — \(error.localizedDescription)")
            loadedAssetNames.remove(name)
            assetURLs.removeValue(forKey: name)
            return nil
        }
    }

    /// Keeps at most one district's event cues resident. Scene loops remain streamed.
    private func prepareDistrict(_ district: DistrictID) {
        guard activeDistrict != district else { return }
        let districtCues = AudioEventCatalog.bundled.cues.filter { $0.districtId != nil }
        let wanted = Set(districtCues.filter { $0.districtId == district }.map(\.assetName))
        for name in Set(districtCues.map(\.assetName)) where !wanted.contains(name) {
            buffers.removeValue(forKey: name)
        }
        for name in wanted.sorted() {
            _ = buffers[name] ?? loadBuffer(named: name)
        }
        activeDistrict = district
    }

    private func district(for scene: AudioScene) -> DistrictID? {
        guard let scenes = AudioEventCatalog.bundled.scenes else { return nil }
        if let ambience = scene.ambience {
            return scenes.districts.first { $0.ambienceAsset == ambience }?.districtId
        }
        if let music = scene.music {
            return scenes.districts.first { definition in
                definition.runAsset == music
                    || definition.bossAsset == music
                    || (definition.bossPhaseAssets ?? []).contains(music)
            }?.districtId
        }
        return nil
    }

    private func stopAllLoops() {
        for slot in LoopSlot.allCases {
            loopTransition[slot] = (loopTransition[slot] ?? 0) + 1
            releaseLoop(slot, index: 0)
            releaseLoop(slot, index: 1)
            loopAsset[slot] = nil
            loopActive[slot] = 0
        }
    }

    private func applyLevels() {
        let master: Float = isMuted ? 0 : 1
        busMixers[.sfx]?.outputVolume = master * sfxVolume
        busMixers[.ui]?.outputVolume = master * sfxVolume
        busMixers[.music]?.outputVolume = master * musicVolume
        for slot in LoopSlot.allCases {
            applyLoopLevel(slot, index: 0)
            applyLoopLevel(slot, index: 1)
        }
    }

    private func applyLoopLevel(_ slot: LoopSlot, index: Int) {
        guard let player = loopPlayers[slot]?[index] else { return }
        let master: Float = isMuted ? 0 : 1
        let group: Float
        switch slot {
        case .foundation, .ambience: group = ambienceVolume
        case .music: group = musicVolume
        case .overlay: group = sfxVolume
        }
        player.volume = master * group * (loopGains[slot]?[index] ?? 0)
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
