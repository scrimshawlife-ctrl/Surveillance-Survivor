import UIKit
import SurveillanceCore

@MainActor
final class HapticFeedback {
    var isEnabled = true

    func play(_ events: [RunEvent]) {
        guard isEnabled else { return }
        for event in events {
            switch event.kind {
            case .tierChanged:
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            case .upgradeOffered:
                UISelectionFeedbackGenerator().selectionChanged()
            case .extractionOpened, .extractionCompleted:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .entityDestroyed where event.message.contains(EntityKind.cameraPole.rawValue):
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            default:
                break
            }
        }
    }
}
