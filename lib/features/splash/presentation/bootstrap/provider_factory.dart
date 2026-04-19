import 'package:nexus/core/services/platform/connectivity_service.dart';
import 'package:nexus/core/services/platform/permission_service.dart';
import 'package:nexus/features/splash/presentation/models/app_initialization_result.dart';
import 'package:nexus/features/splash/presentation/models/critical_initialization_result.dart';
import 'package:nexus/features/splash/presentation/bootstrap/provider_factory_controllers.dart';
import 'package:nexus/features/splash/presentation/bootstrap/provider_factory_repositories.dart';
import 'package:nexus/features/splash/presentation/bootstrap/provider_factory_services.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Builds the [MultiProvider] tree for the running app.
class AppProviderFactory {
  /// Creates providers from critical initialization result
  ///
  /// Returns a list of providers that can be used with MultiProvider.
  /// Non-critical providers are created lazily and will be updated when
  /// full initialization completes.
  static List<SingleChildWidget> createProviders(
    CriticalInitializationResult critical,
    AppInitializationResult? fullResult,
  ) {
    // Store references for use in lazy providers
    final settings = critical.settingsController;
    final connectivity = critical.connectivityService;
    final device = critical.deviceId;

    // Critical providers (always available)
    final criticalProviders = <SingleChildWidget>[
      ChangeNotifierProvider.value(value: settings),
      Provider<String>.value(value: device),
      Provider<ConnectivityService>.value(value: connectivity),
      Provider<PermissionService>.value(value: critical.permissionService),
    ];

    // Non-critical providers (lazy initialization)
    final lazyProviders = <SingleChildWidget>[
      ...createAppServiceProviders(connectivity, device, fullResult),
      ...createAppRepositoryProviders(fullResult),
      ...createAppControllerProviders(
        settings,
        connectivity,
        device,
        fullResult,
      ),
    ];

    return [...criticalProviders, ...lazyProviders];
  }
}
