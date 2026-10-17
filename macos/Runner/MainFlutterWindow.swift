import AVFoundation
import Cocoa
import FlutterMacOS
import ServiceManagement
import UserNotifications

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private var bridge: NativeBridge?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    self.title = "বাংলা ভয়েস ক্লক"
    self.minSize = NSSize(width: 420, height: 480)
    self.delegate = self

    RegisterGeneratedPlugins(registry: flutterViewController)
    bridge = NativeBridge(
      window: self, messenger: flutterViewController.engine.binaryMessenger)
    // Flutter normally starts Dart when the window first appears, but this
    // window starts hidden (the app lives in the menu bar), so start it now.
    _ = flutterViewController.engine.run(withEntrypoint: nil)

    super.awakeFromNib()
  }

  // Closing the settings window only hides it; the app lives in the menu bar.
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    orderOut(nil)
    return false
  }
}

/// The macOS side of `lib/app/platform.dart`: menu-bar item, audio,
/// notifications, launch at login, and wake/clock-change events.
class NativeBridge: NSObject {
  private let window: NSWindow
  private let channel: FlutterMethodChannel
  private let statusItem = NSStatusBar.system.statusItem(
    withLength: NSStatusItem.variableLength)
  private var player: AVAudioPlayer?
  private var notificationsAllowed: Bool?
  // Keeps App Nap from delaying the minute timer while the app is idle.
  private let activity = ProcessInfo.processInfo.beginActivity(
    options: .userInitiatedAllowingIdleSystemSleep,
    reason: "Announcing the time on schedule")

  init(window: NSWindow, messenger: FlutterBinaryMessenger) {
    self.window = window
    channel = FlutterMethodChannel(name: "bangla_voice_clock/macos", binaryMessenger: messenger)
    super.init()
    // The app's logo as a template image, so it follows the menu bar's colour.
    let logo =
      NSImage(named: "StatusIcon")
      ?? NSImage(systemSymbolName: "clock", accessibilityDescription: nil)
    logo?.isTemplate = true
    logo?.accessibilityDescription = "Bangla Voice Clock"
    statusItem.button?.image = logo
    statusItem.button?.imagePosition = .imageLeft
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }

    let disturbed = #selector(clockDisturbed)
    NSWorkspace.shared.notificationCenter.addObserver(
      self, selector: disturbed, name: NSWorkspace.didWakeNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: disturbed, name: .NSSystemClockDidChange, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: disturbed, name: .NSSystemTimeZoneDidChange, object: nil)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "play":
      guard let args = call.arguments as? [String: Any],
        let wav = args["wav"] as? FlutterStandardTypedData
      else { return result(badArguments(call)) }
      do {
        let player = try AVAudioPlayer(data: wav.data)
        player.volume = Float(args["volume"] as? Double ?? 1)
        player.play()
        self.player = player
        result(nil)
      } catch {
        result(FlutterError(code: "play_failed", message: "\(error)", details: nil))
      }
    case "setStatusTitle":
      let title = call.arguments as? String ?? ""
      statusItem.button?.title = title
      // Show the clock icon only when there is no time to show.
      statusItem.button?.imagePosition = title.isEmpty ? .imageOnly : .noImage
      result(nil)
    case "setMenu":
      guard let entries = call.arguments as? [[String: Any]] else {
        return result(badArguments(call))
      }
      statusItem.menu = menu(from: entries)
      result(nil)
    case "showWindow":
      NSApp.activate(ignoringOtherApps: true)
      window.makeKeyAndOrderFront(nil)
      result(nil)
    case "notify":
      guard let args = call.arguments as? [String: String] else {
        return result(badArguments(call))
      }
      notify(title: args["title"] ?? "", body: args["body"] ?? "")
      result(nil)
    case "openUrl":
      guard let link = call.arguments as? String, let url = URL(string: link) else {
        return result(badArguments(call))
      }
      NSWorkspace.shared.open(url)
      result(nil)
    case "launchAtLogin":
      if #available(macOS 13.0, *) {
        result(SMAppService.mainApp.status == .enabled)
      } else {
        result(nil)
      }
    case "setLaunchAtLogin":
      guard #available(macOS 13.0, *) else { return result(false) }
      do {
        if call.arguments as? Bool == true {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
        result(true)
      } catch {
        NSLog("Launch at login change failed: \(error)")
        result(false)
      }
    case "quit":
      result(nil)
      NSApp.terminate(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func menu(from entries: [[String: Any]]) -> NSMenu {
    let menu = NSMenu()
    menu.autoenablesItems = false
    for entry in entries {
      if entry["separator"] as? Bool == true {
        menu.addItem(.separator())
        continue
      }
      let item = NSMenuItem(
        title: entry["title"] as? String ?? "", action: #selector(itemSelected(_:)),
        keyEquivalent: "")
      item.target = self
      item.representedObject = entry["id"] as? String
      item.isEnabled = entry["enabled"] as? Bool ?? true
      item.state = entry["checked"] as? Bool == true ? .on : .off
      if let children = entry["children"] as? [[String: Any]], !children.isEmpty {
        item.submenu = self.menu(from: children)
        item.action = nil
      }
      menu.addItem(item)
    }
    return menu
  }

  @objc private func itemSelected(_ sender: NSMenuItem) {
    if let id = sender.representedObject as? String, !id.isEmpty {
      channel.invokeMethod("menuItemSelected", arguments: id)
    }
  }

  @objc private func clockDisturbed() {
    DispatchQueue.main.async {
      self.channel.invokeMethod("clockDisturbed", arguments: nil)
    }
  }

  private func notify(title: String, body: String) {
    let center = UNUserNotificationCenter.current()
    let send = {
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = body
      center.add(
        UNNotificationRequest(identifier: "announcement", content: content, trigger: nil))
    }
    if let allowed = notificationsAllowed {
      if allowed { send() }
      return
    }
    center.requestAuthorization(options: [.alert]) { granted, _ in
      DispatchQueue.main.async {
        self.notificationsAllowed = granted
        if granted { send() }
      }
    }
  }

  private func badArguments(_ call: FlutterMethodCall) -> FlutterError {
    FlutterError(code: "bad_arguments", message: "Bad arguments for \(call.method)", details: nil)
  }
}
