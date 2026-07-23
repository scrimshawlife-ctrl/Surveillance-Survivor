import SwiftUI

@main
struct SurveillanceSurvivorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .persistentSystemOverlays(.hidden)
        }
    }
}
