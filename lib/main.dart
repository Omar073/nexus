import 'package:flutter/material.dart';
import 'package:nexus/features/splash/presentation/pages/splash_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show splash screen immediately while initializing critical services
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nexus',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const SplashWrapper(),
    ),
  );
}
