import XCTest

/// Black-box launch-shell smoke **without** `-UITesting`.
///
/// Production launches show splash → start menu. Chrome XCUITests skip that shell
/// via `-UITesting` so they can reach pause/settings. This suite proves the real
/// first-run path: splash (or auto-advance) → start menu → BEGIN RUN → play chrome.
///
/// Run: `make launch-smoke`
/// Does not claim ART, extract, or physical-device acceptance.
final class LaunchShellUITests: XCTestCase {
    @MainActor
    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).element(boundBy: 0)
    }

    @MainActor
    private func waitForAnyID(
        _ ids: [String],
        in app: XCUIApplication,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> String? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for id in ids {
                if element(in: app, id: id).exists {
                    return id
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        XCTFail(
            "Missing any of \(ids). Hierarchy:\n\(app.debugDescription)",
            file: file,
            line: line
        )
        return nil
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
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        let el = element(in: app, id: id)
        if el.waitForExistence(timeout: 2) {
            return el
        }
        XCTFail("Missing id=\(id). Hierarchy:\n\(app.debugDescription)", file: file, line: line)
        return el
    }

    @MainActor
    private func safeTap(_ el: XCUIElement) {
        if el.exists, el.isHittable {
            el.tap()
            return
        }
        if el.exists {
            el.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return
        }
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let shot = app.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Advances splash if present, then returns when the start menu is ready.
    @MainActor
    private func advanceThroughSplashIfNeeded(in app: XCUIApplication) {
        // Splash may auto-advance (~1.55s) before we query; menu-only is also success.
        let surface = waitForAnyID(
            ["splash-surface", "splash-screen", "title-screen", "start-menu", "title-begin-run"],
            in: app,
            timeout: 25
        )
        guard let surface else { return }

        if surface == "splash-surface" || surface == "splash-screen" {
            attachScreenshot("launch-splash", app: app)
            let splash = element(in: app, id: "splash-surface")
            if splash.exists {
                safeTap(splash)
            } else {
                // Whole-screen shell is tappable via splash-screen container.
                let shell = element(in: app, id: "splash-screen")
                safeTap(shell)
            }
            // Auto-advance race: either tap worked or the timer already flipped phase.
            _ = waitForAnyID(
                ["title-screen", "start-menu", "title-begin-run"],
                in: app,
                timeout: 8
            )
        }
    }

    @MainActor
    private func launchProductionShell() -> XCUIApplication {
        let app = XCUIApplication()
        // Intentionally omit `-UITesting` so splash + start menu are real.
        app.launchArguments += [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 45)
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        return app
    }

    @MainActor
    func testSplashAndStartMenuReachGameplayWithoutUITesting() {
        let app = launchProductionShell()
        defer { app.terminate() }

        advanceThroughSplashIfNeeded(in: app)
        attachScreenshot("launch-start-menu", app: app)

        _ = waitForID("title-begin-run", in: app, timeout: 12)
        // Wordmark + district prove menu content, not just a blank paper.
        XCTAssertTrue(
            element(in: app, id: "title-wordmark").waitForExistence(timeout: 4)
                || element(in: app, id: "start-menu").exists,
            "Start menu wordmark missing. Hierarchy:\n\(app.debugDescription)"
        )

        let begin = app.buttons.matching(identifier: "title-begin-run").firstMatch
        XCTAssertTrue(begin.waitForExistence(timeout: 8), "BEGIN RUN missing")
        safeTap(begin)

        // Production auto-fire is live; only assert chrome appears promptly.
        _ = waitForID("pause-run", in: app, timeout: 20)
        _ = waitForID("control-chrome", in: app, timeout: 12)
        attachScreenshot("launch-gameplay-after-begin", app: app)
    }
}
