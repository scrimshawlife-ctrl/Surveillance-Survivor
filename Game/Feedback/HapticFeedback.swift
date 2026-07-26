import UIKit
import SurveillanceCore

/// Platform haptic adapter. Consumes run events; never mutates simulation state.
@MainActor
final class HapticFeedback {
    var isEnabled = true
    /// Number of platform outputs requested (for tests). Zero when disabled.
    private(set) var lastPlayCount = 0
    /// Kinds that would fire when enabled (always recorded for diagnostics).
    private(set) var lastResolvedKinds: [RunEvent.Kind] = []

    func play(_ events: [RunEvent]) {
        // Lethal contact can emit damage + defeat in one batch; keep only the defeat pulse.
        let suppressDamage = events.contains { $0.kind == .playerDefeated }
        // Same-tick Blind Spot open+complete should not double-stinger.
        let suppressExtractionOpened = events.contains { $0.kind == .extractionCompleted }
        // Multi-camera kills in one tick should feel like one shatter, not a burst.
        var emittedCameraDestroy = false
        lastResolvedKinds = events.compactMap { event -> RunEvent.Kind? in
            switch event.kind {
            case .tierChanged, .upgradeOffered, .extractionCompleted, .playerDefeated:
                return event.kind
            case .extractionOpened where !suppressExtractionOpened:
                return event.kind
            case .playerDamaged where !suppressDamage:
                return event.kind
            case .entityDestroyed where event.message.contains(EntityKind.cameraPole.rawValue):
                if emittedCameraDestroy { return nil }
                emittedCameraDestroy = true
                return event.kind
            default:
                return nil
            }
        }
        guard isEnabled else {
            lastPlayCount = 0
            return
        }
        lastPlayCount = 0
        for kind in lastResolvedKinds {
            switch kind {
            case .tierChanged:
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                lastPlayCount += 1
            case .upgradeOffered:
                UISelectionFeedbackGenerator().selectionChanged()
                lastPlayCount += 1
            case .extractionOpened:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                lastPlayCount += 1
            case .extractionCompleted:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                lastPlayCount += 1
            case .playerDamaged:
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                lastPlayCount += 1
            case .playerDefeated:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                lastPlayCount += 1
            case .entityDestroyed:
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                lastPlayCount += 1
            default:
                break
            }
        }
    }
}
