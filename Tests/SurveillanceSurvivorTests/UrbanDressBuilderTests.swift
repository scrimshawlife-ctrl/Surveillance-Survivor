import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test func urbanDressMapsEveryObstacleToBuilding() {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -200, maxX: 200, minY: -150, maxY: 150),
        obstacles: [
            WorldObstacle(id: 1, center: .init(x: -80, y: 40), halfSize: .init(x: 30, y: 25)),
            WorldObstacle(id: 2, center: .init(x: 90, y: -20), halfSize: .init(x: 40, y: 20))
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .wichita)
    #expect(dress.buildings.count == 2)
    #expect(Set(dress.buildings.map(\.obstacleID)) == [1, 2])
}

@Test func urbanDressSidewalkExpandsFootprint() {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -200, maxX: 200, minY: -200, maxY: 200),
        obstacles: [
            WorldObstacle(id: 7, center: .init(x: 0, y: 0), halfSize: .init(x: 20, y: 15))
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .louisville)
    let b = dress.buildings[0]
    #expect(b.footprint.minX == -20 && b.footprint.maxX == 20)
    #expect(b.sidewalkOuter.minX == -20 - UrbanDressBuilder.sidewalkWidth)
    #expect(b.sidewalkOuter.maxX == 20 + UrbanDressBuilder.sidewalkWidth)
}

@Test func urbanDressRoadsDoNotOverlapBuildingFootprints() {
    let layout = DistrictGenerator.generate(seed: 42, district: .wichita).layout
    let dress = UrbanDressBuilder.build(layout: layout, district: .wichita)
    for road in dress.roads {
        for building in dress.buildings {
            #expect(!road.intersectsInterior(of: building.footprint))
        }
    }
}

@Test func urbanDressIsDeterministic() {
    let layout = DistrictGenerator.generate(seed: 99, district: .newYorkCity).layout
    let a = UrbanDressBuilder.build(layout: layout, district: .newYorkCity)
    let b = UrbanDressBuilder.build(layout: layout, district: .newYorkCity)
    #expect(a == b)
}
