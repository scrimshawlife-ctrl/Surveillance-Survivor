import XCTest

/// Black-box launch and chrome tests against the iOS Simulator.
/// Launch arg `-UITesting` disables auto-fire so upgrade drafts do not cover chrome.
final class LaunchUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-UITesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 8)
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    /// Prefer stable identifiers; fall back to accessibility labels if SwiftUI
    /// flattens identifiers onto a container.
    private func control(identifier: String, label: String) -> XCUIElement {
        let byID = app.descendants(matching: .any)[identifier]
        if byID.waitForExistence(timeout: 2) { return byID }
        return app.buttons[label]
    }

    func testAppLaunchesToGameplayChrome() {
        let pause = control(identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(
            pause.waitForExistence(timeout: 12),
            "Pause control should be visible while playing. Hierarchy:\n\(app.debugDescription)"
        )
        let settings = control(identifier: "open-settings", label: "Open accessibility settings")
        XCTAssertTrue(settings.exists)
    }

    func testPauseAndResumeRoundTrip() {
        let pause = control(identifier: "pause-run", label: "Pause run")
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
            control(identifier: "pause-run", label: "Pause run").waitForExistence(timeout: 8),
            "Pause should return after resume"
        )
    }

    func testSettingsSheetOpensAndDismisses() {
        let settings = control(identifier: "open-settings", label: "Open accessibility settings")
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

        let pause = control(identifier: "pause-run", label: "Pause run")
        XCTAssertTrue(pause.waitForExistence(timeout: 8), "Gameplay chrome returns after settings dismiss")
    }
}
