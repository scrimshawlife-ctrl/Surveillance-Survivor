import SpriteKit
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

// The drawn scan cone is a promise about where the player gets detected. It was
// hardcoded to radius 403 / half-angle pi/7, which matches lprCameraPole and no
// other archetype — so five of six sensors drew a detection volume they did not
// have. These pin the drawing to the same values Simulation tests against.

@MainActor
private func conePath(for archetype: SensorArchetype) -> CGPath? {
    let scene = SKScene(size: CGSize(width: 800, height: 800))
    let projector = EntityProjector()
    let camera = Entity(
        id: 1, kind: .cameraPole, sensorArchetype: archetype,
        position: .init(), heading: 0, health: 60, radius: 20
    )
    projector.synchronize(entities: [camera], in: scene)
    return (scene.childNode(withName: "entity-1")?
        .childNode(withName: "scan-cone") as? SKShapeNode)?.path
}

/// A point at `fraction` of scan range, `degrees` off the sensor's facing.
private func probe(_ archetype: SensorArchetype, fraction: Double, degrees: Double) -> CGPoint {
    let r = archetype.scanRange * fraction
    let a = degrees * .pi / 180
    return CGPoint(x: r * cos(a), y: r * sin(a))
}

@MainActor
@Test func everySensorDrawsItsOwnDetectionRange() {
    // Tested by containment rather than bounding box: CGPath.boundingBox includes
    // Bezier control points and overshoots an arc, and containment is the actual
    // promise the cone makes to the player.
    for archetype in SensorArchetype.allCases {
        guard let path = conePath(for: archetype) else {
            Issue.record("\(archetype.rawValue) drew no cone")
            continue
        }
        #expect(
            path.contains(probe(archetype, fraction: 0.9, degrees: 0)),
            "\(archetype.rawValue) must cover 90% of its \(archetype.scanRange) range"
        )
        #expect(
            !path.contains(probe(archetype, fraction: 1.1, degrees: 0)),
            "\(archetype.rawValue) must not claim beyond its \(archetype.scanRange) range"
        )
    }
}

@MainActor
@Test func everySensorDrawsItsOwnHalfAngle() {
    for archetype in SensorArchetype.allCases {
        guard let half = archetype.scanHalfAngle, let path = conePath(for: archetype) else { continue }
        let halfDegrees = half * 180 / .pi
        #expect(
            path.contains(probe(archetype, fraction: 0.6, degrees: halfDegrees * 0.7)),
            "\(archetype.rawValue) must cover inside its \(halfDegrees) degree half-angle"
        )
        #expect(
            !path.contains(probe(archetype, fraction: 0.6, degrees: halfDegrees + 12)),
            "\(archetype.rawValue) must not claim beyond its half-angle"
        )
    }
}

@MainActor
@Test func omnidirectionalSensorIsNotDrawnAsAWedge() {
    // acousticGunshotDetector has no scanHalfAngle: the sim checks range alone, so
    // it detects all around. A wedge would imply a blind side that does not exist.
    let acoustic = SensorArchetype.acousticGunshotDetector
    #expect(acoustic.scanHalfAngle == nil)
    guard let path = conePath(for: acoustic) else {
        Issue.record("no cone")
        return
    }
    for bearing in [0.0, 90.0, 180.0, 270.0] {
        #expect(path.contains(probe(acoustic, fraction: 0.9, degrees: bearing)),
                "omnidirectional sensor must cover bearing \(bearing)")
    }
}

@MainActor
@Test func directionalSensorsKeepABlindSideBehindThem() {
    for archetype in SensorArchetype.allCases {
        guard let half = archetype.scanHalfAngle, half < .pi / 2,
              let path = conePath(for: archetype) else { continue }
        #expect(!path.contains(probe(archetype, fraction: 0.6, degrees: 180)),
                "\(archetype.rawValue) must stay blind behind itself")
    }
}

