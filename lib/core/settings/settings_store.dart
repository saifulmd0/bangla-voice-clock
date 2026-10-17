import 'dart:convert';
import 'dart:io';

import 'app_settings.dart';

/// Keeps [AppSettings] in a JSON file.
class SettingsStore {
  SettingsStore(this.file);

  /// `~/Library/Application Support/Bangla Voice Clock/settings.json`, which
  /// for a sandboxed app is inside its own container.
  factory SettingsStore.standard() => SettingsStore(
    File(
      '${Platform.environment['HOME']}/Library/Application Support/'
      'Bangla Voice Clock/settings.json',
    ),
  );

  final File file;

  /// The saved settings, or the defaults if there are none or the file is
  /// unreadable.
  Future<AppSettings> load() async {
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is Map<String, dynamic>) return AppSettings.fromJson(json);
    } on FileSystemException {
      // Not saved yet.
    } on FormatException {
      // Damaged; start again from the defaults.
    }
    return const AppSettings();
  }

  Future<void> save(AppSettings settings) async {
    await file.parent.create(recursive: true);
    // Write then rename, so a crash mid-write can't leave a broken file.
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(settings.toJson()));
    await temp.rename(file.path);
  }
}
