import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    var userInfo: [AnyHashable: Any] = [:]
    userInfo["options"] = options
    userInfo["openUrl"] = url
    NotificationCenter.default.post(
      name: NSNotification.Name("ApplicationOpenURLNotification"),
      object: nil,
      userInfo: userInfo
    )
    return super.application(app, open: url, options: options)
  }
}
