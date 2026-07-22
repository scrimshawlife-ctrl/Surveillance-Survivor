public enum SuspicionTier: Int, Codable, CaseIterable, Sendable {
    case backgroundNoise
    case personOfInterest
    case patternDetected
    case coordinatedResponse
    case narrativeLock
    case totalVisibility
}
