import SpriteKit
import Combine
import SurveillanceCore

final class GameScene: SKScene, ObservableObject {
    private static let initialRunSeed: UInt64 = 0x51555256
    @Published var suspicion: Double = 0
    @Published var suspicionTier: Int = 0
    @Published var isRunPaused = false
    @Published var controlsOnLeft = true
    @Published var pendingUpgradeChoices: [UpgradeChoice] = []
    /// Additional upgrade drafts waiting after the open multi-kill queue (sim truth).
    @Published var queuedUpgradeOffers: Int = 0
    @Published var bossHealth: Double?
    @Published var playerHealth: Double = BossCatalog.bundled.playerHealth
    @Published var playerDefeated = false
    @Published var dataShards = 0
    @Published var activeLoadout: [String] = [WeaponID.kineticCountermeasure.rawValue]
    @Published var runSeed: UInt64 = GameScene.initialRunSeed
    @Published var objectiveText = "Disrupt the surveillance grid"
    @Published var runCompleted = false
    @Published private(set) var completedRunReceipt: DeviceRunReceipt?
    @Published private(set) var districtName = DistrictID.campaignOpener.cityName
    @Published private(set) var districtTitle = DistrictID.campaignOpener.definition.title
    @Published private(set) var bossName = DistrictID.campaignOpener.bossName
    /// Presentation-only unlock profile (cosmetics / radio / weather / motif). Never combat.
    @Published private(set) var unlockPresentation = UnlockPresentationProfile.empty

    var elapsedTicksForTesting: UInt64 { simulation.runReceipt().elapsedTicks }
    var interactableActivationCountForTesting: Int {
        simulation.runReceipt().interactableActivations.count
    }
    var acceptsSceneTouches: Bool { pendingUpgradeChoices.isEmpty }
    /// Active campaign district for the live session (not merely the next-run picker).
    var activeDistrict: DistrictID { district }
    /// Active P11 challenge context, if this run is daily/weekly.
    var activeChallenge: ChallengeInstance? { challenge }

    private var district = DistrictID.campaignOpener
    private var challenge: ChallengeInstance?
    private var simulation = Simulation(seed: initialRunSeed, district: .campaignOpener)
    private var runOrdinal: UInt64 = 0
    private var accumulator: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var frameTimeDiagnostics = FrameTimeDiagnostics()
    private var movement = Vector2()
    private var requestedUpgradeChoiceIndex: Int?
    /// One-shot utility / interactable activation for the next sim step.
    private var requestedUtilityActivation = false
    /// Mastery-resolved presentation base; challenge mutators layer on top and must not leak.
    private var masteryPresentationBase = UnlockPresentationProfile.empty
    private let haptics = HapticFeedback()
    private let audio = AudioCuePlayer()
    private let entityProjector = EntityProjector()
    private let worldProjector = WorldProjector()
    private var presentation = PresentationPipeline()
    private let ghostTrail = GhostTrailPresenter()
    private let followCamera = SKCameraNode()
    private var reducedMotion = false
    private var reducedFlash = false
    private var lastFrameDelta: TimeInterval = 1.0 / 60.0
    /// Disabled under `-UITesting` so XCUITests can reach pause/settings chrome
    /// without AFK kinetic kills opening upgrade drafts at launch.
    private let uiTesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
    /// Device/simulator acceptance automation: force a completed Blind Spot extract for receipt UI.
    /// Does **not** claim ART readability — mechanical extract only.
    private let forceExtractTesting = ProcessInfo.processInfo.arguments.contains("-UITestingForceExtract")
    private var autoFireEnabled: Bool { !uiTesting && !forceExtractTesting }
    /// Under `-UITesting` / force-extract, skip LPR/boss contact damage so chrome/extract
    /// automation is not raced by run-summary after a quick defeat.
    private var suppressThreatContact: Bool { uiTesting || forceExtractTesting }

