import SwiftUI
import SpriteKit
import SurveillanceCore
import UIKit

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene = GameScene(size: CGSize(width: 844, height: 390))
    @AppStorage("surveillance.controlsOnLeft") private var controlsOnLeft = true
    @AppStorage("surveillance.stickScale") private var stickScale = 1.0
    @AppStorage("surveillance.stickOpacity") private var stickOpacity = 0.7
    @AppStorage("surveillance.reducedMotion") private var reducedMotion = false
    @AppStorage("surveillance.reducedFlash") private var reducedFlash = false
    @AppStorage("surveillance.hapticsEnabled") private var hapticsEnabled = true
    @State private var showingSettings = false
    @State private var receiptStore = RunReceiptStore()

    var body: some View {
        ZStack {
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                // The gameplay surface must not receive a modal draft tap.
                // Keep it separate from the SwiftUI modal so disabling it does
                // not also disable the card buttons.
                .allowsHitTesting(scene.acceptsSceneTouches && !scene.isRunPaused && !scene.runCompleted)

            if !scene.isRunPaused && !scene.runCompleted && scene.pendingUpgradeChoices.isEmpty {
                HUDView(scene: scene)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            if !scene.isRunPaused && !scene.runCompleted && scene.pendingUpgradeChoices.isEmpty {
                HStack(spacing: 8) {
                    Button {
                        controlsOnLeft.toggle()
                    } label: {
                        Label(
                            controlsOnLeft ? "Move stick to right" : "Move stick to left",
                            systemImage: "hand.point.\(controlsOnLeft ? "right" : "left").fill"
                        )
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                    }
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Open accessibility settings", systemImage: "gearshape.fill")
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.72))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }

            if scene.isRunPaused {
                PauseOverlay()
            } else if scene.runCompleted {
                RunSummaryOverlay(receipt: scene.completedRunReceipt, startNextRun: scene.startNextRun)
            } else if !scene.pendingUpgradeChoices.isEmpty {
                // A sibling layer receives all modal touches before the
                // SpriteKit surface. Its dimmer also prevents taps outside a
                // card from reaching the active game beneath it.
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { }
                    .accessibilityHidden(true)
                UpgradeDraftOverlay(choices: scene.pendingUpgradeChoices, select: scene.selectUpgrade)
                    .zIndex(1)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            scene.setRunPaused(phase != .active)
        }
        .onAppear(perform: applyAccessibilitySettings)
        .onChange(of: controlsOnLeft) { _, _ in applyAccessibilitySettings() }
        .onChange(of: stickScale) { _, _ in applyAccessibilitySettings() }
        .onChange(of: stickOpacity) { _, _ in applyAccessibilitySettings() }
        .onChange(of: reducedMotion) { _, _ in applyAccessibilitySettings() }
        .onChange(of: reducedFlash) { _, _ in applyAccessibilitySettings() }
        .onChange(of: hapticsEnabled) { _, _ in applyAccessibilitySettings() }
        .onChange(of: scene.completedRunReceipt) { _, receipt in
            if let receipt { receiptStore.save(receipt) }
        }
        .sheet(isPresented: $showingSettings) {
            AccessibilitySettingsView(
                controlsOnLeft: $controlsOnLeft,
                stickScale: $stickScale,
                stickOpacity: $stickOpacity,
                reducedMotion: $reducedMotion,
                reducedFlash: $reducedFlash,
                hapticsEnabled: $hapticsEnabled
            )
        }
    }

    private func applyAccessibilitySettings() {
        scene.applyAccessibilitySettings(
            controlsOnLeft: controlsOnLeft,
            stickScale: stickScale,
            stickOpacity: stickOpacity,
            reducedMotion: reducedMotion,
            reducedFlash: reducedFlash,
            hapticsEnabled: hapticsEnabled
        )
    }
}

