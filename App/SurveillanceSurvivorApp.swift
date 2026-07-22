import SwiftUI

@main
struct SurveillanceSurvivorApp: App {
    var body: some Scene {
        WindowGroup {
            RootView().persistentSystemOverlays(.hidden)
        }
    }
}
