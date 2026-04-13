import UIKit
import Flutter
import Firebase
import GoogleMaps
import UserNotifications   // ✅ REQUIRED for notifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase init
    FirebaseApp.configure()

    // Google Maps API
    GMSServices.provideAPIKey("AIzaSyDpH5LUm09CEiJX4cSan8SDp0vxuVLwCCQ")

    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // Notification delegate
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // Register APNS
    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // ❌ Error registering APNS
  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications: \(error)")
  }

  // ✅ APNS token received
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {

    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()

    print("✅ APNS device token received: \(token)")
  }
}
