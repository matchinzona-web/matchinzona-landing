import Flutter
import UIKit
import GoogleMaps // 1. AGGIUNGI L'IMPORTAZIONE DI GOOGLE MAPS QUI

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    // 2. INIEZIONE API KEY REALE
    GMSServices.provideAPIKey("AIzaSyBDivilBxBjRLpV2CqvnnR0ViU-5uUYFgg")
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}