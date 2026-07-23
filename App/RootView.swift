import SwiftUI
import SpriteKit
import SurveillanceCore
import UIKit

struct RootView: View {
    @Environment(\.scenePhase) private var scenePhase
    // The SpriteKit scene publishes gameplay state that drives SwiftUI HUD and
    // modal presentation. StateObject keeps the scene alive for this view's
    // lifetime and invalidates the view when those published values change.
    @StateObject private var scene = GameScene(size: CGSize(width: 844, height: 390))
    @AppStorage("surveillance.controlsOnLeft") private var controlsOnLeft = true
    @AppStorage("surveillance.stickScale") private var stickScale = 1.0
    @AppStorage("surveillance.stickOpacity") private var stickOpacity = 0.7
    @AppStorage("surveillance.reducedMotion") private var reducedMotion = false
    @AppStorage("surveillance.reducedFlash") private var reducedFlash = false
    @AppStorage("surveillance.hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("surveillance.nextDistrict") private var nextDistrictRaw = DistrictID.campaignOpener.rawValue
    @State private var showingSettings = false
    @State private var userPaused = false
    @State private var receiptStore = RunReceiptStore()

    private var isPlayingSurface: Bool {
        !scene.isRunPaused && !scene.runCompleted && scene.pendingUpgradeChoices.isEmpty
    }

    private var nextDistrict: DistrictID {
        DistrictID(rawValue: nextDistrictRaw) ?? .campaignOpener
    }

    var body: some View {
        ZStack {
            // Rendering only. Movement input is owned by MovementStickOverlay so
            // left-half landscape thumbs are not lost to SpriteKit/SwiftUI hit routing.
            SpriteView(scene: scene, options: [.ignoresSiblingOrder])
                .ignoresSafeArea()
                .allowsHitTesting(false)
                // Keep SpriteKit out of the accessibility tree so XCUITests can
                // reach HUD chrome and control buttons without SpriteKit capturing focus.
                .accessibilityHidden(true)
                .accessibilityIdentifier("game-surface")

            if isPlayingSurface {
                MovementStickOverlay(
                    controlsOnLeft: controlsOnLeft,
                    stickScale: stickScale,
                    stickOpacity: stickOpacity,
                    onMove: { scene.setMovement($0) },
                    onEnd: { scene.clearMovement() }
                )
                .zIndex(1)
            }

            if isPlayingSurface {
                HUDView(scene: scene)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("game-hud")
                    .zIndex(2)
            }

            if isPlayingSurface {
                HStack(spacing: 8) {
                    Button {
                        controlsOnLeft.toggle()
                        scene.clearMovement()
                    } label: {
                        Label(
                            controlsOnLeft ? "Move stick to right" : "Move stick to left",
                            systemImage: "hand.point.\(controlsOnLeft ? "right" : "left").fill"
                        )
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("toggle-handedness")
                    Button {
                        userPaused = true
                        scene.clearMovement()
                        syncPauseState()
                    } label: {
                        Label("Pause run", systemImage: "pause.fill")
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("pause-run")
                    Button {
                        showingSettings = true
                        scene.clearMovement()
                    } label: {
                        Label("Open accessibility settings", systemImage: "gearshape.fill")
                            .labelStyle(.iconOnly)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityIdentifier("open-settings")
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.72))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("control-chrome")
                .zIndex(3)
            }

            if scene.isRunPaused && !scene.runCompleted && !showingSettings {
                PauseOverlay(
                    canResumeManually: userPaused && scenePhase == .active,
                    resume: {
                        userPaused = false
                        syncPauseState()
                    }
                )
            } else if scene.runCompleted {
                RunSummaryOverlay(
                    receipt: scene.completedRunReceipt,
                    playerDefeated: scene.playerDefeated,
                    runSeed: scene.runSeed,
                    selectedDistrict: $nextDistrictRaw,
                    startNextRun: {
                        userPaused = false
                        scene.selectDistrict(nextDistrict)
                        scene.startNextRun()
                        syncPauseState()
                    }
                )
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
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("root-view")
        .onChange(of: scenePhase) { _, _ in syncPauseState() }
        .onChange(of: showingSettings) { _, _ in syncPauseState() }
        .onAppear {
            applyAccessibilitySettings()
            syncPauseState()
        }
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

    private func syncPauseState() {
        // Lifecycle, settings, and explicit pause all suspend the fixed-step loop.
        scene.setRunPaused(scenePhase != .active || userPaused || showingSettings)
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
                .accessibilityIdentifier("upgrade-choice-\(index)")
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
        .background(.black.opacity(0.9), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("upgrade-draft")
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
            Text("\(scene.districtName.uppercased()) · \(scene.districtTitle)")
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.62))
                .lineLimit(1)
                .accessibilityLabel("District \(scene.districtName), \(scene.districtTitle)")
            SuspicionMeter(value: scene.suspicion, tier: scene.suspicionTier)
            Label(
                "INTEGRITY \(Int(max(0, scene.playerHealth.rounded())))",
                systemImage: "heart.fill"
            )
            .font(.caption.bold().monospaced())
            .foregroundStyle(scene.playerHealth > 30 ? .white.opacity(0.9) : .red)
            .accessibilityLabel("Player integrity \(Int(max(0, scene.playerHealth.rounded())))")
            HStack(spacing: 10) {
                Label("SHARDS \(scene.dataShards)", systemImage: "square.stack.3d.up.fill")
                    .accessibilityLabel("Data shards \(scene.dataShards)")
                Label("LOADOUT \(scene.activeLoadout.count)/\(CombatLimits.maximumActiveWeapons)", systemImage: "shield.lefthalf.filled")
                    .accessibilityLabel("Loadout \(scene.activeLoadout.joined(separator: ", "))")
            }
            .font(.caption2.bold().monospaced())
            .foregroundStyle(.white.opacity(0.86))
            if !scene.activeLoadout.isEmpty {
                Text(scene.activeLoadout.joined(separator: " · "))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.cyan.opacity(0.9))
                    .lineLimit(2)
                    .accessibilityHidden(true)
            }
            Text(scene.objectiveText)
                .font(.caption.bold().monospaced())
                .foregroundStyle(.cyan)
            Text(String(format: "SEED 0x%08X", scene.runSeed))
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.55))
                .accessibilityLabel("Run seed \(scene.runSeed)")
            if let bossHealth = scene.bossHealth {
                Label("\(scene.bossName.uppercased()) \(Int(max(0, bossHealth)))", systemImage: "person.crop.circle.badge.exclamationmark")
                    .font(.caption.bold().monospaced())
                    .foregroundStyle(.orange)
            }
        }
    }
}

private struct RunSummaryOverlay: View {
    let receipt: DeviceRunReceipt?
    let playerDefeated: Bool
    let runSeed: UInt64
    @Binding var selectedDistrict: String
    let startNextRun: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: playerDefeated ? "eye.trianglebadge.exclamationmark.fill" : "eye.slash.circle.fill")
                .font(.largeTitle)
                .foregroundStyle(playerDefeated ? .red : .cyan)
            Text(playerDefeated ? "GRID REACQUIRED" : "BLIND SPOT REACHED")
                .font(.headline.monospaced())
            Text(playerDefeated ? "Contract security closed the loop." : "The district has lost your trail.")
                .font(.caption)
            Text(String(format: "SEED 0x%08X", receipt?.core.seed ?? runSeed))
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.65))
                .accessibilityLabel("Run seed \(receipt?.core.seed ?? runSeed)")
            if let receipt {
                Divider().overlay(.white.opacity(0.25))
                HStack(spacing: 14) {
                    SummaryMetric(label: "TIME", value: String(format: "%.0fs", receipt.core.elapsedSeconds))
                    SummaryMetric(label: "LPR", value: "\(receipt.core.deathsByArchetype[.cameraPole, default: 0])")
                    SummaryMetric(label: "DEALT", value: String(format: "%.0f", receipt.core.damageDealt))
                    SummaryMetric(label: "TAKEN", value: String(format: "%.0f", receipt.core.damageTaken))
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
            Divider().overlay(.white.opacity(0.25))
            Picker("Next district", selection: $selectedDistrict) {
                ForEach(DistrictCatalog.bundled.districts.sorted { $0.level < $1.level }, id: \.id) { district in
                    Text("\(district.level). \(district.cityName) — \(district.title)")
                        .tag(district.id.rawValue)
                }
            }
            .pickerStyle(.menu)
            .font(.caption.monospaced())
            .tint(.cyan)
            .accessibilityLabel("Next district")
            Button("START NEXT RUN", action: startNextRun)
                .buttonStyle(.borderedProminent)
                .tint((playerDefeated ? Color.red : Color.cyan).opacity(0.8))
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
    let canResumeManually: Bool
    let resume: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "eye.slash.fill")
                .font(.largeTitle)
            Text("SIGNAL SUSPENDED")
                .font(.headline.monospaced())
            Text(
                canResumeManually
                    ? "Simulation is paused. Resume when ready."
                    : "The run will resume when the app becomes active."
            )
            .font(.caption)
            .multilineTextAlignment(.center)
            if canResumeManually {
                Button("RESUME RUN", action: resume)
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan.opacity(0.85))
                    .accessibilityIdentifier("resume-run")
            }
        }
        .padding(24)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 16))
        .foregroundStyle(.white)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause-overlay")
    }
}
