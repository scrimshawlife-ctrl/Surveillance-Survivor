import UIKit

/// Forces landscape-only presentation for the iPhone vertical slice.
/// Info.plist keys alone are not always enough under the SwiftUI app lifecycle.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        .landscape
    }
}
