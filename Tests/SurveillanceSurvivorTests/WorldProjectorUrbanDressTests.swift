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

    func spritesWithVisualRole(in node: SKNode) -> [(sprite: SKSpriteNode, role: String)] {
        var found: [(SKSpriteNode, String)] = []
        if let sprite = node as? SKSpriteNode,
           let role = sprite.userData?["visual-role"] as? String
        {
            found.append((sprite, role))
        }
        for child in node.children {
            found.append(contentsOf: spritesWithVisualRole(in: child))
        }
        return found
    }

    func isDescendant(_ node: SKNode, of ancestor: SKNode) -> Bool {
        var current = node.parent
        while let c = current {
            if c === ancestor { return true }
            current = c.parent
        }
        return false
    }

    let props = try #require(find("urban-props"))
    let buildings = try #require(find("urban-buildings"))
    let urbanRoot = try #require(props.parent)

    let landmarkRoles: [VisualAssetMap.Role] = [.wichitaLandmarkMonument, .wichitaLandmarkBridge]
    let decalRoles: [VisualAssetMap.Role] = [.wichitaDecalRunwayStripe, .wichitaDecalGrainDust]
    let dressPropRoles = landmarkRoles + decalRoles
    let dressPropRoleNames = Set(dressPropRoles.map(\.rawValue))

    // Cap: at most 2 landmarks + 2 decals.
    #expect(props.children.count <= 4)

    // Positive parenting: each available landmark/decal role lives under urban-props only.
    let sceneRoleSprites = spritesWithVisualRole(in: scene)
    for role in dressPropRoles {
        let assetName = VisualAssetMap.entry(role).assetName
        guard TextureAssetLoader.isAvailable(assetName) else { continue }

        let matches = sceneRoleSprites.filter { $0.role == role.rawValue }
        #expect(matches.count == 1, "expected one \(role.rawValue) node when texture is available")
        for match in matches {
            #expect(
                match.sprite.parent === props,
                "\(role.rawValue) must be a direct child of urban-props, not \(String(describing: match.sprite.parent?.name))"
            )
            #expect(!isDescendant(match.sprite, of: buildings), "\(role.rawValue) must not live under urban-buildings")
            #expect(
                match.sprite.parent !== urbanRoot,
                "\(role.rawValue) must not be a direct child of the projector root"
            )
        }
    }

    // No dress-prop roles as direct children of projector root (regression for pre-props parenting).
    for child in urbanRoot.children {
        guard let sprite = child as? SKSpriteNode,
              let role = sprite.userData?["visual-role"] as? String
        else { continue }
        #expect(
            !dressPropRoleNames.contains(role),
            "dress prop role \(role) must not parent directly under projector root"
        )
    }

    // Always-meaningful pad invariant: building containers are stack shapes + optional retail only.
    // Hangar / warehouse / any landmark plate roles must never skin pads.
    let allowedBuildingChildNames: Set<String> = [
        "building-shadow", "building-foundation", "building-body", "building-parapet",
    ]
    let retailRole = VisualAssetMap.Role.envObstacleRetailMass.rawValue
    for building in buildings.children {
        #expect(building.name?.hasPrefix("building-") == true)
        for child in building.children {
            if let name = child.name, allowedBuildingChildNames.contains(name) {
                #expect(child is SKShapeNode, "stack layer \(name) must be a shape node")
                continue
            }
            // Only optional retail mass skin may appear beyond the stack.
            let sprite = try #require(child as? SKSpriteNode, "unexpected non-stack building child \(child.name ?? "?")")
            let role = sprite.userData?["visual-role"] as? String
            #expect(
                role == nil || role == retailRole,
                "building pad sprite role must be retail mass only, got \(role ?? "nil")"
            )
            #expect(role?.localizedCaseInsensitiveContains("Hangar") != true)
            #expect(role?.localizedCaseInsensitiveContains("Warehouse") != true)
            #expect(role?.localizedCaseInsensitiveContains("Landmark") != true)
            #expect(
                VisualAssetMap.entry(.envObstacleRetailMass).presentationTreatment != .landmarkPlate
            )
        }

        // No landmark-plate visual-role anywhere in the building subtree.
        for tagged in spritesWithVisualRole(in: building) {
            let treatment = VisualAssetMap.Role(rawValue: tagged.role)
                .map { VisualAssetMap.entry($0).presentationTreatment }
            #expect(treatment != .landmarkPlate, "landmark plate \(tagged.role) must not skin building pads")
            #expect(!tagged.role.localizedCaseInsensitiveContains("Hangar"))
            #expect(!tagged.role.localizedCaseInsensitiveContains("Warehouse"))
            #expect(!tagged.role.contains("Landmark"))
        }
    }

    // Wayfinding stays under calmed CityOverlayPresentation alpha (not under props).
    let wayfinding = find("city-wayfinding-wichita")
    #expect(wayfinding != nil)
    if let wayfinding {
        #expect(abs(wayfinding.alpha - WorldProjector.CityOverlayPresentation.standardAlpha) < 0.001)
        #expect(wayfinding.parent !== props)
        #expect(wayfinding.parent === urbanRoot || isDescendant(wayfinding, of: urbanRoot))
    }
}
