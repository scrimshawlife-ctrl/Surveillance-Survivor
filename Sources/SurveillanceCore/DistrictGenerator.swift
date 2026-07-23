/// Builds the authoritative starting world for a district from its authored
/// simulation profile. Geometry and sensor placement are content; this generator
/// only assigns deterministic identity and resolves archetype statistics.
public enum DistrictGenerator {
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

        return (WorldLayout(bounds: profile.bounds, obstacles: obstacles), sensors)
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
