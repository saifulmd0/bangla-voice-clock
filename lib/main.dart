import 'package:flutter/material.dart';

import 'app/app_controller.dart';
import 'app/platform.dart';
import 'core/settings/settings_store.dart';
import 'ui/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create(
    platform: MacosPlatform(),
    store: SettingsStore.standard(),
  );
  runApp(BanglaVoiceClockApp(controller: controller));
  await controller.start();
}

class BanglaVoiceClockApp extends StatelessWidget {
  const BanglaVoiceClockApp({super.key, required this.controller});

  final AppController controller;

  // Bangladesh green.
  static const _seed = Color(0xFF006A4E);

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'বাংলা ভয়েস ক্লক',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: _seed),
    darkTheme: ThemeData(colorSchemeSeed: _seed, brightness: Brightness.dark),
    home: SettingsPage(controller: controller),
  );
}
