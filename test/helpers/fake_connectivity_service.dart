import 'dart:async';

import 'package:nexus/core/services/platform/connectivity_service.dart';

/// Test stub for [ConnectivityService].
///
/// Allows tests to control online/offline state and emit
/// connectivity change events via [controller].
class FakeConnectivityService extends ConnectivityService {
  FakeConnectivityService({this.online = true});

  bool online;

  final StreamController<bool> controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> onlineStream() => controller.stream;

  /// Simulate a connectivity change.
  void setOnline(bool value) {
    online = value;
    controller.add(value);
  }

  void dispose() {
    controller.close();
  }
}
