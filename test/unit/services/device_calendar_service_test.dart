import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus/core/services/platform/device_calendar_service.dart';

import '../../helpers/fake_device_calendar_plugin.dart';

void main() {
  late FakeDeviceCalendarPlugin plugin;
  late DeviceCalendarService service;

  setUp(() {
    plugin = FakeDeviceCalendarPlugin();
    service = DeviceCalendarService(plugin: plugin);
  });

  group('DeviceCalendarService', () {
    test('requestPermissions returns result data', () async {
      plugin.permissionsGranted = true;
      expect(await service.requestPermissions(), isTrue);

      plugin.permissionsGranted = false;
      expect(await service.requestPermissions(), isFalse);
    });

    test('retrieveCalendars returns list from plugin', () async {
      final calendar = Calendar(id: 'c1', name: 'Test Calendar');
      plugin.calendars = [calendar];

      final results = await service.retrieveCalendars();
      expect(results.length, 1);
      expect(results.first.id, 'c1');
    });
  });
}
