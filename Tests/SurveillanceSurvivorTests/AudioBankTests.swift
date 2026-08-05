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

    @Test func bankDiscoversEveryAddressableAssetAndReportsIt() {
        let bank = AudioBank()
        let loaded = bank.start()
        // Availability covers both mechanisms without requiring every file to remain
        // decoded: event cues plus the loops projected from run state.
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

    @Test func bankPreloadsOnlySharedOneShots() {
        let bank = AudioBank()
        _ = bank.start()
        let expected = Set(
            AudioEventCatalog.bundled.cues
                .filter { $0.districtId == nil }
                .map(\.assetName)
        )
        #expect(bank.bufferedAssetNames == expected)

        if let scenes = AudioEventCatalog.bundled.scenes {
            let loopNames = Set(scenes.districts.flatMap { definition -> [String] in
                var names = [definition.ambienceAsset, definition.runAsset]
                if let foundation = definition.foundationAsset { names.append(foundation) }
                if let boss = definition.bossAsset { names.append(boss) }
                names.append(contentsOf: definition.bossPhaseAssets ?? [])
                return names
            })
            #expect(bank.bufferedAssetNames.isDisjoint(with: loopNames))
        }
        bank.stop()
    }

    @Test func districtCuesLoadOnSceneDemandAndReplaceThePriorDistrictCache() throws {
        let bank = AudioBank()
        _ = bank.start()
        let scenes = try #require(AudioEventCatalog.bundled.scenes)
        let shared = Set(
            AudioEventCatalog.bundled.cues
                .filter { $0.districtId == nil }
                .map(\.assetName)
        )

        let wichitaState = RunState(seed: 1, district: .wichita)
        bank.apply(AudioSceneProjector.scene(for: wichitaState, catalog: scenes))
        let wichita = Set(
            AudioEventCatalog.bundled.cues
                .filter { $0.districtId == .wichita }
                .map(\.assetName)
        )
        #expect(bank.bufferedAssetNames == shared.union(wichita))

        let louisvilleState = RunState(seed: 2, district: .louisville)
        bank.apply(AudioSceneProjector.scene(for: louisvilleState, catalog: scenes))
        let louisville = Set(
            AudioEventCatalog.bundled.cues
                .filter { $0.districtId == .louisville }
                .map(\.assetName)
        )
        #expect(bank.bufferedAssetNames == shared.union(louisville))
        #expect(bank.bufferedAssetNames.isDisjoint(with: wichita))
        bank.stop()
    }

    @Test func sceneLoopsStreamWithoutEnteringThePCMBufferCache() throws {
        let bank = AudioBank()
        _ = bank.start()
        let scenes = try #require(AudioEventCatalog.bundled.scenes)
        let state = RunState(seed: 3, district: .wichita)
        let scene = AudioSceneProjector.scene(for: state, catalog: scenes)
        bank.apply(scene)

        let expectedStreams = Set([scene.foundation, scene.ambience, scene.music].compactMap { $0 })
        #expect(bank.streamingAssetNames == expectedStreams)
        #expect(bank.bufferedAssetNames.isDisjoint(with: expectedStreams))
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

    @Test func suspendingPlaybackHoldsTheBankAndSurvivesReactivation() {
        // Pausing the run, opening settings, or backgrounding the app all route through
        // setRunPaused, which suspends playback. Nothing covered it, and the failure
        // mode is the loudest one a player can hit: music continuing when the game is
        // not being played.
        //
        // Asserts the bank's own state. A first version of this checked only the
        // player's isPlaybackSuspended intent flag, which activateBank never clears —
        // so it passed even with the re-suspend removed, proving nothing.
        let player = AudioCuePlayer()
        player.activateBank()
        #expect(player.bank?.isSuspended == false)

        player.suspendPlayback()
        #expect(player.bank?.isSuspended == true, "suspend did not reach the bank")

        player.resumePlayback()
        #expect(player.bank?.isSuspended == false)

        // The case that actually needs the guard: suspended before any bank exists,
        // which is what happens when the app is backgrounded or launched straight
        // into the start menu before audio is activated. Building the bank then must
        // not start sound behind a screen the player is not playing.
        let launched = AudioCuePlayer()
        launched.suspendPlayback()
        #expect(launched.bank == nil, "precondition: no bank yet")
        launched.activateBank()
        #expect(launched.bank?.isSuspended == true,
                "a bank built while suspended started playing")
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
