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
        let byID = app.descendants(matching: .any)[identifier]
        if byID.waitForExistence(timeout: 3) { return byID }
        let byLabel = app.buttons[label]
        if byLabel.waitForExistence(timeout: 2) { return byLabel }
        // Last resort: any element with the label (icon-only buttons).
        return app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
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
        pause = control(in: app, identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(
            pause.waitForExistence(timeout: 20),
            "Pause control missing after relaunch. Hierarchy:\n\(app.debugDescription)"
        )
        return app
    }

    @MainActor
    func testAppLaunchesToGameplayChrome() {
        let app = launchUntilPauseVisible()
        defer { app.terminate() }

        let settings = control(in: app, identifier: "open-settings", label: "Open accessibility settings")
        XCTAssertTrue(
            settings.waitForExistence(timeout: 5),
            "Settings control missing. Hierarchy:\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testPauseAndResumeRoundTrip() {
        let app = launchUntilPauseVisible()
        defer { app.terminate() }

        let pause = control(in: app, identifier: "pause-run", label: "Pause run")
        pause.tap()

        // Prefer the explicit button label; container views can inherit the resume id.
        let resume = app.buttons["RESUME RUN"]
        XCTAssertTrue(
            resume.waitForExistence(timeout: 12),
            "Resume should appear after manual pause. Hierarchy:\n\(app.debugDescription)"
        )
        resume.tap()

        XCTAssertTrue(
            control(in: app, identifier: "pause-run", label: "Pause run").waitForExistence(timeout: 12),
            "Pause should return after resume. Hierarchy:\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testSettingsSheetOpensAndDismisses() {
        let app = launchUntilPauseVisible()
        defer { app.terminate() }

        let settings = control(in: app, identifier: "open-settings", label: "Open accessibility settings")
        XCTAssertTrue(settings.waitForExistence(timeout: 8), app.debugDescription)
        settings.tap()

        let nav = app.navigationBars["Accessibility"]
        XCTAssertTrue(
            nav.waitForExistence(timeout: 12),
            "Accessibility settings sheet should present. Hierarchy:\n\(app.debugDescription)"
        )

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 8))
        done.tap()

        let pause = control(in: app, identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(
            pause.waitForExistence(timeout: 12),
            "Gameplay chrome returns after settings dismiss. Hierarchy:\n\(app.debugDescription)"
        )
    }
}
