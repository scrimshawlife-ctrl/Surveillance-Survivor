import Foundation
import Testing
@testable import SurveillanceCore

@Test func bundledCitySystemicRulesCoverTenCities() throws {
    let catalog = try CitySystemicRulesCatalog.loadBundled()
    #expect(catalog.forbidHiddenStatScaling)
    #expect(catalog.cities.count == DistrictID.allCases.count)
    try catalog.validate()
    for id in DistrictID.allCases {
        #expect(catalog.rule(for: id) != nil)
    }
}

@Test func wichitaAndLouisvilleAreProjectedSystems() throws {
    let catalog = try CitySystemicRulesCatalog.loadBundled()
    #expect(catalog.rule(for: .wichita)?.projectionStatus == "full_p9_proof")
    #expect(catalog.rule(for: .louisville)?.projectionStatus == "slice_a_projected")
    #expect(catalog.rule(for: .louisville)?.landmarkHookId == "louisville_redaction_corridor")
}

@Test func louisvilleInfrastructureAndCoordinationLoad() throws {
    let city = try CityStateCatalog.loadBundled()
    #expect(city.graph(for: .louisville) != nil)
    #expect((city.graph(for: .louisville)?.nodes.count ?? 0) >= 3)

    let coord = try CoordinationCatalog.loadBundled()
    #expect(coord.primaryChain(for: .louisville)?.id == "redaction_cascade")

    let landmarks = try LandmarkEncounterCatalog.loadBundled()
    #expect(landmarks.primary(for: .louisville)?.id == "louisville_redaction_corridor")

    let interactables = try InteractableCatalog.loadBundled()
    #expect(interactables.interactables(for: .louisville).count >= 6)
}

@Test func louisvilleSimulationIsSeedDeterministic() {
    func run() -> RunReceipt {
        var simulation = Simulation(seed: 77, district: .louisville)
        for _ in 0..<180 {
            _ = simulation.step(input: .init(autoFireEnabled: false))
        }
        return simulation.runReceipt()
    }
    #expect(run() == run())
}
