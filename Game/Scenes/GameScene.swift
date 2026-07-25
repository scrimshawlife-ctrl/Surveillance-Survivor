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
    private let autoFireEnabled = !ProcessInfo.processInfo.arguments.contains("-UITesting")

    /// Exposed for emulator diagnostics; never plays system sounds as product audio.
    var lastAudioRequestCountForTesting: Int { audio.lastResolvedRequests.count }

    /// Apply mastery unlocks as presentation profile (safe anytime; never mutates sim combat).
    func applyUnlockPresentation(from progress: MasteryProgress) {
        var profile = UnlockPresentationResolver.resolve(progress: progress)
        // Challenge mutator labels layer on top of mastery unlocks (presentation only).
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
        // Preferred motif is recorded for when approved stems exist; no system sound fallback.
        if let motif = unlockPresentation.audioMotifId {
            audio.setAvailableAssets(audio.availableAssets.union([motif]))
        }
    }

    override func didMove(to view: SKView) {
        // Tinted paper (not pure black) — Hallmark pure-black tell avoidance for presentation surface.
        backgroundColor = VisualDesignTokens.skPaper
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        camera = followCamera
        addChild(followCamera)
        // Movement is owned by SwiftUI's MovementStickOverlay for reliable device hit testing.
        isUserInteractionEnabled = false
        presentation.hardReset(entities: simulation.state.entities)
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        render()
    }

    func setMovement(_ value: Vector2) {
        movement = value
    }

    func clearMovement() {
        movement = .init()
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
            guard pendingUpgradeChoices.isEmpty || requestedUpgradeChoiceIndex != nil else {
                accumulator = 0
                break
            }

            let selectedUpgrade = requestedUpgradeChoiceIndex
            requestedUpgradeChoiceIndex = nil
            let events = simulation.step(
                input: .init(
                    movement: movement,
                    upgradeChoiceIndex: selectedUpgrade,
                    autoFireEnabled: autoFireEnabled
                )
            )
            haptics.play(events)
            audio.play(events: events, atTick: simulation.runReceipt().elapsedTicks)
            presentation.commitSimulationStep(entities: simulation.state.entities)
            accumulator -= simulation.fixedStep
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
        entityProjector.setReducedFlash(reducedFlash)
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        haptics.isEnabled = hapticsEnabled
        clearMovement()
    }

    func setRunPaused(_ paused: Bool) {
        guard paused != isRunPaused else { return }
        isRunPaused = paused
        clearMovement()
        accumulator = 0
        lastUpdate = 0
        isPaused = paused
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
        // Re-resolve presentation with current challenge mutator labels.
        // Mastery unlocks are re-applied by RootView after receipts; for challenge
        // start we only layer challenge labels onto the current profile.
        var profile = unlockPresentation
        if let radio = challenge?.radioLanguageOverride {
            profile.radioLanguage = radio
        }
        if let weather = challenge?.weatherLightingOverride {
            profile.weatherLightingModifier = weather
        }
        if let motif = challenge?.audioMotifOverride {
            profile.audioMotifId = motif
            audio.setAvailableAssets(audio.availableAssets.union([motif]))
        }
        unlockPresentation = profile
        ghostTrail.setEnabled(profile.showsLotGhostTrail, in: self)
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
        requestedUpgradeChoiceIndex = nil
        isRunPaused = false
        isPaused = false
        clearMovement()
        presentation.hardReset(entities: simulation.state.entities)
        presentation.applyAccessibility(reducedMotion: reducedMotion, reducedFlash: reducedFlash)
        render()
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
