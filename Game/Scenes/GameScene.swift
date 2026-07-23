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

    var elapsedTicksForTesting: UInt64 { simulation.runReceipt().elapsedTicks }
    var acceptsSceneTouches: Bool { pendingUpgradeChoices.isEmpty }

    private var simulation = Simulation(seed: initialRunSeed)
    private var runOrdinal: UInt64 = 0
    private var accumulator: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var frameTimeDiagnostics = FrameTimeDiagnostics()
    private var movement = Vector2()
    private var requestedUpgradeChoiceIndex: Int?
    private let haptics = HapticFeedback()
    private let entityProjector = EntityProjector()
    private let worldProjector = WorldProjector()
    private let followCamera = SKCameraNode()
    private var reducedMotion = false
    private var reducedFlash = false
    /// Disabled under `-UITesting` so XCUITests can reach pause/settings chrome
    /// without AFK kinetic kills opening upgrade drafts at launch.
    private let autoFireEnabled = !ProcessInfo.processInfo.arguments.contains("-UITesting")

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        camera = followCamera
        addChild(followCamera)
        // Movement is owned by SwiftUI's MovementStickOverlay for reliable device hit testing.
        isUserInteractionEnabled = false
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
            accumulator -= simulation.fixedStep
        }

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

    func startNextRun() {
        runOrdinal &+= 1
        simulation = Simulation(seed: Self.initialRunSeed &+ runOrdinal)
        accumulator = 0
        lastUpdate = 0
        frameTimeDiagnostics = FrameTimeDiagnostics()
        completedRunReceipt = nil
        runCompleted = false
        playerDefeated = false
        playerHealth = BossCatalog.bundled.playerHealth
        dataShards = 0
        activeLoadout = [WeaponID.kineticCountermeasure.rawValue]
        runSeed = Self.initialRunSeed &+ runOrdinal
        pendingUpgradeChoices = []
        requestedUpgradeChoiceIndex = nil
        isRunPaused = false
        isPaused = false
        clearMovement()
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

    private func render() {
        worldProjector.synchronize(layout: simulation.state.world, in: self)
        entityProjector.synchronize(entities: simulation.state.entities, in: self)

        if let player = simulation.state.entities.first(where: { $0.kind == .player }) {
            let target = CGPoint(x: CGFloat(player.position.x), y: CGFloat(player.position.y))
            followCamera.position = reducedMotion ? target : CGPoint(
                x: followCamera.position.x + (target.x - followCamera.position.x) * 0.16,
                y: followCamera.position.y + (target.y - followCamera.position.y) * 0.16
            )
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
        if playerDefeated {
            objectiveText = "Reacquired by the grid"
        } else if runCompleted {
            objectiveText = "Extraction complete"
        } else if simulation.state.extractionOpen {
            objectiveText = "Reach the Blind Spot"
        } else if bossHealth != nil {
            objectiveText = "Defeat the Shift Manager"
        } else {
            objectiveText = "Escalate and disrupt the grid"
        }
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
