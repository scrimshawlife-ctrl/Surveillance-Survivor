import CoreGraphics
import Testing
@testable import SurveillanceSurvivor

@Test func virtualStickClampsToUnitMagnitude() {
    var stick = VirtualStick(radius: 50)
    stick.begin(at: .zero)

    let movement = stick.move(to: CGPoint(x: 100, y: 0))

    #expect(movement.x == 1)
    #expect(movement.y == 0)
    #expect(stick.knob == CGPoint(x: 50, y: 0))
}

@Test func virtualStickResetsCompletely() {
    var stick = VirtualStick(radius: 50)
    stick.begin(at: CGPoint(x: 10, y: 10))
    _ = stick.move(to: CGPoint(x: 20, y: 20))

    stick.end()

    #expect(stick.origin == nil)
    #expect(stick.knob == nil)
}
