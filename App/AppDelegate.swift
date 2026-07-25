import UIKit

/// Forces landscape-only, fullscreen presentation for the iPhone vertical slice.
/// Info.plist keys alone are not always enough under the SwiftUI app lifecycle.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Prefer hiding the status bar when view-controller based appearance is off.
        UIApplication.shared.isIdleTimerDisabled = false
        return true
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .landscape
    }
}