private struct AccessibilitySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var controlsOnLeft: Bool
    @Binding var stickScale: Double
    @Binding var stickOpacity: Double
    @Binding var reducedMotion: Bool
    @Binding var reducedFlash: Bool
    @Binding var hapticsEnabled: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Controls") {
                    Toggle("Left-handed movement", isOn: $controlsOnLeft)
                    LabeledContent("Stick size") {
                        Text("\(Int(stickScale * 100))%")
                    }
                    Slider(value: $stickScale, in: 0.75...1.4, step: 0.05)
                    LabeledContent("Stick opacity") {
                        Text("\(Int(stickOpacity * 100))%")
                    }
                    Slider(value: $stickOpacity, in: 0.2...1, step: 0.05)
                }
                Section("Accessibility") {
                    Toggle("Reduce camera motion", isOn: $reducedMotion)
                    Toggle("Reduce flash", isOn: $reducedFlash)
                    Toggle("Haptic feedback", isOn: $hapticsEnabled)
                }
            }
            .navigationTitle("Accessibility")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
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
        case .mirrorArray: "Mirror array"
        case .signalFlood: "Signal flood"
        case .precisionDart: "Precision dart"
        case .blackBarMandate: "Black-bar mandate"
        case .ghostPlateCache: "Ghost plate cache"
        case .expeditedDiscovery: "Expedited discovery"
        case .indictmentProtocol: "Indictment protocol"
        case .blackoutField: "Blackout field"
        case .ghostProtocol: "Ghost protocol"
        case .paperStorm: "Paper storm"
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
        case .mirrorArray: "Deploy a reflective array that blinds and damages nearby LPR poles."
        case .signalFlood: "Pulse a high-risk area disruption that disables nearby surveillance and threats."
        case .precisionDart: "Sharpen the Kinetic Countermeasure with faster, harder darts."
        case .blackBarMandate: "Extend Redaction Ordinance sensor denial."
        case .ghostPlateCache: "Extend identity spoofing while further suppressing sensor pressure."
        case .expeditedDiscovery: "Accelerate FOIA processing with stronger slow and damage."
        case .indictmentProtocol: "Evolution: elevate Kinetic Countermeasure into a rapid high-damage build."
        case .blackoutField: "Evolution: transform Redaction Ordinance into a wide, long-lived blackout."
        case .ghostProtocol: "Evolution: turn Identity Transponder into near-total sensor deception."
        case .paperStorm: "Evolution: turn FOIA Swarm into a severe persistent processing storm."
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

private struct RunSummaryOverlay: View {
    let receipt: DeviceRunReceipt?
    let startNextRun: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.slash.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(.cyan)
            Text("BLIND SPOT REACHED")
                .font(.headline.monospaced())
            Text("The district has lost your trail.")
                .font(.caption)
            if let receipt {
                Divider().overlay(.white.opacity(0.25))
                HStack(spacing: 14) {
                    SummaryMetric(label: "TIME", value: String(format: "%.0fs", receipt.core.elapsedSeconds))
                    SummaryMetric(label: "LPR", value: "\(receipt.core.deathsByArchetype[.cameraPole, default: 0])")
                    SummaryMetric(label: "P50", value: String(format: "%.1fms", receipt.frameTimeSummary.p50 * 1_000))
                    SummaryMetric(label: "P95", value: String(format: "%.1fms", receipt.frameTimeSummary.p95 * 1_000))
                    SummaryMetric(label: "MAX", value: String(format: "%.1fms", receipt.frameTimeSummary.maximum * 1_000))
                }
                Text("Receipt saved locally")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.cyan.opacity(0.9))
                Button("COPY RECEIPT JSON") {
                    guard let data = try? JSONEncoder().encode(receipt),
                          let text = String(data: data, encoding: .utf8) else { return }
                    UIPasteboard.general.string = text
                }
                .font(.caption.bold().monospaced())
                .buttonStyle(.bordered)
            }
            Button("START NEXT RUN", action: startNextRun)
                .buttonStyle(.borderedProminent)
                .tint(.cyan.opacity(0.8))
        }
        .padding(24)
        .background(.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}

private struct SummaryMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption.bold().monospaced())
            Text(label).font(.caption2.monospaced()).foregroundStyle(.white.opacity(0.65))
        }
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
