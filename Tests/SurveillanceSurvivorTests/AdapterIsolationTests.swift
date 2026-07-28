import Foundation
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@MainActor
private final class RecordingAudioBackend: AudioPlaybackBackend {
    private(set) var plays: [(url: URL, gain: Double)] = []

    func play(url: URL, gain: Double) {
        plays.append((url, gain))
    }
}

@Test @MainActor func audioAdapterDoesNotPlayWithoutAssetBank() {
    let backend = RecordingAudioBackend()
    let player = AudioCuePlayer(backend: backend)
    #expect(player.availableAssets.isEmpty)
    let events = [
        RunEvent(.weaponFired, "kinetic"),
        RunEvent(.tierChanged, "tier 1"),
        RunEvent(.extractionCompleted, "done")
    ]
    let played = player.play(events: events, atTick: 12)
    #expect(played == 0)
    #expect(backend.plays.isEmpty)
    #expect(!player.lastResolvedRequests.isEmpty)
    #expect(player.lastPlayedRequests.isEmpty)
}

@Test @MainActor func audioAdapterPlaysOnlyApprovedBankEntries() {
    let backend = RecordingAudioBackend()
    var resolver = AudioCueResolver()
    let events = [RunEvent(.extractionCompleted, "Extracted through Blind Spot")]
    let requests = resolver.resolve(events: events, atTick: 1)
    #expect(!requests.isEmpty)
    let asset = requests[0].assetName
    let url = URL(fileURLWithPath: "/approved-audio-bank/\(asset).wav")
    let bank = AudioAssetBank(entries: [.init(assetName: asset, url: url)])
    let player = AudioCuePlayer(assetBank: bank, backend: backend)
    let played = player.play(events: events, atTick: 2)
    #expect(played == 1)
    #expect(backend.plays.map(\.url) == [url])
    #expect(player.lastPlayedRequests.map(\.assetName) == [asset])
}

@Test func audioAssetBankDiscoversOnlyCatalogApprovedRuntimeAssets() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle", isDirectory: true)
    let runtime = root.appendingPathComponent("Audio/Delivery/Runtime", isDirectory: true)
    try FileManager.default.createDirectory(at: runtime, withIntermediateDirectories: true)
    try "{}".write(to: root.appendingPathComponent("Info.plist"), atomically: true, encoding: .utf8)
    try Data([0]).write(to: runtime.appendingPathComponent("sfx_extraction_completed.wav"))
    try Data([1]).write(to: runtime.appendingPathComponent("not_in_catalog.wav"))
    defer { try? FileManager.default.removeItem(at: root) }

    let bundle = try #require(Bundle(path: root.path))
    let bank = AudioAssetBank(bundle: bundle)
    #expect(bank.availableAssets == ["sfx_extraction_completed"])
    #expect(bank.entry(for: "not_in_catalog") == nil)
}

@Test @MainActor func hapticDisabledSuppressesPlatformOutputButResolvesKinds() {
    let haptics = HapticFeedback()
    haptics.isEnabled = false
    haptics.play([
        RunEvent(.tierChanged, "up"),
        RunEvent(.playerDamaged, "hit"),
        RunEvent(.weaponFired, "no-haptic")
    ])
    #expect(haptics.lastPlayCount == 0)
    #expect(haptics.lastResolvedKinds.contains(.tierChanged))
    #expect(haptics.lastResolvedKinds.contains(.playerDamaged))
    #expect(!haptics.lastResolvedKinds.contains(.weaponFired))
}

@Test @MainActor func hapticEnabledCountsOneOutputPerMatchingEvent() {
    let haptics = HapticFeedback()
    haptics.isEnabled = true
    haptics.play([
        RunEvent(.tierChanged, "up"),
        RunEvent(.upgradeOffered, "draft")
    ])
    #expect(haptics.lastPlayCount == 2)
}

@Test @MainActor func hapticSuppressesDamagePulseWhenDefeatIsInSameBatch() {
    let haptics = HapticFeedback()
    haptics.isEnabled = true
    haptics.play([
        RunEvent(.playerDamaged, "hit"),
        RunEvent(.playerDefeated, "down")
    ])
    #expect(haptics.lastPlayCount == 1)
    #expect(haptics.lastResolvedKinds == [.playerDefeated])
}

@Test @MainActor func hapticSuppressesExtractionOpenedWhenCompletedInSameBatch() {
    let haptics = HapticFeedback()
    haptics.isEnabled = true
    haptics.play([
        RunEvent(.extractionOpened, "open"),
        RunEvent(.extractionCompleted, "done")
    ])
    #expect(haptics.lastPlayCount == 1)
    #expect(haptics.lastResolvedKinds == [.extractionCompleted])
}

@Test @MainActor func hapticCoalescesSameTickCameraDestroys() {
    let haptics = HapticFeedback()
    haptics.isEnabled = true
    haptics.play([
        RunEvent(.entityDestroyed, "cameraPole destroyed"),
        RunEvent(.entityDestroyed, "cameraPole destroyed"),
        RunEvent(.entityDestroyed, "securityGuard destroyed")
    ])
    #expect(haptics.lastPlayCount == 1)
    #expect(haptics.lastResolvedKinds == [.entityDestroyed])
}

@Test @MainActor func audioSuppressesExtractionOpenedWhenCompletedInSameBatch() {
    let player = AudioCuePlayer()
    _ = player.play(
        events: [
            RunEvent(.extractionOpened, "open"),
            RunEvent(.extractionCompleted, "done")
        ],
        atTick: 12
    )
    #expect(!player.lastResolvedRequests.contains { $0.sourceEvent == .extractionOpened })
    #expect(player.lastResolvedRequests.contains { $0.sourceEvent == .extractionCompleted })
}

@Test @MainActor func audioSuppressesDamageWhenDefeatIsInSameBatch() {
    let player = AudioCuePlayer()
    _ = player.play(
        events: [
            RunEvent(.playerDamaged, "hit"),
            RunEvent(.playerDefeated, "down")
        ],
        atTick: 20
    )
    #expect(!player.lastResolvedRequests.contains { $0.sourceEvent == .playerDamaged })
    #expect(player.lastResolvedRequests.contains { $0.sourceEvent == .playerDefeated })
}

@Test func simulationReceiptUnaffectedByAudioResolverActivity() {
    var simA = Simulation(seed: 42, district: .wichita)
    var simB = Simulation(seed: 42, district: .wichita)
    var resolver = AudioCueResolver()
    for _ in 0..<90 {
        let events = simA.step(input: .init(autoFireEnabled: true))
        _ = resolver.resolve(events: events, atTick: simA.runReceipt().elapsedTicks)
        _ = simB.step(input: .init(autoFireEnabled: true))
    }
    #expect(simA.runReceipt().seed == simB.runReceipt().seed)
    #expect(simA.state.suspicion == simB.state.suspicion)
    #expect(simA.state.entities.map(\.id) == simB.state.entities.map(\.id))
}
