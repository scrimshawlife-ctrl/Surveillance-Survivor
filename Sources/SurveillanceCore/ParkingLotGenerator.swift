public enum ParkingLotGenerator {
    public static func generate(seed: UInt64) -> (layout: WorldLayout, cameras: [Entity]) {
        var rng = DeterministicRNG(seed: seed ^ 0x5041524B494E47)
        let bounds = WorldBounds(minX: -900, maxX: 900, minY: -540, maxY: 540)
        var obstacles: [WorldObstacle] = []

        // Four deterministic parking islands leave broad traversal lanes between them.
        let rows = [-250.0, 250.0]
        let columns = [-420.0, 420.0]
        for y in rows {
            for x in columns {
                obstacles.append(
                    WorldObstacle(
                        id: rng.next(),
                        center: Vector2(x: x, y: y),
                        halfSize: Vector2(x: 150, y: 48)
                    )
                )
            }
        }

        // A central checkout island creates a readable loop without blocking spawn.
        obstacles.append(
            WorldObstacle(
                id: rng.next(),
                center: Vector2(x: 0, y: 0),
                halfSize: Vector2(x: 78, y: 78)
            )
        )

        let cameraPositions = [
            Vector2(x: -720, y: -360),
            Vector2(x: 720, y: -360),
            Vector2(x: -720, y: 360),
            Vector2(x: 720, y: 360)
        ]
        let cameras = cameraPositions.enumerated().map { index, position in
            Entity(
                id: rng.next(),
                kind: .cameraPole,
                position: position,
                heading: Double(index) * .pi / 2,
                health: 60,
                radius: 22
            )
        }

        return (WorldLayout(bounds: bounds, obstacles: obstacles), cameras)
    }
}
