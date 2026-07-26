import XCTest

/// Automated **mechanical** device acceptance path (extract receipt UI).
/// Launch arg `-UITestingForceExtract` forces Blind Spot completion in-process.
/// Does **not** claim ART readability, thermal, haptics, or ART_SHIP_APPROVED.
final class DeviceAcceptanceUITests: XCTestCase {
    @MainActor
    private func launchForceExtract() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UITesting",
            "-UITestingForceExtract",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        addUIInterruptionMonitor(withDescription: "System alerts") { element in
            for title in ["Allow", "OK", "Close", "Not Now", "Don't Allow"] {
                let button = element.buttons[title]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
        app.launch()
        _ = app.wait(for: .runningForeground, timeout: 45)
        RunLoop.current.run(until: Date().addingTimeInterval(2.0))
        return app
    }

    @MainActor
    private func element(in app: XCUIApplication, id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).element(boundBy: 0)
    }

    @MainActor
    private func waitForID(_ id: String, in app: XCUIApplication, timeout: TimeInterval) -> XCUIElement {
        let el = element(in: app, id: id)
        XCTAssertTrue(
            el.waitForExistence(timeout: timeout),
            "Missing id=\(id). Hierarchy:\n\(app.debugDescription)"
        )
        return el
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Force-extract lands on run summary with a copyable receipt (mechanical only).
    @MainActor
    func testForceExtractShowsRunSummaryAndCopyReceipt() {
        let app = launchForceExtract()
        defer { app.terminate() }

        let summary = waitForID("run-summary", in: app, timeout: 25)
        XCTAssertTrue(summary.exists)

        // Prefer extract-positive copy; still require the chrome control.
        let copy = waitForID("copy-receipt-json", in: app, timeout: 15)
        if copy.isHittable {
            copy.tap()
        } else {
            copy.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))

        // Mastery / campaign lines prove summary fully mounted.
        _ = waitForID("mastery-summary", in: app, timeout: 10)
        XCTAssertTrue(
            app.staticTexts["BLIND SPOT REACHED"].waitForExistence(timeout: 5),
            "Force extract must show extract summary, not defeat. Hierarchy:\n\(app.debugDescription)"
        )
        attachScreenshot("device-acceptance-extract-summary", app: app)
    }
}
