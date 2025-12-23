import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:nexus/app/router/app_router.dart';
import 'package:nexus/app/services/app_services_composer.dart';
import 'package:nexus/app/theme/app_theme.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:nexus/app/app_globals.dart';
import 'package:nexus/l10n/app_localizations.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  // Keep router instance persistent to preserve navigation state across rebuilds
  late final _router = AppRouter.create();

  @override
  void initState() {
    super.initState();
    // Initialize background services after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initializeBackgroundServices(context);
      }
    });
  }

  @override
  void dispose() {
    disposeBackgroundServices();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    // Determine which theme is currently active
    final currentTheme = settings.themeMode == ThemeMode.dark
        ? AppTheme.dark(
            customPrimary: settings.darkColors.primary,
            customSecondary: settings.darkColors.secondary,
          )
        : AppTheme.light(
            customPrimary: settings.lightColors.primary,
            customSecondary: settings.lightColors.secondary,
          );

    return MaterialApp.router(
      scaffoldMessengerKey: appMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Nexus',
      theme: AppTheme.light(
        customPrimary: settings.lightColors.primary,
        customSecondary: settings.lightColors.secondary,
      ),
      darkTheme: AppTheme.dark(
        customPrimary: settings.darkColors.primary,
        customSecondary: settings.darkColors.secondary,
      ),
      themeMode: settings.themeMode,
      routerConfig: _router,
      builder: (context, child) {
        return AnimatedTheme(
          data: currentTheme,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: wrapWithAppServices(context, child ?? const SizedBox.shrink()),
        );
      },
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
