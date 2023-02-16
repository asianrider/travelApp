import UIKit
import Flutter
import GoogleMaps
import MapboxMaps


@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  let customHTTPService = CustomHttpService()
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyClsHb5kKWNrDvPCbP************")
    GeneratedPluginRegistrant.register(with: self)
HttpServiceFactory.setUserDefinedForCustom(customHTTPService)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
