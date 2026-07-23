import XCTest

/// Black-box launch and chrome tests against the iOS Simulator.
/// Launch arg `-UITesting` disables auto-fire so upgrade drafts do not cover chrome.
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
        _ = app.wait(for: .runningForeground, timeout: 20)
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        return app
    }

    /// Query by identifier across the full tree. Prefer buttons, then any.
    @MainActor
    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).element(boundBy: 0)
    }

    @MainActor
    private func waitForID(
        _ id: String,
        in app: XCUIApplication,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let el = element(in: app, id: id)
        let ok = el.waitForExistence(timeout: timeout)
        if !ok {
            // One more full-tree scan after a short settle — CI layout can lag.
            RunLoop.current.run(until: Date().addingTimeInterval(1.0))
            let retry = element(in: app, id: id)
            if retry.waitForExistence(timeout: 5) {
                return retry
            }
            XCTFail("Missing id=\(id). Hierarchy:\n\(app.debugDescription)", file: file, line: line)
        }
        return el
    }

    @MainActor
    private func launchUntilChromeReady() -> XCUIApplication {
        var app = launchApp()
        if element(in: app, id: "pause-run").waitForExistence(timeout: 20) {
            return app
        }
        app.terminate()
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        app = launchApp()
        _ = waitForID("pause-run", in: app, timeout: 25)
        return app
    }

    @MainActor
    private func safeTap(_ el: XCUIElement) {
        if el.isHittable {
            el.tap()
        } else {
            el.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    @MainActor
    func testAppLaunchesToGameplayChrome() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }
        _ = waitForID("pause-run", in: app, timeout: 10)
        _ = waitForID("open-settings", in: app, timeout: 10)
        _ = waitForID("game-hud", in: app, timeout: 5)
    }

    @MainActor
    func testPauseAndResumeRoundTrip() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        safeTap(waitForID("pause-run", in: app, timeout: 10))

        let resume = app.buttons["RESUME RUN"]
        XCTAssertTrue(
            resume.waitForExistence(timeout: 15),
            "Resume missing. Hierarchy:\n\(app.debugDescription)"
        )
        safeTap(resume)

        _ = waitForID("pause-run", in: app, timeout: 25)
    }

    @MainActor
    func testSettingsSheetOpensAndDismisses() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        safeTap(waitForID("open-settings", in: app, timeout: 10))

        let nav = app.navigationBars["Accessibility"]
        XCTAssertTrue(
            nav.waitForExistence(timeout: 15),
            "Settings missing. Hierarchy:\n\(app.debugDescription)"
        )
        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 8))
        safeTap(done)

        _ = waitForID("pause-run", in: app, timeout: 25)
    }
}
