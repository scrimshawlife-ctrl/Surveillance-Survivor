import Foundation

/// Inventory-first multi-frame probe: `base`, `base_2`, … `base_N`.
/// Same naming contract as `PlayerAtlasManifest`. When only the base stem exists
/// (current guards/boss), returns the base name every frame — no new art required.
/// Presentation-only; never touches simulation authority.
@MainActor
enum OptionalSpriteFrameCycle {
    private static var frameCountCache: [String: Int] = [:]

    /// How many consecutive frames exist for `base` (1 = still only; 0 = missing base).
    static func availableFrameCount(base: String, maxFrames: Int = 4) -> Int {
        if let cached = frameCountCache[base] { return cached }
        guard TextureAssetLoader.isAvailable(base) else {
            frameCountCache[base] = 0
            return 0
        }
        var count = 1
        if maxFrames >= 2 {
            for n in 2...maxFrames {
                if TextureAssetLoader.isAvailable("\(base)_\(n)") {
                    count = n
                } else {
                    break
                }
            }
        }
        frameCountCache[base] = count
        return count
    }

    /// Resolve the texture stem for presentation time. Falls back to `base` when
    /// no multi-frame bank is attached (inventory-first REUSE).
    static func frameName(
        base: String,
        at time: TimeInterval,
        frameDuration: TimeInterval = 0.14,
        maxFrames: Int = 4
    ) -> String {
        let count = availableFrameCount(base: base, maxFrames: maxFrames)
        guard count > 1 else { return base }
        let period = frameDuration * Double(count)
        let t = period > 0 ? time.truncatingRemainder(dividingBy: period) : 0
        let index = min(count - 1, max(0, Int(t / frameDuration)))
        if index == 0 { return base }
        return "\(base)_\(index + 1)"
    }

    /// Test / diagnostics only.
    static func resetCacheForTesting() {
        frameCountCache.removeAll()
    }
}
