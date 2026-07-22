import SpriteKit
import UIKit

/// Resolves validated catalog textures and returns nil when an asset is absent.
/// Callers must retain deterministic shape-node fallbacks until production
/// binaries pass the documented intake gates.
enum TextureAssetLoader {
    static func sprite(named name: String, size: CGSize? = nil) -> SKSpriteNode? {
        guard let image = UIImage(named: name) else { return nil }
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        let node = SKSpriteNode(texture: texture)
        if let size { node.size = size }
        return node
    }
}
