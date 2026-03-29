import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/services/platform/connectivity_service.dart';

/// Fake [Connectivity] with controllable status.

class MockConnectivity extends Fake implements Connectivity {
  List<ConnectivityResult> checkResults = [ConnectivityResult.wifi];
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return checkResults;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _controller.stream;

  void emit(List<ConnectivityResult> results) {
    _controller.add(results);
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityService service;

  setUp(() {
    mockConnectivity = MockConnectivity();
    service = ConnectivityService(connectivity: mockConnectivity);
  });

  tearDown(() {
    mockConnectivity.dispose();
  });

  group('ConnectivityService', () {
    test('isOnline returns true when result is wifi', () async {
      mockConnectivity.checkResults = [ConnectivityResult.wifi];
      expect(await service.isOnline, isTrue);
    });

    test('isOnline returns true when result is mobile', () async {
      mockConnectivity.checkResults = [ConnectivityResult.mobile];
      expect(await service.isOnline, isTrue);
    });

    test('isOnline returns false when result is none', () async {
      mockConnectivity.checkResults = [ConnectivityResult.none];
      expect(await service.isOnline, isFalse);
    });

    test('isOnline returns false when result is empty', () async {
      mockConnectivity.checkResults = [];
      expect(await service.isOnline, isFalse);
    });

    test(
      'onlineStream emits true/false based on connectivity changes',
      () async {
        // onlineStream yields initial status first
        mockConnectivity.checkResults = [ConnectivityResult.wifi];

        expect(service.onlineStream(), emitsInOrder([true, false, true]));

        // Trigger changes
        await Future<void>.delayed(Duration.zero);
        mockConnectivity.emit([ConnectivityResult.none]);

        await Future<void>.delayed(Duration.zero);
        mockConnectivity.emit([ConnectivityResult.mobile]);
      },
    );
  });
}