    /// Exposed for emulator diagnostics; never plays system sounds as product audio.
    var lastAudioRequestCountForTesting: Int { audio.lastResolvedRequests.count }
    /// Delivery assets that actually loaded from the bundle.
    private(set) var loadedAudioAssets: Set<String> = []

    /// Apply mastery unlocks as presentation profile (safe anytime; never mutates sim combat).
    func applyUnlockPresentation(from progress: MasteryProgress) {
        masteryPresentationBase = UnlockPresentationResolver.resolve(progress: progress)
        publishUnlockPresentation()
    }

    /// Enables real audio output. Assets that fail to load simply stay unavailable,
    /// so a partial bank plays what exists and stays silent for the rest.
    @discardableResult
    func activateAudioBank() -> Set<String> {
        let loaded = audio.activateBank()
        loadedAudioAssets = loaded
        return loaded
    }

    func applyAudioSettings(muted: Bool, sfxVolume: Double, musicVolume: Double) {
        audio.applyAudioSettings(muted: muted, sfxVolume: sfxVolume, musicVolume: musicVolume)
    }

    override func didMove(to view: SKView) {
        // Tinted paper (not pure black) — Hallmark pure-black tell avoidance for presentation surface.
        backgroundColor = VisualDesignTokens.skPaper
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        camera = followCamera
        // SpriteView can re-attach the same scene; never double-parent the camera node.
        if followCamera.parent !== self {
            followCamera.removeFromParent()
            addChild(followCamera)
        }
        // Movement is owned by SwiftUI's MovementStickOverlay for reliable device hit testing.
        isUserInteractionEnabled = false
        presentation.hardReset(entities: simulation.state.entities)
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        entityProjector.applyPresentationSettings(presentation.settings)
        render()
        applyUITestingForceExtractIfNeeded()
    }

    func setMovement(_ value: Vector2) {
        movement = value
    }

    func clearMovement() {
        movement = .init()
    }

    /// Request a one-shot environmental interactable activation on the next fixed step.
    func requestUtilityActivation() {
        requestedUtilityActivation = true
    }

    override func update(_ currentTime: TimeInterval) {
        guard !isRunPaused else {
            lastUpdate = currentTime
            return
        }

        if lastUpdate == 0 { lastUpdate = currentTime }
        let frameTime = min(1, max(0, currentTime - lastUpdate))
        frameTimeDiagnostics.record(frameTime)
        accumulator += min(0.1, frameTime)
        lastUpdate = currentTime

        while accumulator >= simulation.fixedStep {
            // Use simulation truth — published `pendingUpgradeChoices` is only synced in
            // render() after this loop, so hitch catch-up must not keep stepping after a
            // draft opens mid-frame.
            guard simulation.state.pendingUpgradeChoices.isEmpty || requestedUpgradeChoiceIndex != nil else {
                accumulator = 0
                break
            }

            let selectedUpgrade = requestedUpgradeChoiceIndex
            requestedUpgradeChoiceIndex = nil
            let activateUtility = requestedUtilityActivation
            requestedUtilityActivation = false
            let events = simulation.step(
                input: .init(
                    movement: movement,
                    activateUtility: activateUtility,
                    upgradeChoiceIndex: selectedUpgrade,
                    autoFireEnabled: autoFireEnabled,
                    suppressThreatContact: suppressThreatContact
                )
            )
            haptics.play(events)
            audio.play(
                events: events,
                atTick: simulation.runReceipt().elapsedTicks,
                suspicionTier: simulation.state.suspicionTier,
                district: simulation.state.district
            )
            // Looping ambience and music follow run state, not events.
            audio.applyScene(for: simulation.state)
            presentation.commitSimulationStep(entities: simulation.state.entities)
            accumulator -= simulation.fixedStep
            if !simulation.state.pendingUpgradeChoices.isEmpty && requestedUpgradeChoiceIndex == nil {
                accumulator = 0
                break
            }
        }

        lastFrameDelta = frameTime
        render()
        if simulation.state.runCompleted, completedRunReceipt == nil {
            completedRunReceipt = DeviceRunReceipt(
                core: simulation.runReceipt(),
                frameTimes: frameTimeDiagnostics.samples,
                frameTimeSummary: frameTimeDiagnostics.summary()
            )
        }
    }

