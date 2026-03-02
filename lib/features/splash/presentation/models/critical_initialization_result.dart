import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';

/// Result of critical initialization (needed for app to open)
class CriticalInitializationResult {
  final SettingsController settingsController;
  final String deviceId;
  final ConnectivityService connectivityService;
  final PermissionService permissionService;

  // Will be set when background initialization completes
  AppInitializationResult? _fullResult;

  CriticalInitializationResult({
    required this.settingsController,
    required this.deviceId,
    required this.connectivityService,
    required this.permissionService,
  });

  /// Sets the full initialization result to update lazy providers
  void setFullResult(AppInitializationResult fullResult) {
    _fullResult = fullResult;
  }

  /// Gets the full initialization result (if available)
  AppInitializationResult? get fullResult => _fullResult;
}
