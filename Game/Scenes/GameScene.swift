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
    @Published var objectiveText = "Disrupt the surveillance grid"
    @Published var runCompleted = false
    @Published private(set) var completedRunReceipt: DeviceRunReceipt?

    var elapsedTicksForTesting: UInt64 { simulation.runReceipt().elapsedTicks }

    private var simulation = Simulation(seed: initialRunSeed)
    private var runOrdinal: UInt64 = 0
    private var accumulator: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var frameTimeDiagnostics = FrameTimeDiagnostics()
    private var movement = Vector2()
    private var requestedUpgradeChoiceIndex: Int?
    private var movementTouch: UITouch?
    private var stick = VirtualStick()
    private let haptics = HapticFeedback()
    private let entityProjector = EntityProjector()
    private let worldProjector = WorldProjector()
    private let followCamera = SKCameraNode()
    private let stickBase = SKShapeNode(circleOfRadius: 64)
    private let stickKnob = SKShapeNode(circleOfRadius: 28)
    private var reducedMotion = false
    private var reducedFlash = false

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill
        camera = followCamera
        addChild(followCamera)

        stickBase.fillColor = .white.withAlphaComponent(0.08)
        stickBase.strokeColor = .white.withAlphaComponent(0.28)
        stickBase.isHidden = true
        stickBase.zPosition = 100
        addChild(stickBase)

        stickKnob.fillColor = .white.withAlphaComponent(0.28)
        stickKnob.strokeColor = .cyan.withAlphaComponent(0.65)
        stickKnob.isHidden = true
        stickKnob.zPosition = 101
        addChild(stickKnob)

        render()
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
            let events = simulation.step(input: .init(movement: movement, upgradeChoiceIndex: selectedUpgrade))
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
        cancelMovement()
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
        let clampedScale = min(1.4, max(0.75, stickScale))
        let clampedOpacity = min(1, max(0.2, stickOpacity))
        stick = VirtualStick(radius: 64 * clampedScale)
        stickBase.xScale = clampedScale
        stickBase.yScale = clampedScale
        stickKnob.xScale = clampedScale
        stickKnob.yScale = clampedScale
        stickBase.fillColor = .white.withAlphaComponent(clampedOpacity * 0.28)
        stickBase.strokeColor = .white.withAlphaComponent(clampedOpacity * 0.7)
        stickKnob.fillColor = .white.withAlphaComponent(clampedOpacity * 0.7)
        stickKnob.strokeColor = .cyan.withAlphaComponent(clampedOpacity)
        self.reducedMotion = reducedMotion
        self.reducedFlash = reducedFlash
        entityProjector.setReducedFlash(reducedFlash)
        haptics.isEnabled = hapticsEnabled
        cancelMovement()
    }

    func setRunPaused(_ paused: Bool) {
        guard paused != isRunPaused else { return }
        isRunPaused = paused
        cancelMovement()
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
        isRunPaused = false
        isPaused = false
        cancelMovement()
        render()
    }

    func selectUpgrade(at index: Int) {
        guard pendingUpgradeChoices.indices.contains(index), requestedUpgradeChoiceIndex == nil else { return }
        requestedUpgradeChoiceIndex = index
        // The simulation applies this on its next fixed tick. Hide the SwiftUI
        // draft immediately so an accepted choice cannot leave a stale modal
        // above a run that is already progressing visually.
        pendingUpgradeChoices = []
        cancelMovement()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isRunPaused, movementTouch == nil, let view else { return }
        guard let touch = touches.first else { return }
        let viewportPoint = touch.location(in: view)
        let isLeftHalf = viewportPoint.x <= view.bounds.midX
        guard isLeftHalf == controlsOnLeft else { return }

        let worldPoint = touch.location(in: self)
        movementTouch = touch
        stick.begin(at: worldPoint)
        stickBase.position = worldPoint
        stickKnob.position = worldPoint
        stickBase.isHidden = false
        stickKnob.isHidden = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let movementTouch, touches.contains(movementTouch) else { return }
        let point = movementTouch.location(in: self)
        movement = stick.move(to: point)
        if let knob = stick.knob {
            stickKnob.position = knob
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishMovementTouch(in: touches)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        finishMovementTouch(in: touches)
    }

    private func finishMovementTouch(in touches: Set<UITouch>) {
        guard let movementTouch, touches.contains(movementTouch) else { return }
        cancelMovement()
    }

    private func cancelMovement() {
        movementTouch = nil
        movement = .init()
        stick.end()
        stickBase.isHidden = true
        stickKnob.isHidden = true
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
        runCompleted = simulation.state.runCompleted
        if runCompleted {
            objectiveText = "Extraction complete"
        } else if simulation.state.extractionOpen {
            objectiveText = "Reach the Blind Spot"
        } else if bossHealth != nil {
            objectiveText = "Defeat the Shift Manager"
        } else {
            objectiveText = "Escalate and disrupt the grid"
        }
    }
}
