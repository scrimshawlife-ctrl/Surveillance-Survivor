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

@Test func projectedCitiesHaveCorrectStatus() throws {
    let catalog = try CitySystemicRulesCatalog.loadBundled()
    #expect(catalog.rule(for: .wichita)?.projectionStatus == "full_p9_proof")
    #expect(catalog.rule(for: .louisville)?.projectionStatus == "slice_a_projected")
    #expect(catalog.rule(for: .tulsa)?.projectionStatus == "slice_a_projected")
    #expect(catalog.rule(for: .dayton)?.projectionStatus == "slice_a_projected")
    #expect(catalog.rule(for: .louisville)?.landmarkHookId == "louisville_redaction_corridor")
    #expect(catalog.rule(for: .tulsa)?.landmarkHookId == "tulsa_extraction_yard")
    #expect(catalog.rule(for: .dayton)?.landmarkHookId == "dayton_gateway_cluster")
}

@Test func projectedDistrictsLoadFullSystemStack() throws {
    let city = try CityStateCatalog.loadBundled()
    let coord = try CoordinationCatalog.loadBundled()
    let landmarks = try LandmarkEncounterCatalog.loadBundled()
    let interactables = try InteractableCatalog.loadBundled()

    let expected: [(DistrictID, String, String)] = [
        (.louisville, "redaction_cascade", "louisville_redaction_corridor"),
        (.tulsa, "crude_extract_cascade", "tulsa_extraction_yard"),
        (.dayton, "gateway_chain_cascade", "dayton_gateway_cluster")
    ]
    for (district, chainId, landmarkId) in expected {
        #expect(city.graph(for: district) != nil)
        #expect((city.graph(for: district)?.nodes.count ?? 0) >= 3)
        #expect(coord.primaryChain(for: district)?.id == chainId)
        #expect(landmarks.primary(for: district)?.id == landmarkId)
        #expect(interactables.interactables(for: district).count >= 6)
    }
}

@Test func projectedDistrictSimulationsAreSeedDeterministic() {
    for district in [DistrictID.louisville, .tulsa, .dayton] {
        func run() -> RunReceipt {
            var simulation = Simulation(seed: 77, district: district)
            for _ in 0..<180 {
                _ = simulation.step(input: .init(autoFireEnabled: false))
            }
            return simulation.runReceipt()
        }
        #expect(run() == run(), "district \(district.rawValue) not deterministic")
    }
}
