import Foundation
import Testing
@testable import SurveillanceCore

/// Headless lifecycle matrix: every authored district can boot, open a Blind Spot
/// after forced boss defeat, extract, and emit a stable receipt.
@Suite("District campaign matrix")
struct DistrictCampaignMatrixTests {
    private func forceBossDefeatAndExtract(district: DistrictID, seed: UInt64) -> (Simulation, RunReceipt) {
        var state = RunState(seed: seed, district: district)
        // Preserve world/sensors from authored profile; inject dead boss.
        state.entities.removeAll { $0.kind == .boss }
        state.entities.append(
            Entity(id: 9_001, kind: .boss, position: district.profile.bossSpawn, health: 0, radius: 42)
        )
        var simulation = Simulation(state: state, rngSeed: seed)
        _ = simulation.step(input: .init(autoFireEnabled: false))
        #expect(simulation.state.extractionOpen)

        guard let playerIndex = simulation.state.entities.firstIndex(where: { $0.kind == .player }),
              let extraction = simulation.state.entities.first(where: { $0.kind == .extraction }) else {
            Issue.record("missing player or extraction for \(district.rawValue)")
            return (simulation, simulation.runReceipt())
        }

        var completionState = simulation.state
        completionState.entities[playerIndex].position = extraction.position
        var completion = Simulation(state: completionState, rngSeed: seed)
        _ = completion.step(input: .init(autoFireEnabled: false))
        return (completion, completion.runReceipt())
    }

    @Test func everyDistrictCompletesForcedExtractionWithValidReceipt() {
        for district in DistrictID.allCases {
            let seed: UInt64 = 0xCA_0000 &+ UInt64(district.definition.level)
            let (sim, receipt) = forceBossDefeatAndExtract(district: district, seed: seed)
            #expect(sim.state.runCompleted, "run incomplete for \(district.rawValue)")
            #expect(receipt.extractionCompleted)
            #expect(receipt.district == district)
            #expect(receipt.schemaVersion == RunReceipt.schemaVersion)
            #expect(receipt.seed == seed)
            #expect(sim.state.entities.filter { $0.kind == .extraction }.count == 1)
            #expect(sim.state.entities.filter { $0.kind == .player }.count == 1)
            // No entity outside world bounds.
            let bounds = district.profile.bounds
            for entity in sim.state.entities {
                #expect(
                    bounds.contains(entity.position)
                        || entity.kind == .projectile
                        || entity.kind == .signalFlood,
                    "entity \(entity.id) (\(entity.kind)) out of bounds in \(district.rawValue)"
                )
            }
        }
    }

    @Test func everyDistrictForcedExtractionIsDeterministicForSeed() {
        for district in DistrictID.allCases {
            let seed: UInt64 = 0xDE_0000 &+ UInt64(district.definition.level)
            let a = forceBossDefeatAndExtract(district: district, seed: seed).1
            let b = forceBossDefeatAndExtract(district: district, seed: seed).1
            #expect(a.district == b.district)
            #expect(a.extractionCompleted == b.extractionCompleted)
            #expect(a.seed == b.seed)
            #expect(a.elapsedSeconds == b.elapsedSeconds)
            #expect(a.schemaVersion == b.schemaVersion)
        }
    }

    @Test func representativeDefeatPathsDoNotExtract() {
        let samples: [DistrictID] = [.wichita, .columbus, .atlanta]
        for district in samples {
            var state = RunState(seed: 0xDEFE_A7ED, district: district)
            // Force lethal integrity without relying on long contact DPS windows.
            if let playerIndex = state.entities.firstIndex(where: { $0.kind == .player }) {
                state.entities[playerIndex].health = 0
            }
            state.activeWeapons = []
            var simulation = Simulation(state: state, rngSeed: 0xDEFE_A7ED)
            for _ in 0..<30 {
                _ = simulation.step(input: .init(autoFireEnabled: false))
                if simulation.state.runCompleted { break }
            }
            #expect(simulation.state.runCompleted, "expected defeat path to finish for \(district.rawValue)")
            #expect(simulation.state.playerDefeated)
            #expect(simulation.runReceipt().extractionCompleted == false)
            #expect(simulation.state.extractionOpen == false)
        }
    }

    @Test func differentSeedsYieldDifferentAllowedVariationForWichita() {
        let seedA: UInt64 = 11
        let seedB: UInt64 = 99
        var simA = Simulation(seed: seedA, district: .wichita)
        var simB = Simulation(seed: seedB, district: .wichita)
        for _ in 0..<180 {
            _ = simA.step(input: .init(movement: .init(x: 1, y: 0), autoFireEnabled: true))
            _ = simB.step(input: .init(movement: .init(x: 1, y: 0), autoFireEnabled: true))
        }
        // Seeds differ → either entity set, suspicion, or projectile state should diverge eventually.
        let sameEntities = simA.state.entities.map(\.id) == simB.state.entities.map(\.id)
            && simA.state.entities.map(\.position) == simB.state.entities.map(\.position)
        let sameSuspicion = simA.state.suspicion == simB.state.suspicion
        #expect(!(sameEntities && sameSuspicion && simA.state.seed != simB.state.seed) || seedA == seedB)
        #expect(simA.state.seed == seedA)
        #expect(simB.state.seed == seedB)
    }
}
