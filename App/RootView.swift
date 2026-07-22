import SwiftUI
import SpriteKit
import SurveillanceCore

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene = GameScene(size: CGSize(width: 844, height: 390))

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .overlay(alignment: .topLeading) {
                HUDView(scene: scene).padding()
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    scene.toggleControlSide()
                } label: {
                    Label(
                        scene.controlsOnLeft ? "Move stick to right" : "Move stick to left",
                        systemImage: "hand.point.\(scene.controlsOnLeft ? "right" : "left").fill"
                    )
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.72))
                .padding()
                .accessibilityLabel(scene.controlsOnLeft ? "Use right-handed movement controls" : "Use left-handed movement controls")
            }
            .overlay {
                if scene.isRunPaused {
                    PauseOverlay()
                } else if scene.runCompleted {
                    ExtractionCompleteOverlay()
                } else if !scene.pendingUpgradeChoices.isEmpty {
                    UpgradeDraftOverlay(choices: scene.pendingUpgradeChoices, select: scene.selectUpgrade)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                scene.setRunPaused(phase != .active)
            }
    }
}

private struct UpgradeDraftOverlay: View {
    let choices: [UpgradeChoice]
    let select: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("COUNTERMEASURE DRAFT")
                .font(.headline.monospaced())
            Text("Camera neutralized. Select one upgrade to resume the run.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.78))

            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    select(index)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title(for: choice))
                            .font(.subheadline.bold().monospaced())
                        Text(detail(for: choice))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan.opacity(0.78))
                .accessibilityLabel("Select \(title(for: choice))")
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .padding()
        .accessibilityElement(children: .contain)
    }

    private func title(for choice: UpgradeChoice) -> String {
        switch choice {
        case .rapidCountermeasure: "Rapid countermeasure"
        case .reinforcedSignal: "Reinforced signal"
        case .lowProfileRouting: "Low-profile routing"
        case .redactionOrdinance: "Redaction ordinance"
        case .identityTransponder: "Identity transponder"
        case .foiaSwarm: "FOIA swarm"
        }
    }

    private func detail(for choice: UpgradeChoice) -> String {
        switch choice {
        case .rapidCountermeasure: "Fire your primary countermeasure more often."
        case .reinforcedSignal: "Increase primary countermeasure damage."
        case .lowProfileRouting: "Reduce current suspicion by 10 points."
        case .redactionOrdinance: "Launch black-bar ordinances that disable camera sensors."
        case .identityTransponder: "Spoof camera identity and sharply reduce its Suspicion pressure."
        case .foiaSwarm: "Overload threats with paperwork that slows and damages them over time."
        }
    }
}

private struct HUDView: View {
    @ObservedObject var scene: GameScene

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SURVEILLANCE SURVIVOR")
                .font(.caption.bold().monospaced())
                .foregroundStyle(.white.opacity(0.88))
            SuspicionMeter(value: scene.suspicion, tier: scene.suspicionTier)
            Text(scene.objectiveText)
                .font(.caption.bold().monospaced())
                .foregroundStyle(.cyan)
            if let bossHealth = scene.bossHealth {
                Label("SHIFT MANAGER \(Int(max(0, bossHealth)))", systemImage: "person.crop.circle.badge.exclamationmark")
                    .font(.caption.bold().monospaced())
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct ExtractionCompleteOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.slash.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.cyan)
            Text("BLIND SPOT REACHED")
                .font(.headline.monospaced())
            Text("The district has lost your trail.")
                .font(.caption)
        }
        .padding(24)
        .background(.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

private struct PauseOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "eye.slash.fill")
                .font(.largeTitle)
            Text("SIGNAL SUSPENDED")
                .font(.headline.monospaced())
            Text("The run will resume when the app becomes active.")
                .font(.caption)
        }
        .padding(24)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}
