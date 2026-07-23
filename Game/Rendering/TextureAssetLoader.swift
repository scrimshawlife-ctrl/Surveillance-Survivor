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

    static func sprite(named name: String, size: CGSize? = nil) -> SKSpriteNode? {
        guard let image = image(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        let node = SKSpriteNode(texture: texture)
        node.userData = NSMutableDictionary(dictionary: ["asset": name])
        if let size { node.size = size }
        return node
    }
}
