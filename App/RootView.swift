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
    @State private var campaignStore = CampaignProgressStore()
    @State private var masteryStore = MasteryProgressStore()
    /// Value snapshots so SwiftUI invalidates when store class internals mutate.
    @State private var campaignProgress = CampaignProgress.initial
    @State private var masteryProgress = MasteryProgress.initial

    private var isPlayingSurface: Bool {
        !scene.isRunPaused && !scene.runCompleted && scene.pendingUpgradeChoices.isEmpty
    }

    private var nextDistrict: DistrictID {
        campaignProgress.resolveSelection(DistrictID(rawValue: nextDistrictRaw))
    }

    private var todaysDaily: ChallengeInstance {
        ChallengeResolver.daily()
    }

    private var thisWeekly: ChallengeInstance {
        ChallengeResolver.weekly()
    }

    var body: some View {
        // Snapshot once per render so summary labels and start closures share the same contracts
        // across a UTC day/week boundary (do not re-call Date() in each button action).
        let dailyChallenge = todaysDaily
        let weeklyChallenge = thisWeekly
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

                // Utility / interactable activation — opposite thumb from the stick.
                Button {
                    scene.requestUtilityActivation()
                } label: {
                    Label("Activate nearby utility", systemImage: "bolt.horizontal.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(GameChromeIconButtonStyle())
                .accessibilityIdentifier("activate-utility")
                .padding(.horizontal, VisualDesignTokens.space10)
                .padding(.bottom, VisualDesignTokens.space16)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: controlsOnLeft ? .bottomTrailing : .bottomLeading
                )
                .zIndex(2)
            }

            // Presentation-only redaction vignette (mastery cosmetic). Never blocks hits.
            if scene.unlockPresentation.showsRedactionVignette {
                UnlockRedactionVignette()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .accessibilityIdentifier("unlock-vignette-redaction")
                    .zIndex(1)
            }

            if isPlayingSurface {
                // Compact top strip — must not bury the playfield (Hallmark HUD C1).
                HUDView(scene: scene)
                    .padding(.horizontal, VisualDesignTokens.space10)
                    .padding(.top, VisualDesignTokens.space8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .allowsHitTesting(false)
                    .accessibilityIdentifier("game-hud")
                    .zIndex(2)
            }

            if isPlayingSurface {
                // Pin chrome to top-trailing without expanding the HStack into a full-screen
                // hit target (that broke device XCUITest activation of pause/settings).
                VStack {
                    HStack(spacing: 6) {
                        Button {
                            controlsOnLeft.toggle()
                            scene.clearMovement()
                        } label: {
                            Label(
                                controlsOnLeft ? "Move stick to right" : "Move stick to left",
                                systemImage: "hand.point.\(controlsOnLeft ? "right" : "left").fill"
                            )
                            .labelStyle(.iconOnly)
                        }
                        .buttonStyle(GameChromeIconButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("toggle-handedness")
                        Button {
                            userPaused = true
                            scene.clearMovement()
                            syncPauseState()
                        } label: {
                            Label("Pause run", systemImage: "pause.fill")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(GameChromeIconButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("pause-run")
                        Button {
                            showingSettings = true
                            scene.clearMovement()
                        } label: {
                            Label("Open accessibility settings", systemImage: "gearshape.fill")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(GameChromeIconButtonStyle())
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("open-settings")
                    }
                    .padding(.horizontal, VisualDesignTokens.space10)
                    .padding(.top, VisualDesignTokens.space8)
                    // Group container: children must keep their own identifiers (pause-run, etc.).
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("control-chrome")
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(3)
            }

            if scene.isRunPaused && !scene.runCompleted && !showingSettings {
                // XCUITest launches can report a non-active scenePhase briefly; still show
                // RESUME when the operator tapped pause so chrome tests stay deterministic.
                let uiTesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
                PauseOverlay(
                    canResumeManually: userPaused && (scenePhase == .active || uiTesting),
                    runSeed: scene.runSeed,
                    loadout: scene.activeLoadout,
                    suspicion: scene.suspicion,
                    suspicionTier: scene.suspicionTier,
                    reducedMotion: reducedMotion,
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
                    campaign: campaignProgress,
                    mastery: masteryProgress,
                    daily: dailyChallenge,
                    weekly: weeklyChallenge,
                    selectedDistrict: $nextDistrictRaw,
                    startNextRun: {
                        userPaused = false
                        let choice = campaignProgress.resolveSelection(DistrictID(rawValue: nextDistrictRaw))
                        nextDistrictRaw = choice.rawValue
                        scene.selectDistrict(choice)
                        scene.startNextRun()
                        syncPauseState()
                    },
                    startDaily: {
                        userPaused = false
                        scene.startChallengeRun(dailyChallenge)
                        nextDistrictRaw = dailyChallenge.districtId.rawValue
                        syncPauseState()
                    },
                    startWeekly: {
                        userPaused = false
                        scene.startChallengeRun(weeklyChallenge)
                        nextDistrictRaw = weeklyChallenge.districtId.rawValue
                        syncPauseState()
                    }
                )
            } else if !scene.pendingUpgradeChoices.isEmpty {
                // A sibling layer receives all modal touches before the
                // SpriteKit surface. Its dimmer also prevents taps outside a
                // card from reaching the active game beneath it.
                VisualDesignTokens.paperDimmer
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { }
                    .accessibilityHidden(true)
                UpgradeDraftOverlay(
                    choices: scene.pendingUpgradeChoices,
                    queuedOffers: scene.queuedUpgradeOffers,
                    select: scene.selectUpgrade
                )
                    .zIndex(1)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("root-view")
        .onChange(of: scenePhase) { _, _ in syncPauseState() }
        .onChange(of: showingSettings) { _, _ in syncPauseState() }
        .onAppear {
            applyAccessibilitySettings()
            campaignProgress = campaignStore.progress
            masteryProgress = masteryStore.progress
            // Clamp persisted picker choice to currently unlocked districts, then
            // apply it to the live scene so a relaunch does not silently restart
            // Wichita after the player already unlocked / selected a later city.
            let choice = campaignProgress.resolveSelection(DistrictID(rawValue: nextDistrictRaw))
            nextDistrictRaw = choice.rawValue
            scene.bootstrapCampaignDistrictIfNeeded(choice)
            scene.applyUnlockPresentation(from: masteryProgress)
            syncPauseState()
        }
        .onChange(of: controlsOnLeft) { _, _ in applyAccessibilitySettings() }
        .onChange(of: stickScale) { _, _ in applyAccessibilitySettings() }
        .onChange(of: stickOpacity) { _, _ in applyAccessibilitySettings() }
        .onChange(of: reducedMotion) { _, _ in applyAccessibilitySettings() }
        .onChange(of: reducedFlash) { _, _ in applyAccessibilitySettings() }
        .onChange(of: hapticsEnabled) { _, _ in applyAccessibilitySettings() }
        .onChange(of: scene.completedRunReceipt) { _, receipt in
            guard let receipt else { return }
            receiptStore.save(receipt)
            let mastery = masteryStore.recordReceipt(receipt.core)
            masteryProgress = mastery
            scene.applyUnlockPresentation(from: mastery)
            let updated = campaignStore.applyRunOutcome(
                district: receipt.core.district,
                extractionCompleted: receipt.core.extractionCompleted
            )
            campaignProgress = updated
            // After a win on an unlocked frontier city, prefer the newly unlocked next
            // district. Challenge extractions in locked cities do not advance unlocks
            // (see CampaignProgress.recordRunOutcome) and clamp back to playable picks.
            if receipt.core.extractionCompleted {
                let preferred = updated.nextDistrict(after: receipt.core.district)
                nextDistrictRaw = updated.resolveSelection(preferred).rawValue
            } else {
                nextDistrictRaw = updated.resolveSelection(receipt.core.district).rawValue
            }
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
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackground(VisualDesignTokens.paper)
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

// Hallmark · component: settings-panel · genre: atmospheric · theme: terminal-grid
// Replaces system Form so settings match pause/upgrade chrome (no iOS grouped white).
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
            ScrollView {
                VStack(alignment: .leading, spacing: VisualDesignTokens.space16) {
                    Text("FIELD CONFIG")
                        .font(VisualDesignTokens.display(.title3))
                        .foregroundStyle(VisualDesignTokens.ink)
                    Text("Thumb layout, stick feel, and reduced-stimulus options. Changes apply immediately.")
                        .font(VisualDesignTokens.body(.caption))
                        .foregroundStyle(VisualDesignTokens.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    settingsSection(title: "CONTROLS") {
                        settingsToggle(
                            title: "Left-handed movement",
                            subtitle: "Stick on the left half of the field",
                            isOn: $controlsOnLeft
                        )
                        settingsSlider(
                            title: "Stick size",
                            valueLabel: "\(Int(stickScale * 100))%",
                            value: $stickScale,
                            range: 0.75...1.4
                        )
                        settingsSlider(
                            title: "Stick opacity",
                            valueLabel: "\(Int(stickOpacity * 100))%",
                            value: $stickOpacity,
                            range: 0.2...1
                        )
                    }

                    settingsSection(title: "ACCESSIBILITY") {
                        settingsToggle(
                            title: "Reduce camera motion",
                            subtitle: "Snaps presentation; minimal secondary motion",
                            isOn: $reducedMotion
                        )
                        settingsToggle(
                            title: "Reduce flash",
                            subtitle: "Calmer flood and cone intensity",
                            isOn: $reducedFlash
                        )
                        settingsToggle(
                            title: "Haptic feedback",
                            subtitle: "Pulses on combat and tier events",
                            isOn: $hapticsEnabled
                        )
                    }
                }
                .padding(VisualDesignTokens.space16)
            }
            .background(VisualDesignTokens.paper.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(VisualDesignTokens.bodyBold(.subheadline))
                        .foregroundStyle(VisualDesignTokens.accent)
                        .accessibilityAddTraits(.isHeader)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("DONE") { dismiss() }
                        .font(VisualDesignTokens.bodyBold(.caption))
                        .foregroundStyle(VisualDesignTokens.accent)
                        .accessibilityIdentifier("settings-done")
                }
            }
            .toolbarBackground(VisualDesignTokens.paperElevated, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .accessibilityIdentifier("settings-panel")
    }

    @ViewBuilder
    private func settingsSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space10) {
            Text(title)
                .font(VisualDesignTokens.bodyBold(.caption2))
                .foregroundStyle(VisualDesignTokens.accentSoft)
                .tracking(1.2)
            VStack(spacing: 0) {
                content()
            }
            .background(
                VisualDesignTokens.paperElevated,
                in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
                    .strokeBorder(VisualDesignTokens.ruleSoft, lineWidth: 1)
            )
        }
    }

    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: VisualDesignTokens.space2) {
                Text(title)
                    .font(VisualDesignTokens.bodyBold(.caption))
                    .foregroundStyle(VisualDesignTokens.ink)
                Text(subtitle)
                    .font(VisualDesignTokens.body(.caption2))
                    .foregroundStyle(VisualDesignTokens.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(VisualDesignTokens.accent)
        .padding(VisualDesignTokens.space10)
        .overlay(alignment: .bottom) {
            VisualDesignTokens.ruleSoft.frame(height: 1)
        }
    }

    private func settingsSlider(
        title: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
            HStack {
                Text(title)
                    .font(VisualDesignTokens.bodyBold(.caption))
                    .foregroundStyle(VisualDesignTokens.ink)
                Spacer()
                Text(valueLabel)
                    .font(VisualDesignTokens.metric())
                    .foregroundStyle(VisualDesignTokens.accent)
                    .monospacedDigit()
            }
            Slider(value: value, in: range, step: 0.05)
                .tint(VisualDesignTokens.accent)
        }
        .padding(VisualDesignTokens.space10)
        .overlay(alignment: .bottom) {
            VisualDesignTokens.ruleSoft.frame(height: 1)
        }
    }
}

private struct UpgradeDraftOverlay: View {
    let choices: [UpgradeChoice]
    /// Extra drafts still queued after this pick (multi-kill while modal open).
    let queuedOffers: Int
    let select: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space14) {
            // Lead with the job, not a decorative eyebrow chapter label.
            HStack(alignment: .firstTextBaseline, spacing: VisualDesignTokens.space10) {
                Text("Camera neutralized")
                    .font(VisualDesignTokens.display(.headline))
                    .foregroundStyle(VisualDesignTokens.ink)
                if queuedOffers > 0 {
                    Text("+\(queuedOffers) QUEUED")
                        .font(VisualDesignTokens.bodyBold(.caption2))
                        .foregroundStyle(VisualDesignTokens.paper)
                        .padding(.horizontal, VisualDesignTokens.space6)
                        .padding(.vertical, 3)
                        .background(
                            VisualDesignTokens.accent.opacity(0.9),
                            in: Capsule()
                        )
                        .accessibilityIdentifier("upgrade-queue-cue")
                        .accessibilityLabel("\(queuedOffers) more upgrade drafts queued")
                }
            }
            Text(
                queuedOffers > 0
                    ? "Select one countermeasure. \(queuedOffers) more draft\(queuedOffers == 1 ? "" : "s") waiting after this pick."
                    : "Select one countermeasure upgrade to resume the run."
            )
                .font(VisualDesignTokens.body(.caption))
                .foregroundStyle(VisualDesignTokens.inkMuted)

            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    select(index)
                } label: {
                    VStack(alignment: .leading, spacing: VisualDesignTokens.space4) {
                        Text(title(for: choice))
                            .font(VisualDesignTokens.bodyBold(.subheadline))
                            .foregroundStyle(VisualDesignTokens.ink)
                            .lineLimit(1)
                        Text(detail(for: choice))
                            .font(VisualDesignTokens.body(.caption))
                            .foregroundStyle(VisualDesignTokens.inkMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(VisualDesignTokens.space10)
                    .background(
                        VisualDesignTokens.paperElevated,
                        in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                            .strokeBorder(VisualDesignTokens.rule, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Select \(title(for: choice))")
                .accessibilityIdentifier("upgrade-choice-\(index)")
            }
        }
        .padding(VisualDesignTokens.space24)
        .frame(maxWidth: 360)
        .background(
            VisualDesignTokens.paper.opacity(0.94),
            in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
                .strokeBorder(VisualDesignTokens.accentDim, lineWidth: 1)
        )
        .padding(VisualDesignTokens.space16)
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

/// Soft edge vignette for the redaction cosmetic unlock (presentation only).
private struct UnlockRedactionVignette: View {
    var body: some View {
        RadialGradient(
            colors: [
                .clear,
                VisualDesignTokens.paperDimmer.opacity(0.15),
                VisualDesignTokens.paperDimmer.opacity(0.55)
            ],
            center: .center,
            startRadius: 80,
            endRadius: 420
        )
        .ignoresSafeArea()
    }
}

private struct HUDView: View {
    @ObservedObject var scene: GameScene

    var body: some View {
        // Hallmark HUD C1: one slim strip. Seed / loadout names / cosmetics → pause/summary only.
        VStack(alignment: .leading, spacing: VisualDesignTokens.space4) {
            HStack(spacing: VisualDesignTokens.space8) {
                Text(scene.districtName.uppercased())
                    .font(VisualDesignTokens.bodyBold(.caption2))
                    .foregroundStyle(VisualDesignTokens.ink)
                    .lineLimit(1)
                Text("·")
                    .foregroundStyle(VisualDesignTokens.inkFaint)
                Text(scene.districtTitle)
                    .font(VisualDesignTokens.body(.caption2))
                    .foregroundStyle(VisualDesignTokens.inkMuted)
                    .lineLimit(1)
                if scene.unlockPresentation.showsLotGhostTrail {
                    Circle()
                        .fill(VisualDesignTokens.accent.opacity(0.55))
                        .frame(width: 5, height: 5)
                        .accessibilityIdentifier("unlock-trail-lot-ghost")
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("District \(scene.districtName), \(scene.districtTitle)")

            Text(scene.objectiveText)
                .font(VisualDesignTokens.bodyBold(.caption2))
                .foregroundStyle(VisualDesignTokens.accent)
                .lineLimit(1)

            HStack(alignment: .center, spacing: VisualDesignTokens.space10) {
                CompactSuspicionMeter(value: scene.suspicion, tier: scene.suspicionTier)

                Label(
                    "\(Int(max(0, scene.playerHealth.rounded())))",
                    systemImage: "heart.fill"
                )
                .font(VisualDesignTokens.metric())
                .foregroundStyle(scene.playerHealth > 30 ? VisualDesignTokens.ink : VisualDesignTokens.alarm)
                .accessibilityLabel("Player integrity \(Int(max(0, scene.playerHealth.rounded())))")

                Label("\(scene.dataShards)", systemImage: "square.stack.3d.up.fill")
                    .font(VisualDesignTokens.metric())
                    .foregroundStyle(VisualDesignTokens.inkMuted)
                    .accessibilityLabel("Data shards \(scene.dataShards)")

                Label(
                    "\(scene.activeLoadout.count)/\(CombatLimits.maximumActiveWeapons)",
                    systemImage: "shield.lefthalf.filled"
                )
                .font(VisualDesignTokens.metric())
                .foregroundStyle(VisualDesignTokens.inkMuted)
                .accessibilityLabel("Loadout \(scene.activeLoadout.joined(separator: ", "))")

                if let bossHealth = scene.bossHealth {
                    Label(
                        "\(Int(max(0, bossHealth)))",
                        systemImage: "person.crop.circle.badge.exclamationmark"
                    )
                    .font(VisualDesignTokens.metric())
                    .foregroundStyle(VisualDesignTokens.warning)
                    .lineLimit(1)
                    .accessibilityLabel("\(scene.bossName) \(Int(max(0, bossHealth)))")
                }
            }
        }
        .padding(.horizontal, VisualDesignTokens.space10)
        .padding(.vertical, VisualDesignTokens.space6)
        .frame(maxWidth: 420, alignment: .leading)
        .background(
            VisualDesignTokens.paper.opacity(0.72),
            in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                .strokeBorder(VisualDesignTokens.ruleSoft, lineWidth: 1)
        )
    }
}

/// Slim suspicion row for live play (Hallmark HUD M1). Full tier copy stays a11y-only.
private struct CompactSuspicionMeter: View {
    let value: Double
    let tier: Int

    private var clampedValue: Double { min(100, max(0, value)) }
    private var clampedTier: Int { min(5, max(0, tier)) }

    var body: some View {
        HStack(spacing: VisualDesignTokens.space6) {
            Text("S\(clampedTier)")
                .font(VisualDesignTokens.metric())
                .foregroundStyle(VisualDesignTokens.suspicionFill(tier: clampedTier))
                .monospacedDigit()
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(VisualDesignTokens.ruleSoft)
                    Capsule()
                        .fill(VisualDesignTokens.suspicionFill(tier: clampedTier))
                        .frame(width: max(3, proxy.size.width * clampedValue / 100))
                }
            }
            .frame(width: 72, height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Suspicion tier \(clampedTier) of 5")
        .accessibilityValue("\(Int(clampedValue)) percent")
    }
}

private struct RunSummaryOverlay: View {
    let receipt: DeviceRunReceipt?
    let playerDefeated: Bool
    let runSeed: UInt64
    let campaign: CampaignProgress
    let mastery: MasteryProgress
    let daily: ChallengeInstance
    let weekly: ChallengeInstance
    @Binding var selectedDistrict: String
    let startNextRun: () -> Void
    let startDaily: () -> Void
    let startWeekly: () -> Void

    private var unlocked: [DistrictDefinition] { campaign.unlockedDistricts }

    var body: some View {
        ScrollView {
            VStack(spacing: VisualDesignTokens.space10) {
                Image(systemName: playerDefeated ? "eye.trianglebadge.exclamationmark.fill" : "eye.slash.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(playerDefeated ? VisualDesignTokens.alarm : VisualDesignTokens.accent)
                Text(playerDefeated ? "GRID REACQUIRED" : "BLIND SPOT REACHED")
                    .font(VisualDesignTokens.display(.headline))
                    .foregroundStyle(VisualDesignTokens.ink)
                Text(playerDefeated ? "Contract security closed the loop." : "The district has lost your trail.")
                    .font(VisualDesignTokens.body(.caption))
                    .foregroundStyle(VisualDesignTokens.inkMuted)
                if let challenge = receipt?.core.challenge {
                    Text("\(challenge.kind.uppercased()) · \(challenge.contractDisplayName)")
                        .font(VisualDesignTokens.bodyBold(.caption))
                        .foregroundStyle(VisualDesignTokens.accent)
                        .accessibilityIdentifier("challenge-summary-label")
                }
                if let story = receipt?.core.storySummary, !story.isEmpty {
                    Text(story)
                        .font(VisualDesignTokens.body(.caption2))
                        .foregroundStyle(VisualDesignTokens.accentSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityLabel("Run story \(story)")
                }
                Text(String(format: "SEED 0x%08X", receipt?.core.seed ?? runSeed))
                    .font(VisualDesignTokens.body(.caption2))
                    .foregroundStyle(VisualDesignTokens.inkFaint)
                    .accessibilityLabel("Run seed \(receipt?.core.seed ?? runSeed)")
                Text("CAMPAIGN UNLOCK \(campaign.highestUnlockedLevel)/\(campaign.maxCampaignLevel)")
                    .font(VisualDesignTokens.bodyBold(.caption2))
                    .foregroundStyle(VisualDesignTokens.accentSoft)
                    .accessibilityLabel(
                        "Campaign unlock level \(campaign.highestUnlockedLevel) of \(campaign.maxCampaignLevel)"
                    )
                Text(
                    "MASTERY \(mastery.totalExtractions)/\(mastery.totalRuns) · STREAK \(mastery.currentDailyStreak) (best \(mastery.dailyBestStreak)) · UNLOCKS \(mastery.unlockedItemIds.count)"
                )
                .font(VisualDesignTokens.bodyBold(.caption2))
                .foregroundStyle(VisualDesignTokens.accentSoft)
                .accessibilityIdentifier("mastery-summary")
                .accessibilityLabel(
                    "Mastery \(mastery.totalExtractions) extractions of \(mastery.totalRuns) runs, daily streak \(mastery.currentDailyStreak), \(mastery.unlockedItemIds.count) unlocks"
                )
                if !mastery.lastGrantedUnlockIds.isEmpty {
                    Text("NEW UNLOCK · \(mastery.lastGrantedUnlockIds.joined(separator: ", "))")
                        .font(VisualDesignTokens.bodyBold(.caption2))
                        .foregroundStyle(VisualDesignTokens.accent)
                        .accessibilityIdentifier("unlock-grant-banner")
                }
                if let receipt {
                    Divider().overlay(VisualDesignTokens.ruleSoft)
                    HStack(spacing: VisualDesignTokens.space14) {
                        SummaryMetric(label: "TIME", value: String(format: "%.0fs", receipt.core.elapsedSeconds))
                        SummaryMetric(label: "LPR", value: "\(receipt.core.deathsByArchetype[.cameraPole, default: 0])")
                        SummaryMetric(label: "DEALT", value: String(format: "%.0f", receipt.core.damageDealt))
                        SummaryMetric(label: "TAKEN", value: String(format: "%.0f", receipt.core.damageTaken))
                        SummaryMetric(label: "P50", value: String(format: "%.1fms", receipt.frameTimeSummary.p50 * 1_000))
                        SummaryMetric(label: "P95", value: String(format: "%.1fms", receipt.frameTimeSummary.p95 * 1_000))
                        SummaryMetric(label: "MAX", value: String(format: "%.1fms", receipt.frameTimeSummary.maximum * 1_000))
                    }
                    Text("Receipt saved locally")
                        .font(VisualDesignTokens.body(.caption2))
                        .foregroundStyle(VisualDesignTokens.accentSoft)
                    Button("COPY RECEIPT JSON") {
                        guard let data = try? JSONEncoder().encode(receipt),
                              let text = String(data: data, encoding: .utf8) else { return }
                        UIPasteboard.general.string = text
                    }
                    .buttonStyle(GameChromePrimaryButtonStyle())
                    .accessibilityIdentifier("copy-receipt-json")
                    .accessibilityLabel("Copy receipt JSON")
                }
                Divider().overlay(VisualDesignTokens.ruleSoft)
                VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
                    Text("CHALLENGES")
                        .font(VisualDesignTokens.bodyBold(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkMuted)
                    Text("Daily · \(daily.contractDisplayName) · \(daily.districtId.cityName)")
                        .font(VisualDesignTokens.body(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkFaint)
                        .accessibilityIdentifier("daily-challenge-detail")
                    Button("START DAILY CHALLENGE", action: startDaily)
                        .buttonStyle(GameChromePrimaryButtonStyle())
                        .tint(VisualDesignTokens.accent)
                        .accessibilityIdentifier("start-daily-challenge")
                    Text("Weekly · \(weekly.contractDisplayName) · \(weekly.districtId.cityName)")
                        .font(VisualDesignTokens.body(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkFaint)
                        .accessibilityIdentifier("weekly-challenge-detail")
                    Button("START WEEKLY CHALLENGE", action: startWeekly)
                        .buttonStyle(GameChromePrimaryButtonStyle())
                        .accessibilityIdentifier("start-weekly-challenge")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Divider().overlay(VisualDesignTokens.ruleSoft)
                VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
                    Text("NEXT DISTRICT")
                        .font(VisualDesignTokens.bodyBold(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkMuted)
                    ForEach(unlocked, id: \.id) { district in
                        let cleared = campaign.completedDistricts.contains(district.id)
                        let isSelected = selectedDistrict == district.id.rawValue
                        Button {
                            selectedDistrict = district.id.rawValue
                        } label: {
                            HStack(spacing: VisualDesignTokens.space8) {
                                Text("\(district.level). \(district.cityName)\(cleared ? " ✓" : "")")
                                    .font(VisualDesignTokens.bodyBold(.caption))
                                    .foregroundStyle(VisualDesignTokens.ink)
                                Text(district.title)
                                    .font(VisualDesignTokens.body(.caption2))
                                    .foregroundStyle(VisualDesignTokens.inkMuted)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(VisualDesignTokens.accent)
                                }
                            }
                            .padding(.horizontal, VisualDesignTokens.space10)
                            .padding(.vertical, VisualDesignTokens.space8)
                            .background(
                                (isSelected ? VisualDesignTokens.paperElevated : VisualDesignTokens.paper)
                                    .opacity(0.95),
                                in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                                    .strokeBorder(
                                        isSelected ? VisualDesignTokens.accentDim : VisualDesignTokens.ruleSoft,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(
                            "\(district.cityName), \(district.title)\(cleared ? ", cleared" : "")\(isSelected ? ", selected" : "")"
                        )
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .accessibilityIdentifier("next-district-\(district.id.rawValue)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("next-district-picker")
                .accessibilityLabel("Next district")
                if unlocked.count < campaign.maxCampaignLevel {
                    Text("Clear a Blind Spot extraction to unlock the next city.")
                        .font(VisualDesignTokens.body(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkFaint)
                        .multilineTextAlignment(.center)
                }
                Button("START NEXT RUN", action: startNextRun)
                    .buttonStyle(GameChromePrimaryButtonStyle())
                    .tint(playerDefeated ? VisualDesignTokens.alarmSoft : VisualDesignTokens.accentSoft)
                    .accessibilityIdentifier("start-next-run")
            }
            .padding(VisualDesignTokens.space24)
        }
        .frame(maxHeight: 340)
        .background(
            VisualDesignTokens.paper.opacity(0.92),
            in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
                .strokeBorder(VisualDesignTokens.rule, lineWidth: 1)
        )
        .foregroundStyle(VisualDesignTokens.ink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("run-summary")
    }
}

private struct SummaryMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: VisualDesignTokens.space2) {
            Text(value).font(VisualDesignTokens.metric()).foregroundStyle(VisualDesignTokens.ink)
            Text(label).font(VisualDesignTokens.body(.caption2)).foregroundStyle(VisualDesignTokens.inkFaint)
        }
    }
}

private struct PauseOverlay: View {
    let canResumeManually: Bool
    let runSeed: UInt64
    let loadout: [String]
    let suspicion: Double
    let suspicionTier: Int
    var reducedMotion: Bool = false
    let resume: () -> Void

    var body: some View {
        VStack(spacing: VisualDesignTokens.space10) {
            Image(systemName: "eye.slash.fill")
                .font(.largeTitle)
                .foregroundStyle(VisualDesignTokens.accent)
            Text("SIGNAL SUSPENDED")
                .font(VisualDesignTokens.display(.headline))
                .foregroundStyle(VisualDesignTokens.ink)
            Text(
                canResumeManually
                    ? "Simulation is paused. Resume when ready."
                    : "The run will resume when the app becomes active."
            )
            .font(VisualDesignTokens.body(.caption))
            .foregroundStyle(VisualDesignTokens.inkMuted)
            .multilineTextAlignment(.center)
            // Expanded native meter on pause only — live HUD stays compact (Hallmark HUD M1).
            SuspicionMeter(value: suspicion, tier: suspicionTier, reducedMotion: reducedMotion)
                .accessibilityIdentifier("pause-suspicion-meter")
            // Seed + loadout live on pause so live HUD stays thin (Hallmark HUD m1/m2).
            Text(String(format: "SEED 0x%08X", runSeed))
                .font(VisualDesignTokens.body(.caption2))
                .foregroundStyle(VisualDesignTokens.inkFaint)
                .accessibilityLabel("Run seed \(runSeed)")
            if !loadout.isEmpty {
                Text(loadout.joined(separator: " · "))
                    .font(VisualDesignTokens.body(.caption2))
                    .foregroundStyle(VisualDesignTokens.accentSoft)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            if canResumeManually {
                Button("RESUME RUN", action: resume)
                    .buttonStyle(GameChromePrimaryButtonStyle())
                    .accessibilityIdentifier("resume-run")
            }
        }
        .padding(VisualDesignTokens.space24)
        .background(
            VisualDesignTokens.paper.opacity(0.9),
            in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: VisualDesignTokens.radiusPanel)
                .strokeBorder(VisualDesignTokens.rule, lineWidth: 1)
        )
        .foregroundStyle(VisualDesignTokens.ink)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("pause-overlay")
    }
}

// MARK: - Game chrome button styles (terminal-grid; no stock iOS prominent)

private struct GameChromeIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(VisualDesignTokens.ink)
            .frame(width: 40, height: 40)
            .background(
                VisualDesignTokens.paperElevated.opacity(configuration.isPressed ? 0.75 : 0.94),
                in: RoundedRectangle(cornerRadius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(VisualDesignTokens.rule, lineWidth: 1)
            )
    }
}

private struct GameChromePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VisualDesignTokens.bodyBold(.caption))
            .foregroundStyle(VisualDesignTokens.paper)
            .padding(.horizontal, VisualDesignTokens.space16)
            .padding(.vertical, VisualDesignTokens.space10)
            .background(
                VisualDesignTokens.accent.opacity(configuration.isPressed ? 0.75 : 0.95),
                in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                    .strokeBorder(VisualDesignTokens.accentSoft, lineWidth: 1)
            )
    }
}
