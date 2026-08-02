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

@MainActor
@Test func worldProjectorPropsLayerHostsLandmarksAndDecalsWhenAvailable() throws {
    // Perimeter landmarks / sparse decals parent under urban-props (not root, not pads).
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

    let props = try #require(find("urban-props"))
    let buildings = try #require(find("urban-buildings"))

    let landmarkRoles: [VisualAssetMap.Role] = [.wichitaLandmarkMonument, .wichitaLandmarkBridge]
    let decalRoles: [VisualAssetMap.Role] = [.wichitaDecalRunwayStripe, .wichitaDecalGrainDust]
    let expectedAvailable = (landmarkRoles + decalRoles).filter {
        TextureAssetLoader.isAvailable(VisualAssetMap.entry($0).assetName)
    }

    // Cap: at most 2 landmarks + 2 decals when textures load.
    #expect(props.children.count <= 4)
    if !expectedAvailable.isEmpty {
        #expect(!props.children.isEmpty)
        #expect(props.children.count <= expectedAvailable.count)
    }

    // Hangar art must not appear on building pads (pin-only perimeter landmarks).
    for building in buildings.children {
        for child in building.children {
            if let sprite = child as? SKSpriteNode,
               let role = sprite.userData?["visual-role"] as? String
            {
                #expect(!role.contains("Hangar"), "landmark hangar must not skin building pads")
            }
        }
    }

    // Wayfinding stays under calmed CityOverlayPresentation alpha (not under props).
    let wayfinding = find("city-wayfinding-wichita")
    #expect(wayfinding != nil)
    if let wayfinding {
        #expect(abs(wayfinding.alpha - WorldProjector.CityOverlayPresentation.standardAlpha) < 0.001)
        #expect(wayfinding.parent !== props)
    }
}
