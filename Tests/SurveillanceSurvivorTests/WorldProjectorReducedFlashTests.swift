import CoreGraphics
import SpriteKit
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@MainActor
@Test func worldProjectorReducedFlashDimsCityOverlayWithoutRemovingWayfinding() throws {
    let layout = phoneScaleTestLayout()
    let standardScene = SKScene(size: CGSize(width: 852, height: 393))
    let reducedScene = SKScene(size: CGSize(width: 852, height: 393))

    WorldProjector().synchronize(layout: layout, district: .newYorkCity, reducedFlash: false, in: standardScene)
    WorldProjector().synchronize(layout: layout, district: .newYorkCity, reducedFlash: true, in: reducedScene)

    let standardOverlay = try #require(standardScene.descendant(named: "city-wayfinding-newYorkCity"))
    let reducedOverlay = try #require(reducedScene.descendant(named: "city-wayfinding-newYorkCity"))

    #expect(abs(standardOverlay.alpha - WorldProjector.CityOverlayPresentation.standardAlpha) < 0.001)
    #expect(abs(reducedOverlay.alpha - WorldProjector.CityOverlayPresentation.reducedFlashAlpha) < 0.001)
    #expect(reducedOverlay.alpha < standardOverlay.alpha)

    let standardLabels = standardOverlay.descendants(of: SKLabelNode.self)
    let reducedLabels = reducedOverlay.descendants(of: SKLabelNode.self)
    #expect(!standardLabels.isEmpty)
    #expect(reducedLabels.count == standardLabels.count)
    #expect(reducedLabels.contains { $0.text?.contains("BOROUGH SYNC") == true })
}

@MainActor
@Test func worldProjectorCityOverlayKeepsPhoneScaleCoverageAndLabelsInReducedFlash() throws {
    let layout = phoneScaleTestLayout()
    let scene = SKScene(size: CGSize(width: 852, height: 393))

    WorldProjector().synchronize(layout: layout, district: .atlanta, reducedFlash: true, in: scene)

    let overlay = try #require(scene.descendant(named: "city-wayfinding-atlanta"))
    let shapes = overlay.descendants(of: SKShapeNode.self)
    let labels = overlay.descendants(of: SKLabelNode.self)
    let overlayBounds = shapes.reduce(CGRect.null) { partial, node in
        partial.union(node.calculateAccumulatedFrame())
    }
    let worldRect = CGRect(x: layout.bounds.minX, y: layout.bounds.minY, width: layout.bounds.maxX - layout.bounds.minX, height: layout.bounds.maxY - layout.bounds.minY)

    #expect(shapes.count >= 20)
    #expect(labels.count >= 10)
    #expect(overlayBounds.width >= worldRect.width * 0.75)
    #expect(overlayBounds.height >= worldRect.height * 0.70)
    #expect(labels.allSatisfy { $0.fontSize >= WorldProjector.CityOverlayPresentation.phoneMinimumLabelSize })
    #expect(labels.contains { $0.text?.contains("LOCAL → REGIONAL") == true })
}

private func phoneScaleTestLayout() -> WorldLayout {
    WorldLayout(
        bounds: WorldBounds(minX: -640, maxX: 640, minY: -360, maxY: 360),
        obstacles: []
    )
}

private extension SKNode {
    func descendant(named name: String) -> SKNode? {
        if self.name == name { return self }
        for child in children {
            if let match = child.descendant(named: name) { return match }
        }
        return nil
    }

    func descendants<T: SKNode>(of type: T.Type) -> [T] {
        children.flatMap { child -> [T] in
            var matches = child.descendants(of: type)
            if let typed = child as? T {
                matches.insert(typed, at: 0)
            }
            return matches
        }
    }
}
