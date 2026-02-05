import UIKit
import Flutter
import GoogleMaps   // ✅ Import Google Maps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Register all Flutter plugins
    GeneratedPluginRegistrant.register(with: self)

    // ✅ Provide Google Maps API Key
    GMSServices.provideAPIKey("AIzaSyCedqTzYBhX-7xwYvMScLTvZlYfba1L6gc")

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