    func toggleControlSide() {
        controlsOnLeft.toggle()
        clearMovement()
    }

    func applyAccessibilitySettings(
        controlsOnLeft: Bool,
        stickScale: CGFloat,
        stickOpacity: CGFloat,
        reducedMotion: Bool,
        reducedFlash: Bool,
        hapticsEnabled: Bool
    ) {
        self.controlsOnLeft = controlsOnLeft
        _ = stickScale
        _ = stickOpacity
        self.reducedMotion = reducedMotion
        self.reducedFlash = reducedFlash
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        // One presentation settings path — projector reuses pipeline tier/flash.
        entityProjector.applyPresentationSettings(presentation.settings)
        haptics.isEnabled = hapticsEnabled
        clearMovement()
    }

    func setRunPaused(_ paused: Bool) {
        guard paused != isRunPaused else { return }
        isRunPaused = paused
        clearMovement()
        if paused {
            // Drop one-shot utility taps that arrived before pause; they must not fire on resume.
            requestedUtilityActivation = false
        }
        accumulator = 0
        lastUpdate = 0
        isPaused = paused
        if paused { audio.suspendPlayback() } else { audio.resumePlayback() }
    }

    /// Selects the district the next run takes place in. The active run is left
    /// untouched; districts are fixed for the duration of a run.
    func selectDistrict(_ district: DistrictID) {
        self.district = district
    }

    /// Cold-launch alignment: if AppStorage already selected an unlocked city,
    /// rebuild the live session for that district without advancing run ordinal.
    /// No-op when already on that district, or when a run has progressed/finished
    /// (avoids wiping an active session or post-run summary on a late onAppear).
    func bootstrapCampaignDistrictIfNeeded(_ district: DistrictID) {
        guard self.district != district || simulation.state.district != district else { return }
        guard !runCompleted, completedRunReceipt == nil else { return }
        // Late/repeated onAppear must not wipe a run that has already ticked.
        guard simulation.runReceipt().elapsedTicks == 0 else { return }
        self.district = district
        resetSession(seed: Self.initialRunSeed &+ runOrdinal)
    }

    func startNextRun() {
        challenge = nil
        ghostTrail.clear()
        runOrdinal &+= 1
        resetSession(seed: Self.initialRunSeed &+ runOrdinal)
        refreshChallengePresentation()
    }

    /// Start a deterministic daily/weekly challenge run (P11).
    func startChallengeRun(_ instance: ChallengeInstance) {
        challenge = instance
        district = instance.districtId
        runOrdinal &+= 1
        resetSession(seed: instance.seed)
        refreshChallengePresentation()
    }

    private func refreshChallengePresentation() {
        publishUnlockPresentation()
    }

    /// Rebuild published presentation from mastery base + optional challenge overlays.
    private func publishUnlockPresentation() {
        var profile = masteryPresentationBase
        if let radio = challenge?.radioLanguageOverride {
            profile.radioLanguage = radio
        }
        if let weather = challenge?.weatherLightingOverride {
            profile.weatherLightingModifier = weather
        }
        if let motif = challenge?.audioMotifOverride {
            profile.audioMotifId = motif
        }
        unlockPresentation = profile
        ghostTrail.setEnabled(profile.showsLotGhostTrail, in: self)
        if let motif = profile.audioMotifId {
            audio.setAvailableAssets(audio.availableAssets.union([motif]))
        }
    }

