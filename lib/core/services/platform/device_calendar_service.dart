import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// Minimal device calendar export/import helper.
///
/// Phase 3 scope: list calendars + create events. Import can be added later.
class DeviceCalendarService {
  DeviceCalendarService({DeviceCalendarPlugin? plugin})
      : _plugin = plugin ?? DeviceCalendarPlugin();

  final DeviceCalendarPlugin _plugin;

  Future<bool> requestPermissions() async {
    final result = await _plugin.requestPermissions();
    return result.isSuccess && (result.data ?? false);
  }

  Future<List<Calendar>> retrieveCalendars() async {
    final result = await _plugin.retrieveCalendars();
    return result.data ?? const <Calendar>[];
  }

  Future<String?> createEvent({
    required String calendarId,
    required String title,
    required DateTime start,
    DateTime? end,
    String? description,
  }) async {
    final event = Event(
      calendarId,
      title: title,
      description: description,
      start: tz.TZDateTime.from(start, tz.local),
      end: tz.TZDateTime.from(
        end ?? start.add(const Duration(minutes: 30)),
        tz.local,
      ),
    );
    final result = await _plugin.createOrUpdateEvent(event);
    if (result == null) return null;
    if (!result.isSuccess) return null;
    return result.data;
  }
}

