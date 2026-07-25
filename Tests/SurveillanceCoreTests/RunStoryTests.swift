import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledStoryRulesForbidInventedNarrative() throws {
    let catalog = try RunStoryCatalog.loadBundled()
    #expect(catalog.forbidInventedNarrative)
    #expect(!catalog.rules.isEmpty)
    #expect(catalog.maxSummaryLines >= 1)
}

@Test func emptyRunHasNoInventedCombatFacts() {
    let receipt = Simulation(seed: 1).runReceipt()
    #expect(receipt.schemaVersion == 7)
    // No sensors killed, no extraction — combat facts must not appear.
    #expect(!receipt.storyFacts.contains { $0.id == "sensors_neutralized" })
    #expect(!receipt.storyFacts.contains { $0.id == "extraction_escape" })
    #expect(!receipt.storyFacts.contains { $0.id == "player_defeated" })
}

@Test func extractionProducesOutcomeFactOnlyWhenEvidencePresent() {
    // Force extraction path via known district helper pattern from other tests.
    var state = RunState(seed: 42, district: .wichita)
    if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
        state.entities[playerIndex].health = 1_000_000
    }
    // Kill sensors and force boss defeat path is heavy; use compile on crafted receipt.
    let evidence = StoryEvidenceSnapshot(
        seed: 42,
        district: .wichita,
        extractionCompleted: true,
        eventSequence: [
            RecordedRunEvent(tick: 10, sequence: 0, event: .init(.extractionCompleted, "Extracted through Blind Spot"))
        ],
        deathsByArchetype: [.cameraPole: 3],
        selectedUpgrades: [.lowProfileRouting],
        directorDecisions: [],
        cityStateEvents: [],
        buildSynergyActivations: [],
        buildEngine: nil,
        coordinationEvents: [],
        coordination: nil,
        suspicionTimeline: [SuspicionSample(tick: 1, value: 12, tier: .backgroundNoise)]
    )
    let report = RunStoryCompiler.compile(evidence: evidence)
    #expect(report.facts.contains { $0.id == "extraction_escape" })
    #expect(report.facts.contains { $0.id == "sensors_neutralized" })
    #expect(report.summary.contains("Wichita"))
    #expect(report.summary.contains("3"))
    #expect(!report.facts.contains { $0.id == "player_defeated" })
}

@Test func compilerNeverEmitsFactsWithoutEvidence() {
    let evidence = StoryEvidenceSnapshot(
        seed: 7,
        district: .louisville,
        extractionCompleted: false,
        eventSequence: [],
        deathsByArchetype: [:],
        selectedUpgrades: [],
        directorDecisions: [],
        cityStateEvents: [],
        buildSynergyActivations: [],
        buildEngine: .empty,
        coordinationEvents: [],
        coordination: .idle,
        suspicionTimeline: []
    )
    let report = RunStoryCompiler.compile(evidence: evidence)
    #expect(report.facts.isEmpty)
    #expect(report.summary.isEmpty)
}

@Test func storyCompilationIsDeterministicForIdenticalEvidence() {
    let evidence = StoryEvidenceSnapshot(
        seed: 99,
        district: .wichita,
        extractionCompleted: false,
        eventSequence: [
            RecordedRunEvent(tick: 5, sequence: 0, event: .init(.playerDefeated, "The grid reacquired the Ghost")),
            RecordedRunEvent(tick: 4, sequence: 0, event: .init(.bossActivated, "Boss"))
        ],
        deathsByArchetype: [.securityGuard: 2],
        selectedUpgrades: [.rapidCountermeasure, .reinforcedSignal],
        directorDecisions: [
            DirectorDecisionSample(
                tick: 60,
                elapsed: 1,
                tier: .personOfInterest,
                actionId: "lightPatrol",
                budgetRemaining: 1,
                reason: "test"
            )
        ],
        cityStateEvents: [],
        buildSynergyActivations: [],
        buildEngine: nil,
        coordinationEvents: [
            CoordinationEventSample(
                tick: 10,
                chainId: "lot_capture_cascade",
                linkId: "sensorDetect",
                status: .interrupted,
                signal: "sensorDestroyed",
                reason: "interrupted"
            )
        ],
        coordination: CoordinationState(interruptedCount: 1),
        suspicionTimeline: [SuspicionSample(tick: 1, value: 70, tier: .coordinatedResponse)]
    )
    let a = RunStoryCompiler.compile(evidence: evidence)
    let b = RunStoryCompiler.compile(evidence: evidence)
    #expect(a == b)
    #expect(a.facts.contains { $0.id == "player_defeated" })
    #expect(a.facts.contains { $0.id == "boss_activated" })
    #expect(a.facts.contains { $0.id == "coordination_interrupted" })
    #expect(a.summaryLines.count <= RunStoryCatalog.bundled.maxSummaryLines)
}

@Test func runReceiptEmbedsCompiledStory() {
    var simulation = Simulation(seed: 5150)
    for _ in 0..<(60 * 3) {
        _ = simulation.step(input: .init(autoFireEnabled: true))
    }
    let receipt = simulation.runReceipt()
    #expect(receipt.schemaVersion == 7)
    // Story fields always present (may be empty if no evidence yet).
    #expect(receipt.storySummary == receipt.storyFacts.prefix(RunStoryCatalog.bundled.maxSummaryLines).map(\.text).joined(separator: " "))
}