    private func resetSession(seed: UInt64) {
        if let challenge {
            simulation = Simulation(seed: seed, district: challenge.districtId, challenge: challenge)
            district = challenge.districtId
        } else {
            simulation = Simulation(seed: seed, district: district)
        }
        districtName = district.cityName
        districtTitle = district.definition.title
        bossName = district.bossName
        if let challenge {
            objectiveText = "\(challenge.kind.uppercased()): \(challenge.contractDisplayName)"
        } else {
            objectiveText = "Disrupt the surveillance grid"
        }
        accumulator = 0
        lastUpdate = 0
        frameTimeDiagnostics = FrameTimeDiagnostics()
        completedRunReceipt = nil
        runCompleted = false
        playerDefeated = false
        playerHealth = BossCatalog.bundled.playerHealth
        dataShards = 0
        activeLoadout = [WeaponID.kineticCountermeasure.rawValue]
        runSeed = seed
        pendingUpgradeChoices = []
        queuedUpgradeOffers = 0
        requestedUpgradeChoiceIndex = nil
        requestedUtilityActivation = false
        isRunPaused = false
        isPaused = false
        clearMovement()
        presentation.hardReset(entities: simulation.state.entities)
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        entityProjector.applyPresentationSettings(presentation.settings)
        snapFollowCameraToPlayer()
        render()
        applyUITestingForceExtractIfNeeded()
    }

