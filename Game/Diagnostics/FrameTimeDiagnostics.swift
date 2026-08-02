import Foundation
import SurveillanceCore

struct FrameTimeSummary: Codable, Equatable, Sendable {
    var sampleCount: Int
    var p50: TimeInterval
    var p95: TimeInterval
    var maximum: TimeInterval

    static let empty = FrameTimeSummary(sampleCount: 0, p50: 0, p95: 0, maximum: 0)
}

struct DeviceRunReceipt: Codable, Equatable, Sendable {
    var core: RunReceipt
    var frameTimes: [TimeInterval]
    var frameTimeSummary: FrameTimeSummary
}

struct FrameTimeDiagnostics: Sendable {
    static let maximumSamples = 7_200
    private(set) var samples: [TimeInterval] = []

    /// Only attribute samples to the combat/playfield loop. Pause, upgrade drafts,
    /// and post-extract summary UI produce multi-frame hitches that inflated
    /// receipt max (~200ms) without reflecting steady-state combat pacing.
    static func shouldRecordGameplaySample(
        isRunPaused: Bool,
        hasPendingUpgradeDraft: Bool,
        runCompleted: Bool
    ) -> Bool {
        !isRunPaused && !hasPendingUpgradeDraft && !runCompleted
    }

    mutating func record(_ frameTime: TimeInterval) {
        guard frameTime.isFinite, frameTime >= 0 else { return }
        if samples.count == Self.maximumSamples { samples.removeFirst() }
        samples.append(frameTime)
    }

    func summary() -> FrameTimeSummary {
        guard !samples.isEmpty else { return .empty }
        let ordered = samples.sorted()
        func percentile(_ fraction: Double) -> TimeInterval {
            ordered[Int((Double(ordered.count - 1) * fraction).rounded(.up))]
        }
        return FrameTimeSummary(
            sampleCount: samples.count,
            p50: percentile(0.50),
            p95: percentile(0.95),
            maximum: ordered[ordered.count - 1]
        )
    }
}
