import Foundation
import Testing
import SurveillanceCore
@testable import SurveillanceSurvivor

@Test @MainActor func audioAdapterDoesNotPlayWithoutAssetBank() {
    let player = AudioCuePlayer()
    #expect(player.availableAssets.isEmpty)
    let events = [
        RunEvent(.weaponFired, "kinetic"),
        RunEvent(.tierChanged, "tier 1"),
        RunEvent(.extractionCompleted, "done")
    ]
    let played = player.play(events: events, atTick: 12)
    #expect(played == 0)
    #expect(!player.lastResolvedRequests.isEmpty)
}

@Test @MainActor func audioAdapterPlaysOnlyWhenAssetIsRegistered() {
    let player = AudioCuePlayer()
    var resolver = AudioCueResolver()
    let events = [RunEvent(.extractionCompleted, "Extracted through Blind Spot")]
    let requests = resolver.resolve(events: events, atTick: 1)
    #expect(!requests.isEmpty)
    let asset = requests[0].assetName
    player.setAvailableAssets([asset])
    let played = player.play(events: events, atTick: 2)
    #expect(played >= 1)
    #expect(player.lastResolvedRequests.contains { $0.assetName == asset })
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
