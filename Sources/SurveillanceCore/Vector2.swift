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

    public func dot(_ other: Vector2) -> Double { x * other.x + y * other.y }

    public static func + (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func - (lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func * (lhs: Vector2, rhs: Double) -> Vector2 {
        Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}
