import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:nexus/app/router/app_router.dart';
import 'package:nexus/app/services/app_services_composer.dart';
import 'package:nexus/app/theme/app_theme.dart';
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
  Timer? _pendingCompletePoller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize background services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initializeBackgroundServices(context);
      }
    });

    // While the app is open, Complete can be handled by a headless isolate.
    // Poll briefly so the UI gets the updated completion state without requiring
    // the user to background/resume the app.
    _pendingCompletePoller = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      unawaited(drainPendingReminderCompletesFromNotification(context));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pendingCompletePoller?.cancel();
    disposeBackgroundServices();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(drainPendingReminderCompletesFromNotification(context));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // Determine which theme is currently active
    final currentTheme = settings.themeMode == ThemeMode.dark
        ? AppTheme.dark(
            customPrimary: settings.darkColors.primary,
            customSecondary: settings.darkColors.secondary,
            palette: settings.darkPalette,
          )
        : AppTheme.light(
            customPrimary: settings.lightColors.primary,
            customSecondary: settings.lightColors.secondary,
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
