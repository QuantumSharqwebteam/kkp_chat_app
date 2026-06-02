import UIKit
import Flutter
import UserNotifications
import CallKit

@main
@objc class AppDelegate: FlutterAppDelegate {

  private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    GeneratedPluginRegistrant.register(with: self)

    // Method channel for socket background keepalive
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.kkpchatapp/background_task",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else { return }
        switch call.method {
        case "beginBackgroundTask":
          self.beginSocketBackgroundTask()
          result(nil)
        case "endBackgroundTask":
          self.endSocketBackgroundTask()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func beginSocketBackgroundTask() {
    guard backgroundTaskID == .invalid else { return }
    backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SocketKeepalive") {
      [weak self] in
      self?.endSocketBackgroundTask()
    }
  }

  private func endSocketBackgroundTask() {
    guard backgroundTaskID != .invalid else { return }
    UIApplication.shared.endBackgroundTask(backgroundTaskID)
    backgroundTaskID = .invalid
  }

  // Suppress banner/sound for FCM call notifications when CallKit is already
  // showing the native incoming-call screen — avoids a double alert.
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {

    let userInfo = notification.request.content.userInfo
    let isCallNotification = (userInfo["notificationType"] as? String) == "incoming_call"
      || (userInfo["type"] as? String) == "incoming_call"
      || (userInfo["type"] as? String) == "call"

    // If CallKit is already presenting a call, don't show a duplicate banner
    if isCallNotification {
      let activeCalls = CXCallObserver().calls
      if activeCalls.contains(where: { !$0.hasEnded }) {
        completionHandler([])
        return
      }
    }

    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
