import Foundation

/// Which looping assets a given run state should be sounding.
///
/// Ambience, music, and the extraction overlay are **state**, not events: they
/// persist across ticks and change when the run's situation changes. Deriving them
/// from `RunState` is the "explicit scene-state projection" that
/// `docs/AUDIO_AGENT_EXECUTION.md` permits for reserved assets — it adds no
/// simulation state and cannot alter gameplay.
public struct AudioScene: Equatable, Sendable {
    /// Shared district bed, the foundation the city bed layers on top of.
    public var foundation: String?
    /// City identity bed, above the foundation.
    public var ambience: String?
    /// Run loop, boss loop, or a boss phase loop.
    public var music: String?
    /// Blind Spot field loop while extraction is open.
    public var overlay: String?
    /// 1-based boss phase when the active district authors phases, else nil.
    public var bossPhase: Int?

    public init(foundation: String? = nil, ambience: String? = nil, music: String? = nil,
                overlay: String? = nil, bossPhase: Int? = nil) {
        self.foundation = foundation
        self.ambience = ambience
        self.music = music
        self.overlay = overlay
        self.bossPhase = bossPhase
    }
}

/// Per-district looping asset assignments, loaded from `audio_events.json`.
public struct AudioSceneDefinition: Codable, Equatable, Sendable {
    public let districtId: DistrictID
    /// Reusable foundation bed shared between districts of similar character.
    public let foundationAsset: String?
    public let ambienceAsset: String
    public let runAsset: String
    /// Single boss loop, for districts without authored phases.
    public let bossAsset: String?
    /// Ordered phase loops, used in place of `bossAsset` when present.
    public let bossPhaseAssets: [String]?

    var isValid: Bool {
        guard !ambienceAsset.isEmpty, !runAsset.isEmpty else { return false }
        if let phases = bossPhaseAssets {
            return !phases.isEmpty && phases.allSatisfy { !$0.isEmpty }
        }
        return !(bossAsset ?? "").isEmpty
    }
}

public struct AudioSceneCatalog: Codable, Equatable, Sendable {
    public let overlayExtractionAsset: String?
    public let scanSweepAsset: String?
    public let districts: [AudioSceneDefinition]

    public func definition(for district: DistrictID) -> AudioSceneDefinition? {
        districts.first { $0.districtId == district }
    }

    public func validate() throws {
        guard districts.count == DistrictID.allCases.count,
              Set(districts.map(\.districtId)) == Set(DistrictID.allCases) else {
            throw AudioEventCatalogError.incompleteCatalog
        }
        guard districts.allSatisfy(\.isValid) else { throw AudioEventCatalogError.invalidDefinition }
    }
}

public enum AudioSceneProjector {
    /// Projects the looping audio scene for a run state.
    ///
    /// Boss phases are derived from the authority's **remaining health fraction**
    /// rather than from new simulation state, so a phased district steps through
    /// its loops as the fight progresses without the deterministic core gaining a
    /// phase concept it does not already have.
    public static func scene(for state: RunState, catalog: AudioSceneCatalog) -> AudioScene {
        guard let definition = catalog.definition(for: state.district) else { return AudioScene() }

        var scene = AudioScene(foundation: definition.foundationAsset,
                               ambience: definition.ambienceAsset)

        if state.runCompleted {
            // Nothing loops once the run is over; the completion stinger carries it.
            return AudioScene()
        }

        let boss = state.entities.first { $0.kind == .boss && $0.health > 0 }
        if let boss {
            if let phases = definition.bossPhaseAssets, !phases.isEmpty {
                let index = phaseIndex(for: boss, phaseCount: phases.count)
                scene.music = phases[index]
                scene.bossPhase = index + 1
            } else {
                scene.music = definition.bossAsset
            }
        } else {
            scene.music = definition.runAsset
        }

        if state.extractionOpen {
            scene.overlay = catalog.overlayExtractionAsset
        }
        return scene
    }

    /// Splits the fight into equal health bands, first phase at full health.
    static func phaseIndex(for boss: Entity, phaseCount: Int) -> Int {
        guard phaseCount > 1 else { return 0 }
        let maximum = BossCatalog.bundled.shiftManagerHealth
        guard maximum > 0 else { return 0 }
        // Health can exceed the catalog baseline via district scaling, so clamp.
        let fraction = min(1.0, max(0.0, boss.health / maximum))
        let step = 1.0 / Double(phaseCount)
        let index = Int((1.0 - fraction) / step)
        return min(phaseCount - 1, max(0, index))
    }
}
