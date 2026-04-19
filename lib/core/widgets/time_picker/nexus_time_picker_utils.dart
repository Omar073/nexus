int normalizeMinute(int minute, int interval) {
  final clamped = minute.clamp(0, 59);
  return (clamped ~/ interval) * interval;
}

int hour12ToIndex(int hour24) {
  final hour12 = hour24To12(hour24);
  return hour12 - 1;
}

int hour24To12(int hour24) {
  if (hour24 == 0) return 12;
  if (hour24 > 12) return hour24 - 12;
  return hour24;
}

int composeHour24(int hour12, int periodIndex) {
  final isPm = periodIndex == 1;
  if (hour12 == 12) {
    return isPm ? 12 : 0;
  }
  return isPm ? hour12 + 12 : hour12;
}
