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
        lastResolvedKinds = events.compactMap { event -> RunEvent.Kind? in
            switch event.kind {
            case .tierChanged, .upgradeOffered, .extractionOpened, .extractionCompleted,
                 .playerDamaged, .playerDefeated:
                return event.kind
            case .entityDestroyed where event.message.contains(EntityKind.cameraPole.rawValue):
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
        for event in events {
            switch event.kind {
            case .tierChanged:
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                lastPlayCount += 1
            case .upgradeOffered:
                UISelectionFeedbackGenerator().selectionChanged()
                lastPlayCount += 1
            case .extractionOpened, .extractionCompleted:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                lastPlayCount += 1
            case .playerDamaged:
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                lastPlayCount += 1
            case .playerDefeated:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                lastPlayCount += 1
            case .entityDestroyed where event.message.contains(EntityKind.cameraPole.rawValue):
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                lastPlayCount += 1
            default:
                break
            }
        }
    }
}
