import SpriteKit
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@MainActor
@Test func worldProjectorBuildsUrbanLayerNodes() throws {
    let layout = DistrictGenerator.generate(seed: 7, district: .wichita).layout
    let scene = SKScene(size: CGSize(width: 852, height: 393))
    WorldProjector().synchronize(layout: layout, district: .wichita, in: scene)
    // Projector root may be nested; search descendants
    func find(_ name: String) -> SKNode? {
        func walk(_ n: SKNode) -> SKNode? {
            if n.name == name { return n }
            for c in n.children { if let m = walk(c) { return m } }
            return nil
        }
        for c in scene.children { if let m = walk(c) { return m } }
        return nil
    }
    #expect(find("urban-ground") != nil)
    #expect(find("urban-roads") != nil)
    #expect(find("urban-sidewalks") != nil)
    #expect(find("urban-buildings") != nil)
    #expect(find("urban-props") != nil)
}

@MainActor
@Test func worldProjectorUrbanGroundAndRoadsContainGeometry() throws {
    let layout = DistrictGenerator.generate(seed: 7, district: .wichita).layout
    let scene = SKScene(size: CGSize(width: 852, height: 393))
    WorldProjector().synchronize(layout: layout, district: .wichita, in: scene)

    func find(_ name: String) -> SKNode? {
        func walk(_ n: SKNode) -> SKNode? {
            if n.name == name { return n }
            for c in n.children { if let m = walk(c) { return m } }
            return nil
        }
        for c in scene.children { if let m = walk(c) { return m } }
        return nil
    }

    let ground = try #require(find("urban-ground"))
    let roads = try #require(find("urban-roads"))
    let sidewalks = try #require(find("urban-sidewalks"))
    let buildings = try #require(find("urban-buildings"))

    #expect(!ground.children.isEmpty)
    #expect(!roads.children.isEmpty)
    // Sidewalks only when layout has obstacles
    if !layout.obstacles.isEmpty {
        #expect(!sidewalks.children.isEmpty)
        #expect(!buildings.children.isEmpty)
    }
}

@MainActor
@Test func worldProjectorBuildingStackHasShadowAndBody() throws {
    let layout = WorldLayout(
        bounds: WorldBounds(minX: -100, maxX: 100, minY: -100, maxY: 100),
        obstacles: [WorldObstacle(id: 3, center: .init(x: 0, y: 0), halfSize: .init(x: 25, y: 20))]
    )
    let scene = SKScene(size: CGSize(width: 400, height: 300))
    WorldProjector().synchronize(layout: layout, district: .tulsa, in: scene)

    func find(_ name: String) -> SKNode? {
        func walk(_ n: SKNode) -> SKNode? {
            if n.name == name { return n }
            for c in n.children { if let m = walk(c) { return m } }
            return nil
        }
        for c in scene.children { if let m = walk(c) { return m } }
        return nil
    }

    let buildingsLayer = try #require(find("urban-buildings"))
    let building = try #require(buildingsLayer.childNode(withName: "building-3"))
    #expect(building.childNode(withName: "building-shadow") != nil)
    #expect(building.childNode(withName: "building-foundation") != nil)
    #expect(building.childNode(withName: "building-body") != nil)
    #expect(building.childNode(withName: "building-parapet") != nil)
}
