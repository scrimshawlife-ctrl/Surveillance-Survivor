/// Builds the authoritative starting world for a district from its authored
/// simulation profile. Geometry and sensor placement are content; this generator
/// only assigns deterministic identity and resolves archetype statistics.
public enum DistrictGenerator {
    /// Free walkable ring outside authored block footprints (world units).
    /// Expands layout bounds only — obstacles/spawns stay where content authored them —
    /// so the city is bordered by navigable space before the hard wall.
    public static let navigablePerimeterMargin: Double = 220

    public static func generate(seed: UInt64, district: DistrictID) -> (layout: WorldLayout, sensors: [Entity]) {
        var rng = DeterministicRNG(seed: seed ^ 0x5041524B494E47)
        let profile = district.profile

        let obstacles = profile.obstacles.map {
            WorldObstacle(id: rng.next(), center: $0.center, halfSize: $0.halfSize)
        }

        let sensors = profile.startingSensors.map { placement in
            Entity(
                id: rng.next(),
                kind: .cameraPole,
                sensorArchetype: placement.archetype,
                position: placement.position,
                heading: placement.heading,
                health: placement.archetype.health,
                radius: placement.archetype.radius
            )
        }

        let b = profile.bounds
        let m = navigablePerimeterMargin
        let layoutBounds = WorldBounds(
            minX: b.minX - m,
            maxX: b.maxX + m,
            minY: b.minY - m,
            maxY: b.maxY + m
        )
        return (WorldLayout(bounds: layoutBounds, obstacles: obstacles), sensors)
    }
}

/// The campaign-opening Big-Box Parking Expanse. Retained as the named entry
/// point for Wichita, which authors the original vertical-slice layout.
public enum ParkingLotGenerator {
    public static func generate(seed: UInt64) -> (layout: WorldLayout, cameras: [Entity]) {
        let generated = DistrictGenerator.generate(seed: seed, district: .wichita)
        return (generated.layout, generated.sensors)
    }
}
