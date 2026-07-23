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

public enum AudioCategory: String, Codable, Equatable, Sendable {
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

public struct AudioEventCatalog: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let cues: [AudioCueDefinition]

    public static let currentSchemaVersion = 1
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
        guard !cues.isEmpty else { throw AudioEventCatalogError.emptyCatalog }
        guard Set(cues.map(\.id)).count == cues.count else { throw AudioEventCatalogError.duplicateCueID }
        guard cues.allSatisfy(\.isValid) else { throw AudioEventCatalogError.invalidDefinition }
    }

    public func matchingCues(for event: RunEvent) -> [AudioCueDefinition] {
        cues.filter { cue in cue.triggers.contains { $0.matches(event) } }
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
                return lhs.id.rawValue < rhs.id.rawValue
            }
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

    public mutating func resolve(events: [RunEvent], atTick tick: UInt64) -> [Request] {
        var requests: [Request] = []
        for event in events {
            for cue in catalog.matchingCues(for: event) {
                if let last = lastFiredTick[cue.id], tick &- last < cue.cooldownTicks {
                    continue
                }
                lastFiredTick[cue.id] = tick
                requests.append(
                    Request(
                        cueID: cue.id,
                        assetName: cue.assetName,
                        bus: cue.bus,
                        gain: cue.gain,
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
