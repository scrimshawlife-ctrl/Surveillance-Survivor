import SwiftUI

@main
struct SurveillanceSurvivorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                // Landscape action owns the glass — no status-bar / home-indicator chrome.
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
                .ignoresSafeArea()
        }
    }
}
