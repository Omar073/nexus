import 'package:flutter/material.dart';
import 'package:nexus/app/app.dart';
import 'package:nexus/core/services/notifications/battery_optimization_first_launch_prompt.dart';
import 'package:nexus/features/splash/presentation/bootstrap/app_initializer.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';
import 'package:nexus/features/splash/presentation/models/critical_initialization_result.dart';
import 'package:nexus/features/splash/presentation/bootstrap/provider_factory.dart';
import 'package:nexus/features/splash/presentation/pages/splash_screen.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:provider/provider.dart';

/// Wrapper that shows splash screen, initializes critical services, then shows main app
/// Non-critical services are initialized in the background after the app opens
class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  CriticalInitializationResult? _criticalResult;
  bool _backgroundInitStarted = false;

  void _onCriticalInitializationComplete(CriticalInitializationResult result) {
    if (!mounted) return;
    setState(() {
      _criticalResult = result;
    });

    // Start background initialization after app opens
    _startBackgroundInitialization(result);
  }

  Future<void> _startBackgroundInitialization(
    CriticalInitializationResult critical,
  ) async {
    if (_backgroundInitStarted) return;
    _backgroundInitStarted = true;

    // Complete initialization in background (non-blocking)
    try {
      final fullResult = await AppInitializer.completeInitialization(critical);
      if (!mounted) return;

      // Update critical result with full result so providers can use it
      critical.setFullResult(fullResult);

      // Trigger rebuild to update providers
      if (mounted) {
        setState(() {});
      }

      _scheduleBatteryOptimizationFirstLaunch(fullResult);
    } catch (e) {
      // Log error but don't block the app
      mDebugPrint('Background initialization error: $e');
    }
  }

  /// Defers to the next frame so [rootNavigatorKey] is under the routed app.
  void _scheduleBatteryOptimizationFirstLaunch(
    AppInitializationResult fullResult,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await BatteryOptimizationFirstLaunchPrompt.runIfNeeded(
        notificationService: fullResult.notificationService,
        isMounted: () => mounted,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_criticalResult == null) {
      return SplashScreen(
        onInitializationComplete: _onCriticalInitializationComplete,
      );
    }

    // Show main app with providers (lazy providers will initialize as needed)
    return MultiProvider(
      providers: AppProviderFactory.createProviders(
        _criticalResult!,
        _criticalResult!.fullResult,
      ),
      child: const App(),
    );
  }
}
