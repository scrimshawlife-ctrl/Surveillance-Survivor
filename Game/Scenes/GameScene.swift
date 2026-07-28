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
    private var didInstallUITestScenario = false
    private var lastFrameDelta: TimeInterval = 1.0 / 60.0
    /// Disabled under `-UITesting` so XCUITests can reach pause/settings chrome
    /// without AFK kinetic kills opening upgrade drafts at launch.
    private let autoFireEnabled = !ProcessInfo.processInfo.arguments.contains("-UITesting")

    /// Exposed for emulator diagnostics; never plays system sounds as product audio.
    var lastAudioRequestCountForTesting: Int { audio.lastResolvedRequests.count }

    /// Apply mastery unlocks as presentation profile (safe anytime; never mutates sim combat).
    func applyUnlockPresentation(from progress: MasteryProgress) {
        masteryPresentationBase = UnlockPresentationResolver.resolve(progress: progress)
        publishUnlockPresentation()
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

    /// Installs deterministic black-box UI states requested by XCUITest launch arguments.
    /// Production launches never enter this path because `-UITesting` is required.
    func installUITestScenarioIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) {
        guard !didInstallUITestScenario, arguments.contains("-UITesting") else { return }
        guard let flagIndex = arguments.firstIndex(of: "-UITestScenario"),
              arguments.indices.contains(flagIndex + 1) else { return }
        didInstallUITestScenario = true
        let requestedDistrict: DistrictID = {
            guard let index = arguments.firstIndex(of: "-UITestDistrict"),
                  arguments.indices.contains(index + 1) else { return .wichita }
            return DistrictID(rawValue: arguments[index + 1]) ?? .wichita
        }()

        if arguments.contains("-UITestReducedPresentation") {
            applyAccessibilitySettings(
                controlsOnLeft: controlsOnLeft,
                stickScale: 1,
                stickOpacity: 0.7,
                reducedMotion: true,
                reducedFlash: true,
                hapticsEnabled: false
            )
        }

        switch arguments[flagIndex + 1] {
        case "upgrade":
            var state = RunState(seed: 9_001, district: .wichita)
            state.pendingUpgradeChoices = [.rapidCountermeasure, .reinforcedSignal, .lowProfileRouting]
            installSimulationForTesting(Simulation(state: state, rngSeed: state.seed))
        case "extraction":
            installSimulationForTesting(Self.completedUITestSimulation(defeated: false))
        case "defeat":
            installSimulationForTesting(Self.completedUITestSimulation(defeated: true))
        case "density":
            installSimulationForTesting(Self.denseUITestSimulation(district: requestedDistrict))
        case "combat", "reduced":
            installSimulationForTesting(Self.ordinaryCombatUITestSimulation(district: requestedDistrict))
        default:
            break
        }
    }

    private static func completedUITestSimulation(defeated: Bool) -> Simulation {
        var state = RunState(seed: defeated ? 9_003 : 9_002, district: .wichita)
        state.entities = [
            Entity(
                id: 1,
                kind: .player,
                position: .init(),
                health: defeated ? 0 : BossCatalog.bundled.playerHealth,
                radius: 18
            )
        ]
        state.playerDefeated = defeated
        state.extractionOpen = !defeated
        state.runCompleted = true
        return Simulation(state: state, rngSeed: state.seed)
    }

    private static func denseUITestSimulation(district: DistrictID) -> Simulation {
        let seed = UInt64(9_000 + district.definition.level)
        var state = RunState(seed: seed, district: district)
        var entities = [
            Entity(id: 1, kind: .player, position: .init(), health: 100, radius: 18),
            Entity(id: 2, kind: .boss, position: .init(x: 190, y: 20), health: 320, radius: 42),
            Entity(id: 3, kind: .mirrorArray, position: .init(x: -90, y: -30), health: 1, radius: 56),
            Entity(id: 4, kind: .signalFlood, position: .init(x: 70, y: -70), health: 1, radius: 84)
        ]
        for index in 0..<6 {
            entities.append(Entity(
                id: UInt64(10 + index),
                kind: .securityGuard,
                guardArchetype: GuardArchetype.allCases[index],
                position: .init(x: Double(-180 + index * 70), y: index.isMultiple(of: 2) ? 90 : -110),
                health: 40,
                radius: 16,
                processing: index == 1 ? .init(untilTick: 600, slowMultiplier: 0.5, damagePerTick: 0.1) : nil,
                disruptedUntilTick: index == 3 ? 600 : nil
            ))
            entities.append(Entity(
                id: UInt64(30 + index),
                kind: .cameraPole,
                sensorArchetype: SensorArchetype.allCases[index],
                position: .init(x: Double(-220 + index * 85), y: index.isMultiple(of: 2) ? -180 : 175),
                heading: Double(index) * 0.8,
                health: 45,
                radius: 18
            ))
        }
        for index in 0..<18 {
            let weapons = WeaponID.allCases
            entities.append(Entity(
                id: UInt64(100 + index),
                kind: .projectile,
                position: .init(x: Double(-135 + (index % 6) * 54), y: Double(-75 + (index / 6) * 70)),
                velocity: .init(x: 1, y: 0),
                health: 1,
                radius: 8,
                sourceWeapon: weapons[index % weapons.count]
            ))
        }
        state.entities = entities
        state.suspicion = 88
        state.suspicionTier = .totalVisibility
        return Simulation(state: state, rngSeed: state.seed)
    }

    private static func ordinaryCombatUITestSimulation(district: DistrictID) -> Simulation {
        let seed = UInt64(8_000 + district.definition.level)
        var state = RunState(seed: seed, district: district)
        state.entities.append(contentsOf: [
            Entity(id: 80, kind: .securityGuard, guardArchetype: GuardArchetype.allCases[0], position: .init(x: -105, y: 70), health: 40, radius: 16),
            Entity(id: 81, kind: .securityGuard, guardArchetype: GuardArchetype.allCases[1], position: .init(x: 125, y: -75), health: 40, radius: 16),
            Entity(id: 82, kind: .cameraPole, sensorArchetype: SensorArchetype.allCases[0], position: .init(x: -170, y: -115), heading: 0.7, health: 30, radius: 18),
            Entity(id: 83, kind: .cameraPole, sensorArchetype: SensorArchetype.allCases[1], position: .init(x: 175, y: 120), heading: 3.8, health: 30, radius: 18)
        ])
        state.suspicion = 38
        state.suspicionTier = .patternDetected
        return Simulation(state: state, rngSeed: state.seed)
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
                    autoFireEnabled: autoFireEnabled
                )
            )
            haptics.play(events)
            audio.play(
                events: events,
                atTick: simulation.runReceipt().elapsedTicks,
                suspicionTier: simulation.state.suspicionTier
            )
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
