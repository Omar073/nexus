import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nexus/app/router/app_router.dart';
import 'package:nexus/app/services/app_services_composer.dart';
import 'package:nexus/app/theme/app_theme.dart';
import 'package:nexus/features/reminders/domain/repositories/reminder_repository_interface.dart';
import 'package:nexus/features/reminders/presentation/state_management/reminder_controller.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:nexus/app/app_globals.dart';

/// Root [MaterialApp]: theme mode, [GoRouter], and keyboard shortcuts.
/// Hosts the navigator below splash once [AppInitializer] finishes.

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  // Keep router instance persistent to preserve navigation state across rebuilds
  late final _router = AppRouter.create();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize background services after first frame so the Provider tree is
    // fully mounted (and `context.read<T>()` is safe).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initializeBackgroundServices(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    disposeBackgroundServices();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Resume fallback: if completion happened while the UI isolate wasn't
          // active (or a watcher event was missed), drain the pending file.
          try {
            final repo = context.read<ReminderRepositoryInterface>();
            final controller = context.read<ReminderController>();
            unawaited(
              drainPendingReminderCompletesFromNotification(
                repo: repo,
                controller: controller,
              ),
            );
          } catch (_) {
            // App is resuming but providers may not be ready yet.
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // Match MaterialApp theme resolution (including ThemeMode.system).
    final currentTheme = AppTheme.fromUserSettings(
      context,
      themeMode: settings.themeMode,
      lightPrimary: settings.lightColors.primary,
      lightSecondary: settings.lightColors.secondary,
      darkPrimary: settings.darkColors.primary,
      darkSecondary: settings.darkColors.secondary,
      darkPalette: settings.darkPalette,
    );

    return MaterialApp.router(
      scaffoldMessengerKey: appMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Nexus',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', 'US')],
      theme: AppTheme.light(
        customPrimary: settings.lightColors.primary,
        customSecondary: settings.lightColors.secondary,
      ),
      darkTheme: AppTheme.dark(
        customPrimary: settings.darkColors.primary,
        customSecondary: settings.darkColors.secondary,
        palette: settings.darkPalette,
      ),
      themeMode: settings.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return AnimatedTheme(
          data: currentTheme,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: wrapWithOverlays(context, child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
