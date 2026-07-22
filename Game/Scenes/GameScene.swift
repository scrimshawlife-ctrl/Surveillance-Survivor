import SpriteKit
import Combine

final class GameScene: SKScene, ObservableObject {
    @Published var suspicion: Double = 0
    @Published var suspicionTier: Int = 0
    @Published var isRunPaused = false

    private var simulation = Simulation(seed: 0x51555256)
    private var accumulator: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var movement = Vector2()
    private var movementTouch: UITouch?
    private var stick = VirtualStick()
    private let projector = EntityProjector()
    private let stickBase = SKShapeNode(circleOfRadius: 64)
    private let stickKnob = SKShapeNode(circleOfRadius: 28)

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        scaleMode = .resizeFill

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
        accumulator += min(0.1, currentTime - lastUpdate)
        lastUpdate = currentTime

        while accumulator >= simulation.fixedStep {
            _ = simulation.step(input: .init(movement: movement))
            accumulator -= simulation.fixedStep
        }

        render()
    }

    func setRunPaused(_ paused: Bool) {
        guard paused != isRunPaused else { return }
        isRunPaused = paused
        movement = .init()
        movementTouch = nil
        stick.end()
        hideStick()
        accumulator = 0
        lastUpdate = 0
        isPaused = paused
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isRunPaused, movementTouch == nil else { return }
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        guard point.x <= frame.midX else { return }

        movementTouch = touch
        stick.begin(at: point)
        stickBase.position = point
        stickKnob.position = point
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
        self.movementTouch = nil
        movement = .init()
        stick.end()
        hideStick()
    }

    private func hideStick() {
        stickBase.isHidden = true
        stickKnob.isHidden = true
    }

    private func render() {
        projector.synchronize(entities: simulation.state.entities, in: self)
        suspicion = simulation.state.suspicion
        suspicionTier = simulation.state.suspicionTier.rawValue
    }
}
