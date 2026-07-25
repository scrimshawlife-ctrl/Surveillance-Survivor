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

@Test func presentationQualityTierDensityScaleUsesCombatLimitsCalibration() {
    // Reuses PresentationQualityTier + CombatLimits.maximumProjectiles (96).
    let cap = CombatLimits.maximumProjectiles
    let sparse = PresentationQualityTier.full.densityScale(entityCount: 10)
    let mid = PresentationQualityTier.full.densityScale(entityCount: cap / 2 + 5)
    let dense = PresentationQualityTier.full.densityScale(entityCount: (cap * 3) / 4 + 5)
    let stacked = PresentationQualityTier.full.densityScale(entityCount: cap + 10)
    #expect(sparse == 1.0)
    #expect(mid < sparse)
    #expect(dense < mid)
    #expect(stacked < dense)
    #expect(stacked >= 0.5)
    // Accessibility tiers further calm area FX on the same ladder.
    #expect(
        PresentationQualityTier.minimal.densityScale(entityCount: 10)
            < PresentationQualityTier.full.densityScale(entityCount: 10)
    )
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

/// Art QA: every WeaponID maps through the real GameAssetName presentation path.
@Test func gameAssetNameProjectileOrDeployableCoversAllSixWeapons() {
    #expect(WeaponID.allCases.count == 6)
    for weapon in WeaponID.allCases {
        switch weapon {
        case .kineticCountermeasure:
            #expect(GameAssetName.Projectile.asset(for: weapon) == GameAssetName.Projectile.default)
        case .redactionOrdinance:
            #expect(GameAssetName.Projectile.asset(for: weapon) == GameAssetName.Projectile.redaction)
        case .identityTransponder:
            #expect(GameAssetName.Projectile.asset(for: weapon) == GameAssetName.Projectile.identity)
        case .foiaSwarm:
            #expect(GameAssetName.Projectile.asset(for: weapon) == GameAssetName.Projectile.foia)
        case .mirrorArray:
            // Deployable path — still present as named runtime stems.
            #expect(!GameAssetName.Deployable.mirrorArray.isEmpty)
            #expect(GameAssetName.Deployable.threeStateMirror.count == 4)
        case .signalFlood:
            #expect(!GameAssetName.Deployable.signalFlood.isEmpty)
            #expect(GameAssetName.Deployable.threeStateSignalFlood.count == 4)
        }
    }
}

@Test func visualCombatLayersExtractionAboveHostileBodies() {
    #expect(VisualCombatLayers.extraction > VisualCombatLayers.boss)
    #expect(VisualCombatLayers.extraction > VisualCombatLayers.cameraPole)
    #expect(VisualCombatLayers.player > VisualCombatLayers.extraction)
}

/// F-P2-02: processing vs disrupt use different silhouette + weight (not color alone).
@Test func visualCombatStatusRingKindsDifferByShapeGrammar() {
    #expect(VisualCombatPalette.statusRingKind(processing: true, disrupted: false) == .processing)
    #expect(VisualCombatPalette.statusRingKind(processing: false, disrupted: true) == .disrupt)
    #expect(VisualCombatPalette.statusRingKind(processing: false, disrupted: false) == nil)
    // Processing wins when both flags set (bureaucracy stamp primary).
    #expect(VisualCombatPalette.statusRingKind(processing: true, disrupted: true) == .processing)

    #expect(VisualCombatPalette.statusRingLineWidth(kind: .processing)
        != VisualCombatPalette.statusRingLineWidth(kind: .disrupt))

    let procPath = VisualCombatPalette.statusRingPath(kind: .processing)
    let disruptPath = VisualCombatPalette.statusRingPath(kind: .disrupt)
    // Rounded stamp vs open ellipse — non-color shape channel.
    #expect(procPath != disruptPath)
    let procBox = procPath.boundingBoxOfPath
    let disruptBox = disruptPath.boundingBoxOfPath
    #expect(abs(procBox.width - disruptBox.width) < 0.01)
    #expect(abs(procBox.height - disruptBox.height) < 0.01)
}

/// F-P3-01: flood field is cooler teal, not FOIA yellow family.
@Test func visualCombatFloodPaletteIsNotFoiaYellow() {
    let flood = VisualCombatPalette.floodFill(reducedFlash: false, densityScale: 1)
    let foia = VisualCombatPalette.foiaFill
    var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
    var yr: CGFloat = 0, yg: CGFloat = 0, yb: CGFloat = 0, ya: CGFloat = 0
    flood.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
    foia.getRed(&yr, green: &yg, blue: &yb, alpha: &ya)
    // Flood is cyan-teal: blue channel dominates red; FOIA yellow has high R+G, low B.
    #expect(fb > fr)
    #expect(yg > yb)
    #expect(abs(fr - yr) > 0.15 || abs(fb - yb) > 0.15)
}