@MainActor
@Test func aPooledCameraNodeRebuildsTheConeForItsNewSensor() {
    // Nodes are pooled by kind, so a recycled camera could otherwise keep the
    // previous archetype's detection volume and mislead for the rest of the run.
    let scene = SKScene(size: CGSize(width: 800, height: 800))
    let projector = EntityProjector()
    let wide = Entity(id: 1, kind: .cameraPole, sensorArchetype: .panTiltZoomEye,
                      position: .init(), health: 60, radius: 20)
    projector.synchronize(entities: [wide], in: scene)
    projector.synchronize(entities: [], in: scene)

    let narrow = Entity(id: 2, kind: .cameraPole, sensorArchetype: .smartDoorbellSwarm,
                        position: .init(), health: 60, radius: 20)
    projector.synchronize(entities: [narrow], in: scene)
    guard let node = scene.childNode(withName: "entity-2"),
          let cone = node.childNode(withName: "scan-cone") as? SKShapeNode,
          let path = cone.path else {
        Issue.record("recycled camera lost its cone")
        return
    }
    // The recycled node must claim the doorbell's 260, not the eye's 520.
    let doorbell = SensorArchetype.smartDoorbellSwarm
    #expect(path.contains(probe(doorbell, fraction: 0.9, degrees: 0)))
    #expect(!path.contains(probe(doorbell, fraction: 1.4, degrees: 0)),
            "recycled node kept the previous sensor's longer cone")
}

@MainActor
@Test func cameraMastSwivelStaysWithinItsArc() {
    // The mast leans toward what it is scanning and returns. It must never rotate
    // past the arc: the pole art is a vertical mast seen from above, and a full
    // revolution reads as it toppling. Bounded decoration over sim-owned heading.
    for step in 0..<72 {
        let heading = CGFloat(step) * .pi / 36
        let swivel = EntityProjector.cameraSwivel(for: heading)
        #expect(abs(swivel) <= EntityProjector.cameraSwivelLimit + 0.0001,
                "swivel \(swivel) escaped the arc at heading \(heading)")
    }
    // It has to actually move, or the camera reads as dead hardware.
    #expect(EntityProjector.cameraSwivel(for: .pi / 2) > 0.2)
    #expect(EntityProjector.cameraSwivel(for: -.pi / 2) < -0.2)
    #expect(abs(EntityProjector.cameraSwivel(for: 0)) < 0.0001)
}

@MainActor
@Test func scanningCameraHoldsItsStillRatherThanATranslatingClip() {
    // lpr_scan_loop drifts 52px horizontally across its frames, so playing it walked
    // the camera off its tile. A scanning pole must resolve to the health-derived
    // still until a position-stable bank exists.
    #expect(AnimationClipCatalog.clip(for: .cameraPole, state: .scanning) == nil)
    // The destroy sequence is a one-shot in place and stays wired.
    #expect(AnimationClipCatalog.clip(for: .cameraPole, state: .destroyed)?.stem == "lpr_destroy_sequence")
}

@MainActor
@Test func theHeadSwivelsAndTheMastDoesNot() {
    // First attempt rotated the whole body and the pole read as toppling. The mast
    // is fixed hardware; only the camera unit on top turns.
    let scene = SKScene(size: CGSize(width: 800, height: 800))
    let projector = EntityProjector()
    let camera = Entity(
        id: 1, kind: .cameraPole, sensorArchetype: .lprCameraPole,
        position: .init(), heading: .pi / 2, health: 60, radius: 20
    )
    projector.synchronize(entities: [camera], in: scene)
    guard let node = scene.childNode(withName: "entity-1") else {
        Issue.record("camera did not project")
        return
    }
    guard let head = node.childNode(withName: "camera-head") else {
        Issue.record("camera head missing — the housing is what reads as a camera")
        return
    }
    #expect(abs(head.zRotation) > 0.2, "head must track the scan heading")
    #expect(node.childNode(withName: "body")?.zRotation == 0, "mast must stay upright")
    #expect(node.zRotation == 0)
    // The housing sits on top of the mast, not at its base.
    #expect(head.position.y > 40, "head should ride the top of the mast")
}

@MainActor
@Test func aDestroyedPoleDropsItsIntactHousing() {
    // lpr_destroyed draws its own wrecked camera; an intact housing floating over
    // the wreck would read as the pole being fine.
    let scene = SKScene(size: CGSize(width: 800, height: 800))
    let projector = EntityProjector()
    let wrecked = Entity(
        id: 2, kind: .cameraPole, sensorArchetype: .lprCameraPole,
        position: .init(), health: 0, radius: 20
    )
    projector.synchronize(entities: [wrecked], in: scene)
    let head = scene.childNode(withName: "entity-2")?.childNode(withName: "camera-head")
    #expect(head?.isHidden == true)
}
