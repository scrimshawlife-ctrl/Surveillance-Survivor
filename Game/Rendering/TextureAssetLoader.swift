import SpriteKit
import UIKit

/// Resolves validated catalog textures and returns nil when an asset is absent.
/// Callers must retain deterministic shape-node fallbacks until production
/// binaries pass the documented intake gates.
@MainActor
enum TextureAssetLoader {
    static func image(named name: String) -> UIImage? {
        UIImage(named: name)
    }

    static func isAvailable(_ name: String) -> Bool {
        image(named: name) != nil
    }

    static func sprite(named name: String, size: CGSize? = nil, anchor: CGPoint? = nil) -> SKSpriteNode? {
        guard let image = image(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        let node = SKSpriteNode(texture: texture)
        node.userData = NSMutableDictionary(dictionary: ["asset": name])
        if let size { node.size = size }
        if let anchor { node.anchorPoint = anchor }
        return node
    }

    static func sprite(role: VisualAssetMap.Role) -> SKSpriteNode? {
        let entry = VisualAssetMap.entry(role)
        return sprite(named: entry.assetName, size: entry.displaySize, anchor: entry.anchor)
    }

    /// Availability report for the full visual map (used by tests and diagnostics).
    static func availabilityReport() -> [(name: String, required: Bool, available: Bool)] {
        VisualAssetMap.entries.map { entry in
            (entry.assetName, entry.requiredForMVP, isAvailable(entry.assetName))
        }
    }

    static func missingRequiredAssets() -> [String] {
        availabilityReport()
            .filter { $0.required && !$0.available }
            .map(\.name)
    }
}
