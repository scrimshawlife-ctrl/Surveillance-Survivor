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

@Test func urbanDressBuildingCurbExpandsFootprint() {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -200, maxX: 200, minY: -200, maxY: 200),
        obstacles: [
            WorldObstacle(id: 7, center: .init(x: 0, y: 0), halfSize: .init(x: 20, y: 15))
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .louisville)
    let b = dress.buildings[0]
    #expect(b.footprint.minX == -20 && b.footprint.maxX == 20)
    #expect(b.sidewalkOuter.minX == -20 - UrbanDressBuilder.buildingCurbWidth)
    #expect(b.sidewalkOuter.maxX == 20 + UrbanDressBuilder.buildingCurbWidth)
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

@Test func urbanDressStreetsHaveFlankingSidewalks() {
    // Wide free bands so H and V corridors both form.
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -200, maxX: 200, minY: -200, maxY: 200),
        obstacles: [
            WorldObstacle(id: 1, center: .init(x: -100, y: 100), halfSize: .init(x: 40, y: 30)),
            WorldObstacle(id: 2, center: .init(x: 100, y: 100), halfSize: .init(x: 40, y: 30)),
            WorldObstacle(id: 3, center: .init(x: -100, y: -100), halfSize: .init(x: 40, y: 30)),
            WorldObstacle(id: 4, center: .init(x: 100, y: -100), halfSize: .init(x: 40, y: 30)),
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .tulsa)
    #expect(!dress.roads.isEmpty)
    #expect(dress.sidewalks.count >= 2)

    let sw = UrbanDressBuilder.streetSidewalkWidth
    // Street sidewalks are thin bands (thickness ≈ sidewalk width). Length may be short
    // after punching intersections, but thickness stays the curb strip.
    for sidewalk in dress.sidewalks {
        let thin = min(sidewalk.width, sidewalk.height)
        #expect(thin <= sw + 0.5)
        #expect(thin >= sw - 0.5 || thin >= 2) // full strip or residual clip fragment
    }

    // Carriageways are wider than a single sidewalk strip (two-lane room).
    for road in dress.roads {
        let thickness = min(road.width, road.height)
        #expect(thickness + 1e-6 >= UrbanDressBuilder.minCarriagewayWidth - 1)
    }

    // At least some long street-edge sidewalks remain (not only tiny intersection crumbs).
    let longSidewalks = dress.sidewalks.filter {
        max($0.width, $0.height) >= UrbanDressBuilder.minCarriagewayWidth
    }
    #expect(longSidewalks.count >= 2)
}

@Test func urbanDressStreetSidewalksDoNotOverlapCarriagewayInteriors() {
    let layout = DistrictGenerator.generate(seed: 7, district: .wichita).layout
    let dress = UrbanDressBuilder.build(layout: layout, district: .wichita)
    for sidewalk in dress.sidewalks {
        for road in dress.roads {
            #expect(!sidewalk.intersectsInterior(of: road))
        }
    }
    for parking in dress.parking {
        for road in dress.roads {
            #expect(!parking.intersectsInterior(of: road))
        }
    }
}

@Test func urbanDressWideCorridorsIncludeParkingStrips() {
    // Gaps large enough for sidewalk + parking + carriageway on both axes.
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -300, maxX: 300, minY: -300, maxY: 300),
        obstacles: [
            WorldObstacle(id: 1, center: .init(x: -160, y: 160), halfSize: .init(x: 50, y: 40)),
            WorldObstacle(id: 2, center: .init(x: 160, y: 160), halfSize: .init(x: 50, y: 40)),
            WorldObstacle(id: 3, center: .init(x: -160, y: -160), halfSize: .init(x: 50, y: 40)),
            WorldObstacle(id: 4, center: .init(x: 160, y: -160), halfSize: .init(x: 50, y: 40)),
        ]
    )
    let dress = UrbanDressBuilder.build(layout: layout, district: .columbus)
    #expect(!dress.parking.isEmpty)
    let pk = UrbanDressBuilder.streetParkingWidth
    for band in dress.parking {
        let thin = min(band.width, band.height)
        #expect(thin <= pk + 0.5)
    }
}
