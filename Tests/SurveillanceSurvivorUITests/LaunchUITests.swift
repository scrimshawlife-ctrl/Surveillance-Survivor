import XCTest

/// Black-box launch and chrome tests against the iOS Simulator.
/// Launch arg `-UITesting` disables auto-fire so upgrade drafts do not cover chrome.
///
/// XCUIApplication is main-actor isolated under Swift 6. XCTest's setUp/tearDown
/// overrides are not, so each test method is `@MainActor` and owns its app instance.
final class LaunchUITests: XCTestCase {
    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UITesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 15)
        // Give SpringBoard / first layout a moment on cold CI simulators.
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        return app
    }

    /// Prefer stable identifiers; fall back to accessibility labels if SwiftUI
    /// flattens identifiers onto a container.
    @MainActor
    private func control(in app: XCUIApplication, identifier: String, label: String) -> XCUIElement {
        let byID = app.buttons[identifier]
        if byID.waitForExistence(timeout: 2) { return byID }
        let anyID = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        if anyID.waitForExistence(timeout: 2) { return anyID }
        let byLabel = app.buttons[label]
        if byLabel.waitForExistence(timeout: 2) { return byLabel }
        return app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    @MainActor
    private func waitForControl(
        in app: XCUIApplication,
        identifier: String,
        label: String,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        var element = control(in: app, identifier: identifier, label: label)
        while Date() < deadline {
            if element.exists { return element }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
            element = control(in: app, identifier: identifier, label: label)
        }
        XCTFail(
            "Missing \(identifier)/\(label). Hierarchy:\n\(app.debugDescription)",
            file: file,
            line: line
        )
        return element
    }

    /// Wait for pause chrome, relaunching once if the first launch is too cold.
    @MainActor
    private func launchUntilPauseVisible() -> XCUIApplication {
        var app = launchApp()
        var pause = control(in: app, identifier: "pause-run", label: "Pause run")
        if pause.waitForExistence(timeout: 15) {
            return app
        }
        app.terminate()
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        app = launchApp()
        _ = waitForControl(in: app, identifier: "pause-run", label: "Pause run", timeout: 20)
        return app
    }

    @MainActor
    private func safeTap(_ element: XCUIElement) {
        // Re-resolve when the first query is stale after layout transitions.
        if element.waitForExistence(timeout: 5), element.isHittable {
            element.tap()
            return
        }
        let coord = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coord.tap()
    }

    @MainActor
    func testAppLaunchesToGameplayChrome() {
        let app = launchUntilPauseVisible()
        defer { app.terminate() }

        _ = waitForControl(
            in: app,
            identifier: "open-settings",
            label: "Open accessibility settings",
            timeout: 8
        )
    }

    @MainActor
    func testPauseAndResumeRoundTrip() {
        let app = launchUntilPauseVisible()
        defer { app.terminate() }

        let pause = waitForControl(in: app, identifier: "pause-run", label: "Pause run", timeout: 8)
        safeTap(pause)

        // Prefer the explicit button label; container views can inherit the resume id.
        let resume = app.buttons["RESUME RUN"]
        XCTAssertTrue(
            resume.waitForExistence(timeout: 12),
            "Resume should appear after manual pause. Hierarchy:\n\(app.debugDescription)"
        )
        safeTap(resume)

        // Layout rebuild after unpause can lag on CI; poll rather than single query.
        _ = waitForControl(in: app, identifier: "pause-run", label: "Pause run", timeout: 20)
    }

    @MainActor
    func testSettingsSheetOpensAndDismisses() {
        let app = launchUntilPauseVisible()
        defer { app.terminate() }

        let settings = waitForControl(
            in: app,
            identifier: "open-settings",
            label: "Open accessibility settings",
            timeout: 8
        )
        safeTap(settings)

        let nav = app.navigationBars["Accessibility"]
        XCTAssertTrue(
            nav.waitForExistence(timeout: 12),
            "Accessibility settings sheet should present. Hierarchy:\n\(app.debugDescription)"
        )

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 8))
        safeTap(done)

        _ = waitForControl(in: app, identifier: "pause-run", label: "Pause run", timeout: 20)
    }
}
