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
        _ = app.wait(for: .runningForeground, timeout: 8)
        return app
    }

    /// Prefer stable identifiers; fall back to accessibility labels if SwiftUI
    /// flattens identifiers onto a container.
    @MainActor
    private func control(in app: XCUIApplication, identifier: String, label: String) -> XCUIElement {
        let byID = app.descendants(matching: .any)[identifier]
        if byID.waitForExistence(timeout: 2) { return byID }
        return app.buttons[label]
    }

    @MainActor
    func testAppLaunchesToGameplayChrome() {
        let app = launchApp()
        defer { app.terminate() }

        let pause = control(in: app, identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(
            pause.waitForExistence(timeout: 12),
            "Pause control should be visible while playing. Hierarchy:\n\(app.debugDescription)"
        )
        let settings = control(in: app, identifier: "open-settings", label: "Open accessibility settings")
        XCTAssertTrue(settings.exists)
    }

    @MainActor
    func testPauseAndResumeRoundTrip() {
        let app = launchApp()
        defer { app.terminate() }

        let pause = control(in: app, identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(pause.waitForExistence(timeout: 12), app.debugDescription)
        pause.tap()

        // Prefer the explicit button label; container views can inherit the resume id.
        let resume = app.buttons["RESUME RUN"]
        XCTAssertTrue(
            resume.waitForExistence(timeout: 8),
            "Resume should appear after manual pause. Hierarchy:\n\(app.debugDescription)"
        )
        resume.tap()

        XCTAssertTrue(
            control(in: app, identifier: "pause-run", label: "Pause run").waitForExistence(timeout: 8),
            "Pause should return after resume"
        )
    }

    @MainActor
    func testSettingsSheetOpensAndDismisses() {
        let app = launchApp()
        defer { app.terminate() }

        let settings = control(in: app, identifier: "open-settings", label: "Open accessibility settings")
        XCTAssertTrue(settings.waitForExistence(timeout: 12), app.debugDescription)
        settings.tap()

        let nav = app.navigationBars["Accessibility"]
        XCTAssertTrue(
            nav.waitForExistence(timeout: 8),
            "Accessibility settings sheet should present. Hierarchy:\n\(app.debugDescription)"
        )

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5))
        done.tap()

        let pause = control(in: app, identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(pause.waitForExistence(timeout: 8), "Gameplay chrome returns after settings dismiss")
    }
}
