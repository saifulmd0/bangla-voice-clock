import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/error_log.dart';
import 'app/platform.dart';
import 'app/updater.dart';
import 'core/settings/app_settings.dart';
import 'core/settings/settings_store.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';
import 'ui/update_dialog.dart';

void main() {
  final log = ErrorLog.standard();
  log.guard(() async {
    WidgetsFlutterBinding.ensureInitialized();
    log.write('Starting');
    final controller = await AppController.create(
      platform: NativePlatform(),
      store: SettingsStore.standard(),
      updates: GitHubUpdates(),
      // On Windows the setup's start-at-sign-in box, ticked by default,
      // decides.
      openAtLoginOnFirstRun: Platform.isMacOS,
    );
    runApp(BanglaVoiceClockApp(controller: controller));
    await controller.start();
    log.write('Ready');
  });
}

class BanglaVoiceClockApp extends StatefulWidget {
  const BanglaVoiceClockApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<BanglaVoiceClockApp> createState() => _BanglaVoiceClockAppState();
}

class _BanglaVoiceClockAppState extends State<BanglaVoiceClockApp> {
  final _navigator = GlobalKey<NavigatorState>();
  late final StreamSubscription<void> _credits;
  late final StreamSubscription<void> _updates;

  @override
  void initState() {
    super.initState();
    // The menu bar's Credits item opens the credits page in this window.
    _credits = widget.controller.creditsRequests.listen((_) {
      _navigator.currentState
        ?..popUntil((route) => route.isFirst)
        ..push(creditsRoute(widget.controller));
    });
    // A daily check found a new version; the window is already open.
    _updates = widget.controller.updateRequests.listen((release) {
      final overlay = _navigator.currentState?.overlay;
      if (overlay != null && overlay.mounted) {
        unawaited(
          showUpdateDialog(overlay.context, widget.controller, release),
        );
      }
    });
  }

  @override
  void dispose() {
    _credits.cancel();
    _updates.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) => _app(),
  );

  Widget _app() => MaterialApp(
    navigatorKey: _navigator,
    themeMode: switch (widget.controller.settings.appearance) {
      Appearance.system => ThemeMode.system,
      Appearance.light => ThemeMode.light,
      Appearance.dark => ThemeMode.dark,
    },
    title: 'Bangla Voice Clock',
    debugShowCheckedModeBanner: false,
    theme: skyTheme(Brightness.light),
    darkTheme: skyTheme(Brightness.dark),
    home: SettingsPage(controller: widget.controller),
  );
}
