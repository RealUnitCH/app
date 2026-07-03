import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private static let backupExclusionChannelName = "swiss.realunit.app/backup_exclusion"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: AppDelegate.backupExclusionChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "excludeFromBackup" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let paths = call.arguments as? [String] else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "excludeFromBackup expects a list of file paths",
              details: nil
            )
          )
          return
        }
        for path in paths {
          AppDelegate.excludeFromBackup(path: path)
        }
        result(nil)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Sets `NSURLIsExcludedFromBackupKey` on the file at `path` so it is left out
  /// of iCloud / iTunes / Finder backups. Best-effort: files that do not exist
  /// (e.g. a `-wal`/`-shm` sidecar not yet created) are skipped, and any failure
  /// to set the attribute is intentionally swallowed — the exclusion is
  /// defence-in-depth on an already-encrypted database, not a correctness
  /// invariant.
  private static func excludeFromBackup(path: String) {
    guard FileManager.default.fileExists(atPath: path) else { return }
    var url = URL(fileURLWithPath: path)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? url.setResourceValues(values)
  }
}
