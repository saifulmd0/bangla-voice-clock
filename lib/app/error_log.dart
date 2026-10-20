import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../core/settings/settings_store.dart';

/// Appends startup milestones and uncaught errors to
/// `~/Library/Logs/Bangla Voice Clock/app.log` (inside the app's sandbox
/// container), since a release build has nowhere else to report them.
class ErrorLog {
  ErrorLog(this.file);

  /// On Windows, `%LOCALAPPDATA%\Bangla Voice Clock\app.log`; on Linux,
  /// beside the settings in `~/.config/bangla-voice-clock/`.
  factory ErrorLog.standard() => ErrorLog(
    File(
      Platform.isWindows
          ? '${Platform.environment['LOCALAPPDATA']}\\Bangla Voice Clock\\app.log'
          : Platform.isLinux
          ? '${linuxConfigHome()}/bangla-voice-clock/app.log'
          : '${Platform.environment['HOME']}/Library/Logs/Bangla Voice Clock/'
                'app.log',
    ),
  );

  final File file;

  void write(String message) {
    try {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
        '${DateTime.now().toIso8601String()} $message\n',
        mode: FileMode.append,
      );
    } on FileSystemException {
      // Nowhere to log to; carry on.
    }
  }

  /// Runs [body], logging every error it or Flutter reports.
  void guard(Future<void> Function() body) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      write('Flutter error: ${details.exception}\n${details.stack}');
    };
    runZonedGuarded(body, (error, stack) => write('Error: $error\n$stack'));
  }
}
