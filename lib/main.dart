import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/error_log.dart';
import 'app/platform.dart';
import 'core/settings/settings_store.dart';
import 'ui/settings_page.dart';
import 'ui/theme.dart';

void main() {
  final log = ErrorLog.standard();
  log.guard(() async {
    WidgetsFlutterBinding.ensureInitialized();
    log.write('Starting');
    final controller = await AppController.create(
      platform: MacosPlatform(),
      store: SettingsStore.standard(),
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

  @override
  void initState() {
    super.initState();
    // The menu bar's Credits item opens the credits page in this window.
    _credits = widget.controller.creditsRequests.listen((_) {
      _navigator.currentState
        ?..popUntil((route) => route.isFirst)
        ..push(creditsRoute(widget.controller));
    });
  }

  @override
  void dispose() {
    _credits.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorKey: _navigator,
    title: 'Bangla Voice Clock',
    debugShowCheckedModeBanner: false,
    theme: skyTheme(Brightness.light),
    darkTheme: skyTheme(Brightness.dark),
    home: SettingsPage(controller: widget.controller),
  );
}
