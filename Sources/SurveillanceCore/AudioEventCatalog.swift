import Foundation

/// Logical audio cue identity. Asset files are optional until an approved bank lands.
public struct AudioCueID: RawRepresentable, Hashable, Codable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
}

public enum AudioBus: String, Codable, Equatable, Sendable {
    case sfx
    case ui
    case music
}

public enum AudioCategory: String, Codable, Equatable, CaseIterable, Sendable {
    case combat
    case feedback
    case ui
    case stinger
}

public struct AudioTrigger: Codable, Equatable, Sendable {
    public let kind: RunEvent.Kind
    /// Optional substring match against `RunEvent.message` (e.g. cameraPole).
    public let messageContains: String?

    public init(kind: RunEvent.Kind, messageContains: String? = nil) {
        self.kind = kind
        self.messageContains = messageContains
    }

    public func matches(_ event: RunEvent) -> Bool {
        guard event.kind == kind else { return false }
        guard let needle = messageContains else { return true }
        return event.message.localizedCaseInsensitiveContains(needle)
    }
}

public struct AudioCueDefinition: Codable, Equatable, Sendable {
    public let id: AudioCueID
    public let assetName: String
    public let category: AudioCategory
    public let priority: Int
    public let cooldownTicks: UInt64
    public let gain: Double
    public let bus: AudioBus
    public let triggers: [AudioTrigger]

    public var isValid: Bool {
        !id.rawValue.isEmpty
            && !assetName.isEmpty
            && priority >= 0
            && gain >= 0
            && gain <= 1.5
            && !triggers.isEmpty
    }
}

/// Catalog-only adaptive audio rules. Stems may be missing; never invent system-sound playback.
public struct AdaptiveAudioHook: Codable, Equatable, Sendable {
    public let id: String
    public let kind: String
    public let note: String
    public let stemStatus: String
    public let appliesToCategories: [String]?
    public let gainByTier: [String: Double]?
    public let districtId: String?
    public let motifAssetName: String?
    public let triggerCueId: String?

    public var isValid: Bool {
        guard !id.isEmpty, !kind.isEmpty, !note.isEmpty, !stemStatus.isEmpty else { return false }
        if let categories = appliesToCategories {
            let known = Set(AudioCategory.allCases.map(\.rawValue))
            guard categories.allSatisfy({ known.contains($0) }) else { return false }
        }
        if let gains = gainByTier {
            for (key, value) in gains {
                guard let tier = Int(key), (0...SuspicionTier.allCases.count - 1).contains(tier) else {
                    return false
                }
                guard value.isFinite, value >= 0, value <= 4 else { return false }
            }
        }
        return true
    }
}

public struct AudioEventCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let schemaId: String?
    public let adaptiveHooks: [AdaptiveAudioHook]
    public let cues: [AudioCueDefinition]

    public static let currentSchemaVersion = 1
    public static let expectedSchemaId = "surveillance-survivor/audio_events"
    public static let bundled: AudioEventCatalog = {
        do { return try loadBundled() }
        catch { preconditionFailure("Invalid bundled audio event catalog: \(error)") }
    }()

    public static func loadBundled() throws -> AudioEventCatalog {
        guard let url = contentBundle.url(forResource: "audio_events", withExtension: "json", subdirectory: "Content")
            ?? contentBundle.url(forResource: "audio_events", withExtension: "json") else {
            throw AudioEventCatalogError.missingResource
        }
        let catalog = try JSONDecoder().decode(AudioEventCatalog.self, from: Data(contentsOf: url))
        try catalog.validate()
        return catalog
    }

    public func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw AudioEventCatalogError.unsupportedSchema(schemaVersion)
        }
        if let schemaId, schemaId != Self.expectedSchemaId {
            throw AudioEventCatalogError.invalidDefinition
        }
        guard !cues.isEmpty else { throw AudioEventCatalogError.emptyCatalog }
        guard Set(cues.map(\.id)).count == cues.count else { throw AudioEventCatalogError.duplicateCueID }
        guard cues.allSatisfy(\.isValid) else { throw AudioEventCatalogError.invalidDefinition }
        guard adaptiveHooks.allSatisfy(\.isValid) else { throw AudioEventCatalogError.invalidDefinition }
        guard Set(adaptiveHooks.map(\.id)).count == adaptiveHooks.count else {
            throw AudioEventCatalogError.duplicateCueID
        }
        // Adaptive hooks may reference cue ids; if set, they must exist.
        let cueIDs = Set(cues.map(\.id.rawValue))
        for hook in adaptiveHooks {
            if let trigger = hook.triggerCueId, !cueIDs.contains(trigger) {
                throw AudioEventCatalogError.invalidDefinition
            }
        }
    }

    public func matchingCues(for event: RunEvent) -> [AudioCueDefinition] {
        cues.filter { cue in cue.triggers.contains { $0.matches(event) } }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                return lhs.id.rawValue < rhs.id.rawValue
            }
    }

    /// Explicit adaptive gain multiplier for a category at a suspicion tier (catalog truth).
    public func adaptiveGain(category: AudioCategory, tier: SuspicionTier) -> Double {
        let hooks = adaptiveHooks.filter { $0.kind == "gainScaleBySuspicionTier" }
        guard let hook = hooks.first else { return 1 }
        let categories = hook.appliesToCategories ?? []
        guard categories.isEmpty || categories.contains(category.rawValue) else { return 1 }
        return hook.gainByTier?["\(tier.rawValue)"] ?? 1
    }
}

public enum AudioEventCatalogError: Error, Equatable, Sendable {
    case missingResource
    case unsupportedSchema(Int)
    case emptyCatalog
    case duplicateCueID
    case invalidDefinition
}

/// Resolves run events into cue requests with simple cooldown gating.
/// Does not load or play audio files — that stays in the app layer once assets exist.
public struct AudioCueResolver: Sendable {
    public struct Request: Equatable, Sendable {
        public let cueID: AudioCueID
        public let assetName: String
        public let bus: AudioBus
        public let gain: Double
        public let priority: Int
        public let sourceEvent: RunEvent.Kind
    }

    private let catalog: AudioEventCatalog
    private var lastFiredTick: [AudioCueID: UInt64] = [:]

    public init(catalog: AudioEventCatalog = .bundled) {
        self.catalog = catalog
    }

    public mutating func resolve(
        events: [RunEvent],
        atTick tick: UInt64,
        suspicionTier: SuspicionTier = .backgroundNoise
    ) -> [Request] {
        var requests: [Request] = []
        for event in events {
            for cue in catalog.matchingCues(for: event) {
                if let last = lastFiredTick[cue.id], tick &- last < cue.cooldownTicks {
                    continue
                }
                lastFiredTick[cue.id] = tick
                let adaptive = catalog.adaptiveGain(category: cue.category, tier: suspicionTier)
                requests.append(
                    Request(
                        cueID: cue.id,
                        assetName: cue.assetName,
                        bus: cue.bus,
                        gain: cue.gain * adaptive,
                        priority: cue.priority,
                        sourceEvent: event.kind
                    )
                )
            }
        }
        return requests.sorted {
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            return $0.cueID.rawValue < $1.cueID.rawValue
        }
    }
}
