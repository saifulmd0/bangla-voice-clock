import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  // The app keeps running in the menu bar after its window closes.
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