    /// Mechanical Blind Spot completion for automated acceptance UI (not ART / ship approval).
    private func applyUITestingForceExtractIfNeeded() {
        guard forceExtractTesting, !runCompleted else { return }
        var state = simulation.state
        if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
            state.entities[playerIndex].health = max(state.entities[playerIndex].health, 100)
        }
        if state.entities.contains(where: { $0.kind == .boss }) {
            for index in state.entities.indices where state.entities[index].kind == .boss {
                state.entities[index].health = 0
            }
        } else {
            state.entities.append(
                Entity(id: 99, kind: .boss, position: .init(x: 120, y: 0), health: 0, radius: 42)
            )
        }
        var opened = Simulation(state: state, rngSeed: state.seed)
        _ = opened.step(input: .init(autoFireEnabled: false, suppressThreatContact: true))
        guard let playerIndex = opened.state.entities.firstIndex(where: { $0.kind == .player }),
              let extraction = opened.state.entities.first(where: { $0.kind == .extraction })
        else { return }
        var completionState = opened.state
        completionState.entities[playerIndex].position = extraction.position
        var completed = Simulation(state: completionState, rngSeed: completionState.seed)
        _ = completed.step(input: .init(autoFireEnabled: false, suppressThreatContact: true))
        installSimulationForTesting(completed)
        runCompleted = completed.state.runCompleted
        playerDefeated = completed.state.playerDefeated
        playerHealth = completed.state.entities.first(where: { $0.kind == .player })?.health
            ?? playerHealth
        dataShards = completed.state.dataShards
    }

    /// Hard-snap camera to the player so district/session changes do not ease from a stale pose.
    private func snapFollowCameraToPlayer() {
        guard let player = simulation.state.entities.first(where: { $0.kind == .player }) else { return }
        followCamera.position = CGPoint(x: CGFloat(player.position.x), y: CGFloat(player.position.y))
    }

    func selectUpgrade(at index: Int) {
        guard pendingUpgradeChoices.indices.contains(index), requestedUpgradeChoiceIndex == nil else { return }
        requestedUpgradeChoiceIndex = index
        // The simulation applies this on its next fixed tick. Hide the SwiftUI
        // draft immediately so an accepted choice cannot leave a stale modal
        // above a run that is already progressing visually.
        pendingUpgradeChoices = []
        clearMovement()
    }

    /// Host-driven extraction smoke: installs a prepared simulation and advances
    /// one fixed step through the normal update path so receipts and projection
    /// stay consistent with live play.
    func installSimulationForTesting(_ prepared: Simulation) {
        simulation = prepared
        district = prepared.state.district
        districtName = prepared.state.district.cityName
        districtTitle = prepared.state.district.definition.title
        bossName = prepared.state.district.bossName
        runSeed = prepared.state.seed
        completedRunReceipt = nil
        clearMovement()
        presentation.hardReset(entities: simulation.state.entities)
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        entityProjector.applyPresentationSettings(presentation.settings)
        snapFollowCameraToPlayer()
        render()
        if simulation.state.runCompleted, completedRunReceipt == nil {
            completedRunReceipt = DeviceRunReceipt(
                core: simulation.runReceipt(),
                frameTimes: frameTimeDiagnostics.samples,
                frameTimeSummary: frameTimeDiagnostics.summary()
            )
        }
    }

    private func render() {
        worldProjector.synchronize(
            layout: simulation.state.world,
            district: simulation.state.district,
            landmark: simulation.state.landmarkEncounter,
            in: self
        )

        // Prefer current pose (alpha→1 as accumulator empties after a step).
        let step = max(simulation.fixedStep, 0.000_1)
        let rawAlpha = CGFloat(1 - min(1, accumulator / step))
        let display = presentation.sample(
            entities: simulation.state.entities,
            tick: simulation.runReceipt().elapsedTicks,
            extractionOpen: simulation.state.extractionOpen,
            rawAlpha: rawAlpha,
            frameDelta: CGFloat(lastFrameDelta)
        )
        entityProjector.synchronize(
            entities: simulation.state.entities,
            display: display,
            tick: simulation.runReceipt().elapsedTicks,
            animationDelta: lastFrameDelta,
            in: self
        )

        if let player = simulation.state.entities.first(where: { $0.kind == .player }) {
            let sample = display[player.id]
            let target = sample?.position
                ?? CGPoint(x: CGFloat(player.position.x), y: CGFloat(player.position.y))
            let smooth = presentation.settings.tier.allowCameraSmoothing && !reducedMotion
            followCamera.position = smooth ? CGPoint(
                x: followCamera.position.x + (target.x - followCamera.position.x) * 0.16,
                y: followCamera.position.y + (target.y - followCamera.position.y) * 0.16
            ) : target
            ghostTrail.update(playerPosition: target, reducedMotion: reducedMotion)
        }

        suspicion = simulation.state.suspicion
        suspicionTier = simulation.state.suspicionTier.rawValue
        pendingUpgradeChoices = requestedUpgradeChoiceIndex == nil
            ? simulation.state.pendingUpgradeChoices
            : []
        queuedUpgradeOffers = simulation.state.queuedUpgradeOffers
        bossHealth = simulation.state.entities.first(where: { $0.kind == .boss })?.health
        playerHealth = simulation.state.entities.first(where: { $0.kind == .player })?.health ?? 0
        playerDefeated = simulation.state.playerDefeated
        dataShards = simulation.state.dataShards
        runSeed = simulation.state.seed
        activeLoadout = simulation.state.activeWeapons.map { weapon in
            "\(shortWeaponName(weapon.id)) L\(weapon.level)"
        }
        runCompleted = simulation.state.runCompleted
        objectiveText = resolveObjectiveText(
            defeated: playerDefeated,
            completed: runCompleted,
            extractionOpen: simulation.state.extractionOpen,
            bossActive: bossHealth != nil
        )
    }

    private func resolveObjectiveText(
        defeated: Bool,
        completed: Bool,
        extractionOpen: Bool,
        bossActive: Bool
    ) -> String {
        if defeated { return "Reacquired by the grid" }
        if completed { return "Extraction complete" }
        if extractionOpen { return "Reach the Blind Spot" }
        if bossActive {
            if let challenge {
                return "Defeat \(bossName) · \(challenge.contractDisplayName)"
            }
            return "Defeat the Shift Manager"
        }
        if let challenge {
            return "\(challenge.kind.uppercased()): \(challenge.contractDisplayName)"
        }
        return "Escalate and disrupt the grid"
    }

    private func shortWeaponName(_ id: WeaponID) -> String {
        switch id {
        case .kineticCountermeasure: "Kinetic"
        case .redactionOrdinance: "Redaction"
        case .identityTransponder: "Spoofer"
        case .foiaSwarm: "FOIA"
        case .mirrorArray: "Mirror"
        case .signalFlood: "Flood"
        }
    }
}
