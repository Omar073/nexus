import 'dart:collection';

import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceCalendarPlugin extends Fake implements DeviceCalendarPlugin {
  bool permissionsGranted = true;
  List<Calendar> calendars = [];
  String? newEventId;
  Event? lastEvent;

  @override
  Future<Result<bool>> requestPermissions() async {
    final res = Result<bool>();
    // Property 'isSuccess' isn't defined for the class 'Result<bool>'?
    // If Result is from device_calendar, it SHOULD have isSuccess.
    // If it's a getter, I can't set it.
    // But requestPermissions passed?
    // Let's assume it has public field or setter.
    // I can't know for sure without checking source, but I'll try.
    // Actually, looking at device_calendar source (if I could), Result usually has data and errorMessages.
    // isSuccess is typically a getter: boolean get isSuccess => errorMessages.isEmpty;
    // So if errorMessages is empty, it returns true?
    // Exception: requestPermissions test passed. createEvent failed.
    // createEvent: returns Result<String>.
    // Maybe newEventId is string, so not null.
    // If I return res with data set, isSuccess should be true?
    res.data = permissionsGranted;
    return res;
  }

  @override
  Future<Result<UnmodifiableListView<Calendar>>> retrieveCalendars() async {
    final res = Result<UnmodifiableListView<Calendar>>();
    res.data = UnmodifiableListView(calendars);
    return res;
  }

  @override
  Future<Result<String>?> createOrUpdateEvent(Event? event) async {
    lastEvent = event;
    final res = Result<String>();
    res.data = newEventId;
    // ensure isSuccess is true if possible.
    // If unmodifiable, maybe I need to use constructor?
    // Result() constructor?
    return res;
  }
}
