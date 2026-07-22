import SpriteKit
import Combine

final class GameScene: SKScene, ObservableObject {
    @Published var suspicion: Double = 0
    @Published var suspicionTier: Int = 0

    private var simulation = Simulation(seed: 0x51555256)
    private var accumulator: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var movement = Vector2()
    private let playerNode = SKShapeNode(circleOfRadius: 18)

    override func didMove(to view: SKView) {
        backgroundColor = .black
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        playerNode.fillColor = .white
        playerNode.strokeColor = .cyan
        addChild(playerNode)
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime }
        accumulator += min(0.1, currentTime - lastUpdate)
        lastUpdate = currentTime

        while accumulator >= simulation.fixedStep {
            _ = simulation.step(input: .init(movement: movement))
            accumulator -= simulation.fixedStep
        }

        render()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateMovement(touches.first)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateMovement(touches.first)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        movement = .init()
    }

    private func updateMovement(_ touch: UITouch?) {
        guard let touch else { return }
        let point = touch.location(in: self)
        movement = Vector2(
            x: Double(point.x - playerNode.position.x),
            y: Double(point.y - playerNode.position.y)
        )
    }

    private func render() {
        guard let player = simulation.state.entities.first(where: { $0.kind == .player }) else { return }
        playerNode.position = CGPoint(x: player.position.x, y: player.position.y)
        suspicion = simulation.state.suspicion
        suspicionTier = simulation.state.suspicionTier.rawValue
    }
}
