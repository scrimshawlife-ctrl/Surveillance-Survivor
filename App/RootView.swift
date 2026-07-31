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
    @AppStorage("surveillance.audioMuted") private var audioMuted = false
    @AppStorage("surveillance.sfxVolume") private var sfxVolume = 0.85
    @AppStorage("surveillance.musicVolume") private var musicVolume = 0.7
    @AppStorage("surveillance.ambienceVolume") private var ambienceVolume = 0.40
    @AppStorage("surveillance.nextDistrict") private var nextDistrictRaw = DistrictID.campaignOpener.rawValue
    @State private var showingSettings = false
    /// Suppressed under `-UITesting` so existing chrome/extract XCUITests still land
    /// directly on the game surface instead of a launch screen they never tap through.
    @State private var showingTitle = !ProcessInfo.processInfo.arguments.contains("-UITesting")
    /// Splash → menu only when the launch shell is shown (never under `-UITesting`).
    @State private var launchPhase: LaunchPhase = .splash
    @State private var userPaused = false
    /// Drives the damage vignette. There is no healing anywhere in the game, so any
    /// decrease in integrity is a hit and nothing else.
    @State private var damageFlash = 0.0
    @State private var lastObservedHealth = BossCatalog.bundled.playerHealth
    @State private var receiptStore = RunReceiptStore()
    @State private var campaignStore = CampaignProgressStore()
    @State private var masteryStore = MasteryProgressStore()
    /// Value snapshots so SwiftUI invalidates when store class internals mutate.
    @State private var campaignProgress = CampaignProgress.initial
    @State private var masteryProgress = MasteryProgress.initial

    /// One value covering every setting that feeds `applyAccessibilitySettings`, so a
    /// single observer replaces ten identical ones. The long modifier chain was what
    /// pushed `body` past the type-checker's budget.
    private var accessibilitySignature: String {
        [
            String(controlsOnLeft), String(stickScale), String(stickOpacity),
            String(reducedMotion), String(reducedFlash), String(hapticsEnabled),
            String(audioMuted), String(sfxVolume), String(musicVolume), String(ambienceVolume)
        ].joined(separator: "|")
    }

    /// Extracted from `body` to keep that expression inside the type-checker's budget.
    @ViewBuilder private var damageVignetteLayer: some View {
        if damageFlash > 0 {
            DamageVignette(intensity: damageFlash, reducedFlash: reducedFlash)
                .zIndex(1)
        }
    }

    private var isPlayingSurface: Bool {
        !showingTitle && !scene.isRunPaused && !scene.runCompleted && scene.pendingUpgradeChoices.isEmpty
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
                .accessibilityLabel("Activate nearby utility")
                .accessibilityHint("Activates an available district interactable within reach")
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

            damageVignetteLayer

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
                        .accessibilityLabel(controlsOnLeft ? "Move movement control to right" : "Move movement control to left")
                        .accessibilityHint("Changes which side of the screen owns the movement control")
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
                        .accessibilityLabel("Pause run")
                        .accessibilityHint("Pauses simulation and opens the run status panel")
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
                        .accessibilityLabel("Open settings")
                        .accessibilityHint("Pauses the run while settings are open")
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

            if showingTitle {
                LaunchShellOverlay(
                    phase: $launchPhase,
                    campaign: campaignProgress,
                    mastery: masteryProgress,
                    daily: dailyChallenge,
                    weekly: weeklyChallenge,
                    selectedDistrict: $nextDistrictRaw,
                    reducedMotion: reducedMotion,
                    beginRun: {
                        let choice = campaignProgress.resolveSelection(DistrictID(rawValue: nextDistrictRaw))
                        nextDistrictRaw = choice.rawValue
                        // selectDistrict alone does not rebuild the sim; bootstrap aligns
                        // the cold session (ticks == 0) to the picker without burning ordinal.
                        scene.selectDistrict(choice)
                        scene.bootstrapCampaignDistrictIfNeeded(choice)
                        showingTitle = false
                        userPaused = false
                        syncPauseState()
                    },
                    startDaily: {
                        showingTitle = false
                        userPaused = false
                        scene.startChallengeRun(dailyChallenge)
                        nextDistrictRaw = dailyChallenge.districtId.rawValue
                        syncPauseState()
                    },
                    startWeekly: {
                        showingTitle = false
                        userPaused = false
                        scene.startChallengeRun(weeklyChallenge)
                        nextDistrictRaw = weeklyChallenge.districtId.rawValue
                        syncPauseState()
                    },
                    openSettings: {
                        showingSettings = true
                    }
                )
                .zIndex(4)
            } else if scene.isRunPaused && !scene.runCompleted && !showingSettings {
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
        .onChange(of: showingTitle) { _, _ in syncPauseState() }
        .onAppear {
            scene.activateAudioBank()
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
            // Defer until SwiftUI has registered the receipt observer so completed
            // XCUITest scenarios exercise the same persistence path as live runs.
            DispatchQueue.main.async {
                scene.installUITestScenarioIfRequested()
            }
        }
        .onChange(of: accessibilitySignature) { _, _ in applyAccessibilitySettings() }
        .onChange(of: scene.playerHealth) { previous, current in
            pulseDamageVignette(previous: previous, current: current)
        }
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
        // Device XCUITests: fullScreenCover is more reliable in the a11y tree than sheet detents.
        .sheet(isPresented: Binding(
            get: { !isUITesting && showingSettings },
            set: { showingSettings = $0 }
        )) {
            settingsContent
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(VisualDesignTokens.paper)
        }
        .fullScreenCover(isPresented: Binding(
            get: { isUITesting && showingSettings },
            set: { showingSettings = $0 }
        )) {
            settingsContent
                .presentationBackground(VisualDesignTokens.paper)
        }
    }

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-UITesting")
    }

    private var settingsContent: some View {
        AccessibilitySettingsView(
            controlsOnLeft: $controlsOnLeft,
            stickScale: $stickScale,
            stickOpacity: $stickOpacity,
            reducedMotion: $reducedMotion,
            reducedFlash: $reducedFlash,
            hapticsEnabled: $hapticsEnabled,
            audioMuted: $audioMuted,
            sfxVolume: $sfxVolume,
            musicVolume: $musicVolume,
            ambienceVolume: $ambienceVolume
        )
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
        scene.applyAudioSettings(muted: audioMuted, sfxVolume: sfxVolume,
                                 musicVolume: musicVolume, ambienceVolume: ambienceVolume)
    }

    /// A new run restores integrity to full, so only a drop counts as a hit. Scaled by
    /// the size of the bite: chip damage whispers, a real hit is loud. Contact damage
    /// lands every tick, so the pulse is refreshed rather than queued.
    private func pulseDamageVignette(previous: Double, current: Double) {
        lastObservedHealth = current
        guard current < previous else { return }
        let lost: Double = previous - current
        // Contact damage arrives ~0.25 integrity per tick, so the floor is what chip
        // damage looks like — it must whisper, or being touched at all washes the field.
        let scaled: Double = min(1.0, 0.18 + lost / 10.0)
        let peak: Double = reducedMotion ? min(scaled, 0.5) : scaled
        let duration: Double = reducedMotion ? 0.45 : 0.34
        damageFlash = peak
        withAnimation(.easeOut(duration: duration)) { damageFlash = 0 }
    }

    private func syncPauseState() {
        // Lifecycle, settings, and explicit pause all suspend the fixed-step loop.
        scene.setRunPaused(showingTitle || scenePhase != .active || userPaused || showingSettings)
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
    @Binding var audioMuted: Bool
    @Binding var sfxVolume: Double
    @Binding var musicVolume: Double
    @Binding var ambienceVolume: Double

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

                    settingsSection(title: "AUDIO") {
                        settingsToggle(
                            title: "Mute all audio",
                            subtitle: "Silences cues without changing levels",
                            isOn: $audioMuted
                        )
                        settingsSlider(
                            title: "Effects",
                            valueLabel: "\(Int(sfxVolume * 100))%",
                            value: $sfxVolume,
                            range: 0...1
                        )
                        settingsSlider(
                            title: "Music",
                            valueLabel: "\(Int(musicVolume * 100))%",
                            value: $musicVolume,
                            range: 0...1
                        )
                        settingsSlider(
                            title: "City ambience",
                            valueLabel: "\(Int(ambienceVolume * 100))%",
                            value: $ambienceVolume,
                            range: 0...1
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
                .accessibilityAddTraits(.isHeader)
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
                // The adjacent texts are visual siblings, not a semantic label/value
                // pair. Bind both explicitly so VoiceOver announces a useful
                // adjustable control instead of an unlabeled percentage slider.
                .accessibilityLabel(title)
                .accessibilityValue(valueLabel)
                .accessibilityHint("Swipe up or down with one finger to adjust")
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

            // Three cards side by side. Stacked vertically inside a 360pt panel they
            // overflowed landscape's ~390pt of height, which clipped the heading and
            // truncated the instruction to "…upgrade to resu…". Landscape has width to
            // spare; it is height that is scarce.
            HStack(alignment: .top, spacing: VisualDesignTokens.space10) {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    Button {
                        select(index)
                    } label: {
                        VStack(alignment: .leading, spacing: VisualDesignTokens.space4) {
                            Text(title(for: choice))
                                .font(VisualDesignTokens.bodyBold(.subheadline))
                                .foregroundStyle(VisualDesignTokens.ink)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Text(detail(for: choice))
                                .font(VisualDesignTokens.body(.caption))
                                .foregroundStyle(VisualDesignTokens.inkMuted)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(VisualDesignTokens.space16)
        .frame(maxWidth: 720)
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
        case .emergencyRepair: "Emergency repair"
        case .redundantSystems: "Redundant systems"
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
        case .emergencyRepair: "Salvage the broken grid to restore 40 integrity now."
        case .redundantSystems: "Recover integrity steadily whenever no sensor has contact."
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
// Hallmark · component: damage-vignette · genre: atmospheric · theme: terminal-grid
/// Brief red edge pulse when the player loses integrity. Damage already fires a
/// haptic and a cue and moves the HUD number, but on a phone — thumb on the stick,
/// eyes on the crowd — a digit changing in the corner is easy to miss entirely, so
/// hits landed without ever registering. Presentation only; reads position-free at
/// the screen edge so it never hides the threat that caused it.
private struct DamageVignette: View {
    let intensity: Double
    let reducedFlash: Bool

    var body: some View {
        RadialGradient(
            colors: [
                .clear,
                VisualDesignTokens.alarm.opacity(0.04 * intensity),
                VisualDesignTokens.alarm.opacity((reducedFlash ? 0.24 : 0.42) * intensity)
            ],
            center: .center,
            // Keep the middle of the field clear — the pulse must not obscure the
            // threat that caused it.
            startRadius: 210,
            endRadius: 560
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

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
                .accessibilityIdentifier("game-objective")

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
                    VStack(alignment: .leading, spacing: 1) {
                        Label(
                            "\(Int(max(0, bossHealth)))",
                            systemImage: "person.crop.circle.badge.exclamationmark"
                        )
                        .font(VisualDesignTokens.metric())
                        if let phase = scene.bossPhaseName, let progress = scene.bossPhaseProgress {
                            Text("\(phase) · \(progress)")
                                .font(VisualDesignTokens.bodyBold(.caption2))
                                .accessibilityIdentifier("boss-phase")
                        }
                    }
                    .foregroundStyle(VisualDesignTokens.warning)
                    .lineLimit(1)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(scene.bossName) \(Int(max(0, bossHealth))), phase \(scene.bossPhaseName ?? "active") \(scene.bossPhaseProgress ?? "")")
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
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

// Hallmark · surface: launch-shell · macrostructure: marquee-then-workbench
// genre: atmospheric · theme: terminal-grid · enrichment: none · nav: N9 · footer: Ft2
// pre-emit critique: P4 H4 E4 S4 R4 V4
// audience: first+returning · use: BEGIN RUN · tone: technical/austere
/// Two-phase launch: splash (brand beat) → start menu (district, challenges, briefing).
/// Suppressed under `-UITesting` at the RootView gate so chrome tests still land on play.
private enum LaunchPhase: Equatable {
    case splash
    case menu
}

private struct LaunchShellOverlay: View {
    @Binding var phase: LaunchPhase
    let campaign: CampaignProgress
    let mastery: MasteryProgress
    let daily: ChallengeInstance
    let weekly: ChallengeInstance
    @Binding var selectedDistrict: String
    let reducedMotion: Bool
    let beginRun: () -> Void
    let startDaily: () -> Void
    let startWeekly: () -> Void
    let openSettings: () -> Void

    /// Cancels the splash auto-advance if the player taps through early.
    @State private var splashGeneration = 0

    private var resolvedDistrict: DistrictID {
        campaign.resolveSelection(DistrictID(rawValue: selectedDistrict))
    }

    var body: some View {
        ZStack {
            VisualDesignTokens.paper
                .ignoresSafeArea()
            // Absorb every stray tap so nothing reaches the paused field behind.
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { }
                .accessibilityHidden(true)

            Group {
                if phase == .splash {
                    SplashSurface(
                        reducedMotion: reducedMotion,
                        advance: advanceToMenu
                    )
                    .transition(splashTransition)
                } else {
                    StartMenuSurface(
                        campaign: campaign,
                        mastery: mastery,
                        daily: daily,
                        weekly: weekly,
                        selectedDistrict: $selectedDistrict,
                        resolvedDistrict: resolvedDistrict,
                        beginRun: beginRun,
                        startDaily: startDaily,
                        startWeekly: startWeekly,
                        openSettings: openSettings
                    )
                    .transition(menuTransition)
                }
            }
            .animation(reducedMotion ? .easeOut(duration: 0.12) : .easeOut(duration: 0.28), value: phase)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualDesignTokens.paper)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(phase == .splash ? "splash-screen" : "title-screen")
        .onAppear {
            guard phase == .splash else { return }
            scheduleSplashAdvance()
        }
    }

    private var splashTransition: AnyTransition {
        reducedMotion ? .opacity : .opacity.combined(with: .scale(scale: 1.02))
    }

    private var menuTransition: AnyTransition {
        .opacity
    }

    private func advanceToMenu() {
        guard phase == .splash else { return }
        splashGeneration &+= 1
        phase = .menu
    }

    private func scheduleSplashAdvance() {
        splashGeneration &+= 1
        let generation = splashGeneration
        let delayNs: UInt64 = reducedMotion ? 350_000_000 : 1_550_000_000
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delayNs)
            guard generation == splashGeneration, phase == .splash else { return }
            phase = .menu
        }
    }
}

// Hallmark · component: splash-surface · genre: atmospheric · theme: terminal-grid
/// Full-bleed brand beat. No menu chrome — wordmark, one honest line, then the menu.
private struct SplashSurface: View {
    let reducedMotion: Bool
    let advance: () -> Void

    @State private var markOpacity: Double = 0

    var body: some View {
        ZStack {
            // Quiet phosphor wash — single cool bloom, no glass, no multi-hue.
            RadialGradient(
                colors: [
                    VisualDesignTokens.accent.opacity(0.10),
                    VisualDesignTokens.paper.opacity(0)
                ],
                center: .center,
                startRadius: 12,
                endRadius: 220
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            VStack(spacing: VisualDesignTokens.space14) {
                HStack(alignment: .firstTextBaseline, spacing: VisualDesignTokens.space8) {
                    Text("SURVEILLANCE")
                        .foregroundStyle(VisualDesignTokens.ink)
                    Text("SURVIVOR")
                        .foregroundStyle(VisualDesignTokens.accent)
                }
                .font(VisualDesignTokens.display(.largeTitle))
                .minimumScaleFactor(0.55)
                .lineLimit(1)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("splash-wordmark")

                Rectangle()
                    .fill(VisualDesignTokens.accentDim)
                    .frame(width: 72, height: 2)
                    .accessibilityHidden(true)

                Text("OFFLINE · ANTI-SURVEILLANCE · ROGUELITE")
                    .font(VisualDesignTokens.bodyBold(.caption2))
                    .foregroundStyle(VisualDesignTokens.inkMuted)
                    .tracking(0.8)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("splash-tagline")

                Text(reducedMotion ? "CONTINUE" : "TAP TO CONTINUE")
                    .font(VisualDesignTokens.body(.caption2))
                    .foregroundStyle(VisualDesignTokens.inkFaint)
                    .padding(.top, VisualDesignTokens.space8)
                    .accessibilityIdentifier("splash-continue-hint")
            }
            .padding(.horizontal, VisualDesignTokens.space24)
            .opacity(markOpacity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: advance)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Surveillance Survivor. Offline anti-surveillance roguelite. Double tap to continue.")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("splash-surface")
        .onAppear {
            if reducedMotion {
                markOpacity = 1
            } else {
                withAnimation(.easeOut(duration: 0.45)) { markOpacity = 1 }
            }
        }
    }
}

// Hallmark · component: start-menu · genre: atmospheric · theme: terminal-grid
/// Workbench menu: pick district, begin run, optional challenges, how-to, settings.
private struct StartMenuSurface: View {
    let campaign: CampaignProgress
    let mastery: MasteryProgress
    let daily: ChallengeInstance
    let weekly: ChallengeInstance
    @Binding var selectedDistrict: String
    let resolvedDistrict: DistrictID
    let beginRun: () -> Void
    let startDaily: () -> Void
    let startWeekly: () -> Void
    let openSettings: () -> Void

    @State private var showHowTo = false

    private var unlocked: [DistrictDefinition] { campaign.unlockedDistricts }

    private var marketingVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    var body: some View {
        // Landscape height is tight; scroll degrades Dynamic Type instead of clipping the CTA.
        ScrollView {
            VStack(alignment: .leading, spacing: VisualDesignTokens.space10) {
                headerBlock
                statusLine
                districtPicker
                primaryActions
                challengeBlock
                howToBlock
                footerLine
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, VisualDesignTokens.space24)
            .padding(.vertical, VisualDesignTokens.space14)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollBounceBehavior(.basedOnSize)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("start-menu")
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
            HStack(alignment: .firstTextBaseline, spacing: VisualDesignTokens.space6) {
                Text("SURVEILLANCE")
                    .foregroundStyle(VisualDesignTokens.ink)
                Text("SURVIVOR")
                    .foregroundStyle(VisualDesignTokens.accent)
            }
            .font(VisualDesignTokens.display(.title3))
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("title-wordmark")

            Rectangle()
                .fill(VisualDesignTokens.rule)
                .frame(height: 1)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: VisualDesignTokens.space2) {
                Text(resolvedDistrict.cityName.uppercased())
                    .font(VisualDesignTokens.bodyBold(.footnote))
                    .foregroundStyle(VisualDesignTokens.ink)
                Text(resolvedDistrict.definition.title)
                    .font(VisualDesignTokens.body(.caption2))
                    .foregroundStyle(VisualDesignTokens.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("title-district")
        }
    }

    private var statusLine: some View {
        Text(
            "CAMPAIGN \(campaign.highestUnlockedLevel)/\(campaign.maxCampaignLevel) · MASTERY \(mastery.totalExtractions)/\(mastery.totalRuns) · STREAK \(mastery.currentDailyStreak)"
        )
        .font(VisualDesignTokens.bodyBold(.caption2))
        .foregroundStyle(VisualDesignTokens.accentSoft)
        .accessibilityIdentifier("start-menu-status")
        .accessibilityLabel(
            "Campaign unlock \(campaign.highestUnlockedLevel) of \(campaign.maxCampaignLevel), mastery \(mastery.totalExtractions) extractions of \(mastery.totalRuns) runs, daily streak \(mastery.currentDailyStreak)"
        )
    }

    private var districtPicker: some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
            Text("DISTRICT")
                .font(VisualDesignTokens.bodyBold(.caption2))
                .foregroundStyle(VisualDesignTokens.inkMuted)
            ForEach(unlocked, id: \.id) { district in
                let cleared = campaign.completedDistricts.contains(district.id)
                // resolvedDistrict clamps locked/stale AppStorage onto an unlocked city.
                let selected = resolvedDistrict == district.id
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
                        if selected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(VisualDesignTokens.accent)
                        }
                    }
                    .padding(.horizontal, VisualDesignTokens.space10)
                    .padding(.vertical, VisualDesignTokens.space8)
                    .background(
                        (selected ? VisualDesignTokens.paperElevated : VisualDesignTokens.paper)
                            .opacity(0.95),
                        in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
                            .strokeBorder(
                                selected ? VisualDesignTokens.accentDim : VisualDesignTokens.ruleSoft,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    "\(district.cityName), \(district.title)\(cleared ? ", cleared" : "")\(selected ? ", selected" : "")"
                )
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityIdentifier("start-district-\(district.id.rawValue)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("start-district-picker")
        .accessibilityLabel("District")
    }

    private var primaryActions: some View {
        HStack(spacing: VisualDesignTokens.space8) {
            Button(action: beginRun) {
                Text("BEGIN RUN")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GameChromePrimaryButtonStyle())
            .accessibilityIdentifier("title-begin-run")
            .accessibilityLabel("Begin run in \(resolvedDistrict.cityName)")

            Button(action: openSettings) {
                Text("SETTINGS")
            }
            .buttonStyle(GameChromeSecondaryButtonStyle())
            .accessibilityIdentifier("title-open-settings")
        }
        .padding(.top, VisualDesignTokens.space2)
    }

    private var challengeBlock: some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
            Text("CHALLENGES")
                .font(VisualDesignTokens.bodyBold(.caption2))
                .foregroundStyle(VisualDesignTokens.inkMuted)
            Text("Daily · \(daily.contractDisplayName) · \(daily.districtId.cityName)")
                .font(VisualDesignTokens.body(.caption2))
                .foregroundStyle(VisualDesignTokens.inkFaint)
                .accessibilityIdentifier("start-daily-detail")
            Button("START DAILY CHALLENGE", action: startDaily)
                .buttonStyle(GameChromeSecondaryButtonStyle())
                .accessibilityIdentifier("title-start-daily")
            Text("Weekly · \(weekly.contractDisplayName) · \(weekly.districtId.cityName)")
                .font(VisualDesignTokens.body(.caption2))
                .foregroundStyle(VisualDesignTokens.inkFaint)
                .accessibilityIdentifier("start-weekly-detail")
            Button("START WEEKLY CHALLENGE", action: startWeekly)
                .buttonStyle(GameChromeSecondaryButtonStyle())
                .accessibilityIdentifier("title-start-weekly")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var howToBlock: some View {
        VStack(alignment: .leading, spacing: VisualDesignTokens.space6) {
            Button {
                showHowTo.toggle()
            } label: {
                HStack(spacing: VisualDesignTokens.space6) {
                    Text("HOW TO PLAY")
                        .font(VisualDesignTokens.bodyBold(.caption2))
                        .foregroundStyle(VisualDesignTokens.inkMuted)
                    Image(systemName: showHowTo ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(VisualDesignTokens.inkFaint)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("title-how-to-toggle")
            .accessibilityLabel(showHowTo ? "Hide how to play" : "Show how to play")

            if showHowTo {
                briefing("MOVE", "You steer. Your countermeasures fire themselves at whatever they have acquired.")
                briefing("KNOCK OUT THE POLES", "Every camera you break is a data shard and a new upgrade to draft.")
                briefing("GO LOUD, THEN GO DARK", "Breaking the grid draws the district authority. Put it down, then slip out through the Blind Spot.")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("title-how-to")
    }

    private var footerLine: some View {
        Text("v\(marketingVersion) · PRE-ALPHA · NO ACCOUNTS · NO LIVE FEEDS")
            .font(VisualDesignTokens.body(.caption2))
            .foregroundStyle(VisualDesignTokens.inkDisabled)
            .accessibilityIdentifier("start-menu-version")
    }

    private func briefing(_ heading: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(heading)
                .font(VisualDesignTokens.bodyBold(.caption2))
                .foregroundStyle(VisualDesignTokens.accentSoft)
            Text(detail)
                .font(VisualDesignTokens.body(.caption2))
                .foregroundStyle(VisualDesignTokens.inkMuted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct GameChromeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(VisualDesignTokens.bodyBold(.caption))
            .foregroundStyle(VisualDesignTokens.ink)
            .padding(.horizontal, VisualDesignTokens.space16)
            .padding(.vertical, VisualDesignTokens.space10)
            .background(
                VisualDesignTokens.paperElevated.opacity(configuration.isPressed ? 0.7 : 1),
                in: RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
            )
            .overlay(
                RoundedRectangle(cornerRadius: VisualDesignTokens.radiusMeter)
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
