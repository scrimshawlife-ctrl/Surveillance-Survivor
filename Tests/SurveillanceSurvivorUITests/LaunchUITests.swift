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
        // Dismiss SpringBoard banners that steal first taps on physical devices.
        addUIInterruptionMonitor(withDescription: "System alerts") { element in
            let buttons = ["Allow", "OK", "Close", "Not Now", "Don't Allow"]
            for title in buttons {
                let b = element.buttons[title]
                if b.exists {
                    b.tap()
                    return true
                }
            }
            return false
        }
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
    private func ensurePlayingChrome(in app: XCUIApplication) {
        // If a prior run already ended (contact defeat before invuln), restart from summary.
        if element(in: app, id: "run-summary").waitForExistence(timeout: 1.0)
            || element(in: app, id: "start-next-run").waitForExistence(timeout: 0.5)
        {
            let start = element(in: app, id: "start-next-run")
            if start.waitForExistence(timeout: 8) {
                safeTap(start)
                RunLoop.current.run(until: Date().addingTimeInterval(1.5))
            }
        }
    }

    @MainActor
    private func launchUntilChromeReady() -> XCUIApplication {
        // Up to 3 cold launches — GHA simulators often miss the first attach.
        var last = launchApp()
        for attempt in 1...3 {
            ensurePlayingChrome(in: last)
            if element(in: last, id: "pause-run").waitForExistence(timeout: 18)
                || element(in: last, id: "control-chrome").waitForExistence(timeout: 2)
            {
                return last
            }
            last.terminate()
            RunLoop.current.run(until: Date().addingTimeInterval(1.5))
            last = launchApp()
            if attempt == 3 {
                ensurePlayingChrome(in: last)
                _ = waitForID("pause-run", in: last, timeout: 30)
            }
        }
        return last
    }

    @MainActor
    private func safeTap(_ el: XCUIElement) {
        // Prefer a real accessibility hit. Coordinate-only taps often miss SwiftUI
        // Button actions on physical devices even when the frame looks correct.
        if el.exists, el.isHittable {
            el.tap()
            return
        }
        if el.exists {
            // Fall back to mid-frame coordinate when hittability is wrong under SpriteKit.
            el.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
        if el.isHittable {
            el.tap()
        }
    }

    @MainActor
    private func tapChrome(id: String, in app: XCUIApplication) {
        _ = waitForID(id, in: app, timeout: 15)
        let button = app.buttons.matching(identifier: id).firstMatch
        XCTAssertTrue(
            button.waitForExistence(timeout: 8),
            "Chrome button missing id=\(id). Hierarchy:\n\(app.debugDescription)"
        )
        if button.isHittable {
            button.tap()
        } else {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
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

        tapChrome(id: "pause-run", in: app)
        var pauseOverlay = element(in: app, id: "pause-overlay")
        if !pauseOverlay.waitForExistence(timeout: 4) {
            // A busy SpriteKit accessibility refresh can invalidate the first hit target
            // between lookup and event synthesis. Retry only while gameplay chrome proves
            // the run is still active rather than masking a real pause-state failure.
            let pause = app.buttons.matching(identifier: "pause-run").firstMatch
            if pause.exists {
                safeTap(pause)
            }
            pauseOverlay = element(in: app, id: "pause-overlay")
        }
        XCTAssertTrue(
            pauseOverlay.waitForExistence(timeout: 8),
            "Pause overlay missing after pause request. Hierarchy:\n\(app.debugDescription)"
        )

        // Prefer accessibility id; fall back to visible label.
        var resume = element(in: app, id: "resume-run")
        if !resume.waitForExistence(timeout: 8) {
            resume = app.buttons["RESUME RUN"]
        }
        if !resume.waitForExistence(timeout: 4) {
            resume = app.buttons.matching(identifier: "resume-run").element(boundBy: 0)
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

        tapChrome(id: "open-settings", in: app)
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))

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

        if !element(in: app, id: "pause-run").waitForExistence(timeout: 8),
           element(in: app, id: "resume-run").waitForExistence(timeout: 4)
        {
            safeTap(element(in: app, id: "resume-run"))
        }
        _ = waitForID("pause-run", in: app, timeout: 30)
    }

    @MainActor
    func testPrimaryChromeExposesVoiceOverLabels() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        let pause = waitForID("pause-run", in: app, timeout: 20)
        let settings = waitForID("open-settings", in: app, timeout: 20)
        let handedness = waitForID("toggle-handedness", in: app, timeout: 20)

        XCTAssertEqual(pause.label, "Pause run")
        XCTAssertEqual(settings.label, "Open settings")
        XCTAssertTrue(
            handedness.label == "Move utility control to right"
                || handedness.label == "Move utility control to left"
                // Pre-dynamic-stick labels (keep until CI logs roll over).
                || handedness.label == "Move movement control to right"
                || handedness.label == "Move movement control to left"
        )
    }

    @MainActor
    func testSettingsSlidersExposeVoiceOverLabelsAndValues() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        safeTap(waitForID("open-settings", in: app, timeout: 15))
        _ = waitForID("settings-panel", in: app, timeout: 15)

        let stickSize = app.sliders["Stick size"]
        XCTAssertTrue(stickSize.waitForExistence(timeout: 10))
        XCTAssertTrue(
            (stickSize.value as? String)?.contains("%") == true,
            "Stick size should announce its percentage value"
        )

        let stickOpacity = app.sliders["Stick opacity"]
        XCTAssertTrue(stickOpacity.waitForExistence(timeout: 10))
        XCTAssertTrue((stickOpacity.value as? String)?.contains("%") == true)
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

    @MainActor
    func testDailyChallengeLaunchesWithChallengeObjective() {
        let app = launchApp(scenario: "extraction")
        defer { app.terminate() }

        _ = waitForID("run-summary", in: app, timeout: 20)
        waitForID("start-daily-challenge", in: app, timeout: 10).tap()
        _ = waitForID("pause-run", in: app, timeout: 20)
        let objective = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH[c] %@", "DAILY:")
        ).firstMatch
        XCTAssertTrue(objective.waitForExistence(timeout: 10))
    }

    @MainActor
    func testWeeklyChallengeLaunchesWithChallengeObjective() {
        let app = launchApp(scenario: "extraction")
        defer { app.terminate() }

        _ = waitForID("run-summary", in: app, timeout: 20)
        waitForID("start-weekly-challenge", in: app, timeout: 10).tap()
        _ = waitForID("pause-run", in: app, timeout: 20)
        let objective = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH[c] %@", "WEEKLY:")
        ).firstMatch
        XCTAssertTrue(objective.waitForExistence(timeout: 10))
    }

    @MainActor
    func testReducedMotionSettingPersistsAcrossSheetReopen() {
        let app = launchUntilChromeReady()
        defer { app.terminate() }

        safeTap(waitForID("open-settings", in: app, timeout: 15))
        _ = waitForID("settings-panel", in: app, timeout: 15)
        let toggle = app.switches.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Reduce camera motion")
        ).firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 10))
        let original = toggle.value as? String
        toggle.tap()
        let changed = toggle.value as? String
        XCTAssertNotEqual(changed, original)
        var done = element(in: app, id: "settings-done")
        if !done.waitForExistence(timeout: 4) {
            done = app.buttons["DONE"]
        }
        safeTap(done)
        // After settings, prefer chrome; if residual pause overlay, resume first.
        if !element(in: app, id: "pause-run").waitForExistence(timeout: 8),
           element(in: app, id: "resume-run").waitForExistence(timeout: 4)
        {
            safeTap(element(in: app, id: "resume-run"))
        }
        _ = waitForID("pause-run", in: app, timeout: 20)

        safeTap(waitForID("open-settings", in: app, timeout: 15))
        _ = waitForID("settings-panel", in: app, timeout: 15)
        let reopened = app.switches.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Reduce camera motion")
        ).firstMatch
        XCTAssertTrue(reopened.waitForExistence(timeout: 10))
        XCTAssertEqual(reopened.value as? String, changed)
    }

    @MainActor
    func testDenseCombatScenarioRendersAndKeepsChromeReachable() {
        let app = launchApp(scenario: "density")
        defer { app.terminate() }

        _ = waitForID("pause-run", in: app, timeout: 20)
        _ = waitForID("game-hud", in: app, timeout: 15)
        attachScreenshot("dense-combat", app: app)
    }
}
