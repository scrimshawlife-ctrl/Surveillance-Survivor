import Foundation
import Testing

/// Decodes the emulator evidence receipt schema without requiring a live simulator.
struct EmulatorEvidenceReceipt: Codable, Equatable, Sendable {
    var schemaVersion: Int
    var status: String
    var commit: String
    var swiftVersion: String?
    var xcodeVersion: String?
    var simulatorId: String
    var startedAt: String?
    var endedAt: String?
    var steps: [Step]
    var screenshot: String?
    var logFile: String?
    var notes: String?

    struct Step: Codable, Equatable, Sendable {
        var name: String
        var status: String
        var exitCode: Int?
        var durationSeconds: Double?
    }
}

@Test func emulatorReceiptSchemaDecodesFixture() throws {
    let json = """
    {
      "schemaVersion": 1,
      "status": "pass",
      "commit": "abc1234",
      "swiftVersion": "Apple Swift version 6.0",
      "xcodeVersion": "Xcode 16.0",
      "simulatorId": "SIM-ID",
      "startedAt": "2026-07-24T00:00:00Z",
      "endedAt": "2026-07-24T00:10:00Z",
      "steps": [
        {"name": "privacy-check", "status": "pass", "exitCode": 0, "durationSeconds": 0.2},
        {"name": "package-tests", "status": "pass", "exitCode": 0, "durationSeconds": 8.0}
      ],
      "screenshot": "launch.png",
      "logFile": "emulator-suite.log",
      "notes": "Simulator evidence only; not physical-device acceptance."
    }
    """.data(using: .utf8)!
    let receipt = try JSONDecoder().decode(EmulatorEvidenceReceipt.self, from: json)
    #expect(receipt.schemaVersion == 1)
    #expect(receipt.status == "pass")
    #expect(receipt.steps.count == 2)
    #expect(receipt.screenshot == "launch.png")
    #expect(receipt.notes?.contains("not physical-device") == true)
}

@Test func emulatorReceiptRejectsMissingStatus() {
    let json = """
    {"schemaVersion":1,"commit":"x","simulatorId":"y","steps":[]}
    """.data(using: .utf8)!
    #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(EmulatorEvidenceReceipt.self, from: json)
    }
}
