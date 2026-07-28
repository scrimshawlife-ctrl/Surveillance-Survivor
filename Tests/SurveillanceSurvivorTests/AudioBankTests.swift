import AVFoundation
import Foundation
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

/// Verifies the delivery bank is genuinely present and playable, not merely
/// catalogued. These are the checks that would have caught the bank being
/// absent from the app bundle, which is easy to miss because the resolver keeps
/// working and the game just stays silent.
@MainActor
struct AudioBankTests {
    /// Resolve the bundle that actually carries the delivery files. `AudioBank`
    /// lives in the app module, so this is the app bundle in both the test host
    /// and the shipped app.
    private var appBundle: Bundle { Bundle(for: AudioBank.self) }

    @Test func everyRuntimeCueAssetIsBundledAsDelivery() throws {
        let expected = AudioEventCatalog.bundled.cues.map(\.assetName)
        #expect(!expected.isEmpty)
        for name in expected {
            let url = appBundle.url(forResource: name, withExtension: "caf")
            #expect(url != nil, "delivery asset missing from bundle: \(name).caf")
        }
    }

    @Test func bundledDeliveryAssetsDecodeAtTheExpectedFormat() throws {
        var names = AudioEventCatalog.bundled.cues.map(\.assetName)
        if let scenes = AudioEventCatalog.bundled.scenes {
            names += scenes.districts.flatMap { [$0.ambienceAsset, $0.runAsset] }
        }
        for name in names {
            guard let url = appBundle.url(forResource: name, withExtension: "caf") else { continue }
            let file = try AVAudioFile(forReading: url)
            #expect(file.fileFormat.sampleRate == 48_000, "\(name) is not 48 kHz")
            #expect(file.fileFormat.channelCount == 2, "\(name) is not stereo")
            #expect(file.length > 0, "\(name) decoded to zero frames")
        }
    }

    @Test func bankLoadsEveryAddressableAssetAndReportsIt() {
        let bank = AudioBank()
        let loaded = bank.start()
        // The bank must load both mechanisms: event cues *and* the looping assets
        // the scene catalog projects from run state. Cues alone would understate it.
        var expected = Set(AudioEventCatalog.bundled.cues.map(\.assetName))
        if let scenes = AudioEventCatalog.bundled.scenes {
            for definition in scenes.districts {
                expected.insert(definition.ambienceAsset)
                expected.insert(definition.runAsset)
                if let foundation = definition.foundationAsset { expected.insert(foundation) }
                if let boss = definition.bossAsset { expected.insert(boss) }
                expected.formUnion(definition.bossPhaseAssets ?? [])
            }
            if let overlay = scenes.overlayExtractionAsset { expected.insert(overlay) }
            if let sweep = scenes.scanSweepAsset { expected.insert(sweep) }
        }
        #expect(loaded == expected, "loaded \(loaded.count) of \(expected.count) addressable assets")
        bank.stop()
    }

    @Test func everyDeliveryAssetTheSceneCatalogNamesIsBundled() throws {
        let scenes = try #require(AudioEventCatalog.bundled.scenes)
        for definition in scenes.districts {
            for name in [definition.ambienceAsset, definition.runAsset] {
                #expect(appBundle.url(forResource: name, withExtension: "caf") != nil,
                        "\(name) is not bundled")
            }
        }
    }

    @Test func playerOnlyReportsCuesWhoseAssetsExist() {
        let player = AudioCuePlayer()
        // Dry-run: no bank activated, so nothing is playable even though the
        // resolver still produces requests for diagnostics.
        let played = player.play(events: [RunEvent(.weaponFired, "kinetic")], atTick: 600)
        #expect(played == 0)
        #expect(!player.lastResolvedRequests.isEmpty)
    }

    @Test func activatedPlayerPlaysResolvedCues() {
        let player = AudioCuePlayer()
        let loaded = player.activateBank()
        #expect(!loaded.isEmpty)
        let played = player.play(events: [RunEvent(.weaponFired, "kinetic")], atTick: 600)
        #expect(played > 0, "weaponFired resolved to no playable cue")
    }

    @Test func mutingSilencesOutputWithoutDroppingResolution() {
        let player = AudioCuePlayer()
        player.activateBank()
        player.applyAudioSettings(muted: true, sfxVolume: 1, musicVolume: 1, ambienceVolume: 1)
        // Resolution is unaffected by mute; only the mixer output is silenced, so
        // cue diagnostics and receipts stay meaningful when a player mutes audio.
        _ = player.play(events: [lprDestroyedEvent()], atTick: 900)
        #expect(!player.lastResolvedRequests.isEmpty)
    }

    @Test func audioSessionUsesAmbientSoTheSilentSwitchIsRespected() {
        let bank = AudioBank()
        bank.start()
        #expect(AVAudioSession.sharedInstance().category == .ambient)
        bank.stop()
    }
}

/// A camera-pole destruction, which the catalog matches on message content
/// rather than on event kind alone.
private func lprDestroyedEvent() -> RunEvent {
    RunEvent(.entityDestroyed, "Removed \(EntityKind.cameraPole.rawValue)")
}
