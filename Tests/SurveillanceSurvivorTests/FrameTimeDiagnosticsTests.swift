import Foundation
import Testing
@testable import SurveillanceSurvivor

@Test func frameTimingSummarizesPercentilesDeterministically() {
    var diagnostics = FrameTimeDiagnostics()
    [0.010, 0.016, 0.017, 0.020, 0.040].forEach { diagnostics.record($0) }

    let summary = diagnostics.summary()
    #expect(summary.sampleCount == 5)
    #expect(summary.p50 == 0.017)
    #expect(summary.p95 == 0.040)
    #expect(summary.maximum == 0.040)
}

@Test func frameTimingRetainsABoundedMostRecentWindow() {
    var diagnostics = FrameTimeDiagnostics()
    for index in 0...FrameTimeDiagnostics.maximumSamples {
        diagnostics.record(TimeInterval(index))
    }

    #expect(diagnostics.samples.count == FrameTimeDiagnostics.maximumSamples)
    #expect(diagnostics.samples.first == 1)
    #expect(diagnostics.samples.last == TimeInterval(FrameTimeDiagnostics.maximumSamples))
}
