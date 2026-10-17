import 'dart:async';

import 'package:flutter/services.dart';

import '../core/settings/app_settings.dart';

/// An item in the menu-bar menu.
class MenuEntry {
  const MenuEntry(
    this.id,
    this.title, {
    this.checked = false,
    this.enabled = true,
    this.children = const [],
  });

  const MenuEntry.separator()
    : id = '',
      title = '',
      checked = false,
      enabled = false,
      children = const [];

  final String id;
  final String title;
  final bool checked;
  final bool enabled;
  final List<MenuEntry> children;

  bool get isSeparator => id.isEmpty && title.isEmpty;

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'checked': checked,
    'enabled': enabled,
    'separator': isSeparator,
    'children': [for (final c in children) c.toMap()],
  };
}

/// What the app needs from the operating system.
abstract interface class AppPlatform {
  /// Menu-bar item clicks, by [MenuEntry.id].
  Stream<String> get menuSelections;

  /// Fires after the computer wakes or the clock or time zone changes.
  Stream<void> get clockDisturbed;

  Future<void> play(Uint8List wav, {double volume = 1});
  Future<void> setStatusTitle(String title);
  Future<void> setMenu(List<MenuEntry> entries);
  Future<void> showWindow();
  Future<void> notify(String title, String body);
  Future<void> openUrl(String url);

  /// Makes the window's own chrome (title bar) light, dark or follow macOS.
  Future<void> setAppearance(Appearance appearance);

  /// Null where launching at login isn't supported (before macOS 13).
  Future<bool?> launchAtLogin();

  /// Returns whether the change took effect.
  Future<bool> setLaunchAtLogin(bool enabled);
  Future<void> quit();
}

/// [AppPlatform] for macOS, backed by the Swift code in `macos/Runner`.
class MacosPlatform implements AppPlatform {
  MacosPlatform() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'menuItemSelected':
          _menu.add(call.arguments as String);
        case 'clockDisturbed':
          _clock.add(null);
      }
    });
  }

  static const _channel = MethodChannel('bangla_voice_clock/macos');
  final _menu = StreamController<String>.broadcast();
  final _clock = StreamController<void>.broadcast();

  @override
  Stream<String> get menuSelections => _menu.stream;

  @override
  Stream<void> get clockDisturbed => _clock.stream;

  @override
  Future<void> play(Uint8List wav, {double volume = 1}) =>
      _channel.invokeMethod('play', {'wav': wav, 'volume': volume});

  @override
  Future<void> setStatusTitle(String title) =>
      _channel.invokeMethod('setStatusTitle', title);

  @override
  Future<void> setMenu(List<MenuEntry> entries) =>
      _channel.invokeMethod('setMenu', [for (final e in entries) e.toMap()]);

  @override
  Future<void> showWindow() => _channel.invokeMethod('showWindow');

  @override
  Future<void> notify(String title, String body) =>
      _channel.invokeMethod('notify', {'title': title, 'body': body});

  @override
  Future<void> openUrl(String url) => _channel.invokeMethod('openUrl', url);

  @override
  Future<void> setAppearance(Appearance appearance) =>
      _channel.invokeMethod('setAppearance', appearance.name);

  @override
  Future<bool?> launchAtLogin() => _channel.invokeMethod<bool>('launchAtLogin');

  @override
  Future<bool> setLaunchAtLogin(bool enabled) async =>
      await _channel.invokeMethod<bool>('setLaunchAtLogin', enabled) ?? false;

  @override
  Future<void> quit() => _channel.invokeMethod('quit');
}
