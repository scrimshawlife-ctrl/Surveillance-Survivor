import CoreGraphics
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

// Art QA structural guards — hierarchy + density helpers used by existing projectors.

@Test func visualCombatLayersPlayerAboveHostileAndDeployable() {
    #expect(VisualCombatLayers.entityLayer(for: .player) > VisualCombatLayers.entityLayer(for: .boss))
    #expect(VisualCombatLayers.entityLayer(for: .player) > VisualCombatLayers.entityLayer(for: .securityGuard))
    #expect(VisualCombatLayers.entityLayer(for: .player) > VisualCombatLayers.entityLayer(for: .cameraPole))
    #expect(VisualCombatLayers.entityLayer(for: .player) > VisualCombatLayers.entityLayer(for: .mirrorArray))
    #expect(VisualCombatLayers.entityLayer(for: .player) > VisualCombatLayers.entityLayer(for: .signalFlood))
}

@Test func visualCombatLayersProjectileAboveBodies() {
    #expect(VisualCombatLayers.entityLayer(for: .projectile) > VisualCombatLayers.entityLayer(for: .player))
    #expect(VisualCombatLayers.entityLayer(for: .projectile) > VisualCombatLayers.entityLayer(for: .boss))
    #expect(VisualCombatLayers.entityLayer(for: .projectile) > VisualCombatLayers.entityLayer(for: .securityGuard))
}

@Test func visualCombatLayersGhostTrailBetweenExtractionAndPlayer() {
    #expect(VisualCombatLayers.ghostTrail > VisualCombatLayers.extraction)
    #expect(VisualCombatLayers.ghostTrail < VisualCombatLayers.player)
}

@Test func visualCombatLayersLandmarkZoneUnderCombatEntities() {
    #expect(VisualCombatLayers.landmarkZone < VisualCombatLayers.deployable)
    #expect(VisualCombatLayers.landmarkZone < VisualCombatLayers.securityGuard)
    #expect(VisualCombatLayers.landmarkZone < VisualCombatLayers.player)
}

@Test func visualCombatLayersPreservesPriorPlayerAndGhostConstants() {
    // Do not drift from historical magic numbers without an explicit product change.
    #expect(VisualCombatLayers.player == 30)
    #expect(VisualCombatLayers.ghostTrail == 25)
}

@Test func visualCombatPaletteDensityScaleMonotonicSoftening() {
    let sparse = VisualCombatPalette.densityScale(entityCount: 10)
    let mid = VisualCombatPalette.densityScale(entityCount: 55)
    let dense = VisualCombatPalette.densityScale(entityCount: 90)
    let stacked = VisualCombatPalette.densityScale(entityCount: 140)
    #expect(sparse == 1.0)
    #expect(mid < sparse)
    #expect(dense < mid)
    #expect(stacked < dense)
    #expect(stacked >= 0.5)
}

@Test func visualCombatPaletteHostileConeAlphaSoftensWithDensity() {
    let full = VisualCombatPalette.hostileConeFill(densityScale: 1)
    let soft = VisualCombatPalette.hostileConeFill(densityScale: 0.55)
    var fullA: CGFloat = 0
    var softA: CGFloat = 0
    full.getRed(nil, green: nil, blue: nil, alpha: &fullA)
    soft.getRed(nil, green: nil, blue: nil, alpha: &softA)
    #expect(softA < fullA)
    #expect(abs(fullA - 0.12) < 0.001)
}

@Test func visualCombatPaletteLandmarkZoneDimmerWhenOutside() {
    var insideA: CGFloat = 0
    var outsideA: CGFloat = 0
    VisualCombatPalette.landmarkZoneStroke(inside: true)
        .getRed(nil, green: nil, blue: nil, alpha: &insideA)
    VisualCombatPalette.landmarkZoneStroke(inside: false)
        .getRed(nil, green: nil, blue: nil, alpha: &outsideA)
    #expect(insideA > outsideA)
}
