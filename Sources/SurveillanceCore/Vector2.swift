import Foundation

public struct Vector2: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0, y: Double = 0) { self.x = x; self.y = y }
    public var magnitude: Double { sqrt(x * x + y * y) }
    public func normalized() -> Vector2 {
        let m = magnitude
        return m > 0 ? Vector2(x: x / m, y: y / m) : .init()
    }
}
