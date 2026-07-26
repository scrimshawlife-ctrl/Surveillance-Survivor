import Foundation
import SurveillanceCore

/// Presentation state machines driven by authoritative entity fields only.
enum EntityAnimationState: String, Sendable, Equatable {
    case idle
    case moving
    case attacking
    case damaged
    case statusAffected
    case defeated
    case extracting
    case deploying
    case active
    case expended
    case scanning
    case disabled
    case destroyed
}

enum EntityAnimationStateMachine {
    /// Player-facing clip selection. Does not infer combat outcomes from animation time.
    /// `nearExtraction` must reflect sim overlap with the Blind Spot entity — open alone is not enough.
    static func playerState(
        entity: Entity,
        extractionOpen: Bool,
        nearExtraction: Bool = false
    ) -> EntityAnimationState {
        if entity.health <= 0 { return .defeated }
        if extractionOpen, nearExtraction, hypot(entity.velocity.x, entity.velocity.y) < 4 {
            return .extracting
        }
        if entity.health < 30 { return .damaged }
        let speed = hypot(entity.velocity.x, entity.velocity.y)
        return speed > 8 ? .moving : .idle
    }

    static func cameraState(entity: Entity) -> EntityAnimationState {
        if entity.health <= 0 { return .destroyed }
        if entity.sensorDisabledUntilTick != nil { return .disabled }
        if entity.disruptedUntilTick != nil { return .statusAffected }
        return .scanning
    }

    static func deployableState(entity: Entity, tick: UInt64) -> EntityAnimationState {
        if let expires = entity.effectExpiresAtTick, tick >= expires { return .expended }
        // First few ticks after spawn are not tracked separately; treat healthy deployables as active.
        if entity.health <= 0 { return .expended }
        return .active
    }

    static func hostileState(entity: Entity) -> EntityAnimationState {
        if entity.health <= 0 { return .defeated }
        if entity.processing != nil || entity.disruptedUntilTick != nil { return .statusAffected }
        let speed = hypot(entity.velocity.x, entity.velocity.y)
        return speed > 6 ? .moving : .idle
    }

    static func state(
        for entity: Entity,
        tick: UInt64,
        extractionOpen: Bool,
        nearExtraction: Bool = false
    ) -> EntityAnimationState {
        switch entity.kind {
        case .player:
            return playerState(
                entity: entity,
                extractionOpen: extractionOpen,
                nearExtraction: nearExtraction
            )
        case .cameraPole:
            return cameraState(entity: entity)
        case .mirrorArray, .signalFlood, .extraction:
            return deployableState(entity: entity, tick: tick)
        case .securityGuard, .boss:
            return hostileState(entity: entity)
        case .projectile:
            return .moving
        }
    }
}
