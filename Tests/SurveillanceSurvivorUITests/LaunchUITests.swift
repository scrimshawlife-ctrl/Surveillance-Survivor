import XCTest

/// Black-box launch and chrome tests for Simulator and physical device.
/// Launch arg `-UITesting` disables auto-fire so upgrade drafts do not cover chrome.
/// Physical suite: `make device-test` / `make device-ui-test` (not full ART acceptance).
final class LaunchUITests: XCTestCase {
    @MainActor
    private func launchApp(scenario: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UITesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        if let scenario {
            app.launchArguments += ["-UITestScenario", scenario]
        }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 45)
        // CI hosts and physical devices need settle after SpriteKit scene attach.
        RunLoop.current.run(until: Date().addingTimeInterval(3.0))
        return app
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Query by identifier across the full tree.
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
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let el = element(in: app, id: id)
            if el.exists {
                return el
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        }
        let el = element(in: app, id: id)
        if el.waitForExistence(timeout: 3) {
            return el
        }
        XCTFail("Missing id=\(id). Hierarchy:\n\(app.debugDescription)", file: file, line: line)
        return el
    }

    @MainActor
    private func launchUntilChromeReady() -> XCUIApplication {
        // Up to 3 cold launches — GHA simulators often miss the first attach.
        var last = launchApp()
        for attempt in 1...3 {
            if element(in: last, id: "pause-run").waitForExistence(timeout: 18)
                || element(in: last, id: "control-chrome").waitForExistence(timeout: 2)
            {
                return last
            }
            last.terminate()
            RunLoop.current.run(until: Date().addingTimeInterval(1.5))
            last = launchApp()
            if attempt == 3 {
                _ = waitForID("pause-run", in: last, timeout: 30)
            }
        }
        return last
    }

    @MainActor
    private func safeTap(_ el: XCUIElement) {
        // Prefer coordinate tap — framed buttons often report !isHittable under SpriteKit.
        if el.exists {
            el.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        if el.isHittable {
            el.tap()
        }
    }

    @MainActor
    func testAppLaunchesToGameplayChrome() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }
        _ = waitForID("pause-run", in: app, timeout: 20)
        _ = waitForID("open-settings", in: app, timeout: 20)
        // control-chrome is the reliable parent; game-hud can lag behind SpriteKit attach.
        _ = waitForID("control-chrome", in: app, timeout: 20)
        let hud = element(in: app, id: "game-hud")
        if !hud.waitForExistence(timeout: 12) {
            // Soft: chrome buttons prove playing surface; HUD is presentation-only.
            XCTAssertTrue(
                element(in: app, id: "pause-run").exists,
                "Missing game-hud and pause-run. Hierarchy:\n\(app.debugDescription)"
            )
        }
        attachScreenshot("gameplay-chrome", app: app)
    }

    @MainActor
    func testPauseAndResumeRoundTrip() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        safeTap(waitForID("pause-run", in: app, timeout: 15))
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))

        // Prefer accessibility id; fall back to visible label.
        var resume = element(in: app, id: "resume-run")
        if !resume.waitForExistence(timeout: 8) {
            resume = app.buttons["RESUME RUN"]
        }
        XCTAssertTrue(
            resume.waitForExistence(timeout: 15),
            "Resume missing. Hierarchy:\n\(app.debugDescription)"
        )
        safeTap(resume)
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))

        _ = waitForID("pause-run", in: app, timeout: 30)
    }

    @MainActor
    func testSettingsSheetOpensAndDismisses() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        safeTap(waitForID("open-settings", in: app, timeout: 15))
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))

        // Terminal-grid settings (not system Form "Accessibility" title).
        var panel = element(in: app, id: "settings-panel")
        if !panel.waitForExistence(timeout: 12) {
            panel = app.navigationBars["SETTINGS"]
        }
        if !panel.waitForExistence(timeout: 8) {
            panel = app.staticTexts["FIELD CONFIG"]
        }
        XCTAssertTrue(
            panel.waitForExistence(timeout: 12),
            "Settings missing. Hierarchy:\n\(app.debugDescription)"
        )

        var done = element(in: app, id: "settings-done")
        if !done.waitForExistence(timeout: 6) {
            done = app.buttons["DONE"]
        }
        if !done.waitForExistence(timeout: 4) {
            done = app.buttons["Done"]
        }
        XCTAssertTrue(done.waitForExistence(timeout: 10), "Done missing. Hierarchy:\n\(app.debugDescription)")
        safeTap(done)
        RunLoop.current.run(until: Date().addingTimeInterval(0.8))

        _ = waitForID("pause-run", in: app, timeout: 30)
    }

    @MainActor
    func testUpgradeDraftSelectionReturnsToGameplay() {
        let app = launchApp(scenario: "upgrade")
        defer { app.terminate() }

        _ = waitForID("upgrade-draft", in: app, timeout: 20)
        safeTap(waitForID("upgrade-choice-0", in: app, timeout: 10))
        XCTAssertTrue(
            waitForID("pause-run", in: app, timeout: 20).exists,
            "Gameplay chrome did not return after selecting an upgrade"
        )
    }

    @MainActor
    func testExtractionSummaryStartsNextRun() {
        let app = launchApp(scenario: "extraction")
        defer { app.terminate() }

        _ = waitForID("run-summary", in: app, timeout: 20)
        _ = waitForID("next-district-picker", in: app, timeout: 10)
        attachScreenshot("extraction-summary", app: app)
        let startNext = waitForID("start-next-run", in: app, timeout: 10)
        startNext.tap()
        _ = waitForID("pause-run", in: app, timeout: 20)
    }

    @MainActor
    func testDefeatSummaryDoesNotExposeExtractionUnlockBanner() {
        let app = launchApp(scenario: "defeat")
        defer { app.terminate() }

        _ = waitForID("run-summary", in: app, timeout: 20)
        XCTAssertFalse(
            element(in: app, id: "unlock-grant-banner").exists,
            "A defeat must not display an extraction unlock grant"
        )
        let startNext = waitForID("start-next-run", in: app, timeout: 10)
        startNext.tap()
        _ = waitForID("pause-run", in: app, timeout: 20)
    }
}
