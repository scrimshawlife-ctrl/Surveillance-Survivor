import AVFoundation
import Foundation
import SurveillanceCore

/// Immutable lookup table for runtime-approved audio assets discovered in the app bundle.
/// Missing binaries intentionally resolve to silence; discovery never fabricates placeholders.
struct AudioAssetBank: Equatable {
    struct Entry: Equatable {
        let assetName: String
        let url: URL
    }

    static let supportedExtensions: Set<String> = ["wav", "m4a", "caf", "aiff", "aif", "mp3"]
    static let runtimeSubdirectories = [
        "Audio/Delivery/Runtime",
        "Audio/Masters/Runtime",
        "Audio"
    ]

    private let entriesByAssetName: [String: Entry]

    var availableAssets: Set<String> { Set(entriesByAssetName.keys) }
    var entries: [Entry] { entriesByAssetName.values.sorted { $0.assetName < $1.assetName } }

    init(entries: [Entry]) {
        var unique: [String: Entry] = [:]
        for entry in entries where unique[entry.assetName] == nil {
            unique[entry.assetName] = entry
        }
        entriesByAssetName = unique
    }

    init(bundle: Bundle = .main, catalog: AudioEventCatalog = .bundled) {
        let approvedNames = Set(catalog.cues.map(\.assetName))
        var discovered: [Entry] = []
        for assetName in approvedNames.sorted() {
            if let url = Self.firstURL(forAssetName: assetName, in: bundle) {
                discovered.append(Entry(assetName: assetName, url: url))
            }
        }
        self.init(entries: discovered)
    }

    func entry(for assetName: String) -> Entry? {
        entriesByAssetName[assetName]
    }

    private static func firstURL(forAssetName assetName: String, in bundle: Bundle) -> URL? {
        for subdirectory in runtimeSubdirectories {
            for ext in supportedExtensions.sorted() {
                if let url = bundle.url(forResource: assetName, withExtension: ext, subdirectory: subdirectory) {
                    return url
                }
            }
        }
        for ext in supportedExtensions.sorted() {
            if let url = bundle.url(forResource: assetName, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

@MainActor
protocol AudioPlaybackBackend: AnyObject {
    func play(url: URL, gain: Double)
}

@MainActor
final class AVFoundationAudioPlaybackBackend: AudioPlaybackBackend {
    private var players: [URL: AVAudioPlayer] = [:]

    func play(url: URL, gain: Double) {
        do {
            let player: AVAudioPlayer
            if let existing = players[url] {
                player = existing
            } else {
                player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                players[url] = player
            }
            player.currentTime = 0
            player.volume = Float(max(0, min(gain, 1.5)))
            player.play()
        } catch {
            // Intake or decode failure must be silent. Asset correctness is covered by tests/checks.
            players[url] = nil
        }
    }
}
