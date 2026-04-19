/// Rolls a selected reminder time to tomorrow when it is not in the future.
DateTime rollReminderTimeToFuture(DateTime selectedTime, {DateTime? now}) {
  final referenceNow = now ?? DateTime.now();
  if (selectedTime.isAfter(referenceNow)) {
    return selectedTime;
  }
  return selectedTime.add(const Duration(days: 1));
}

/// Formats a duration into a human-readable days/hours/minutes label.
String formatReminderOffsetLabel(Duration duration) {
  var remainingMinutes = duration.inMinutes;
  if (remainingMinutes < 1) remainingMinutes = 1;
  final days = remainingMinutes ~/ (24 * 60);
  remainingMinutes -= days * 24 * 60;
  final hours = remainingMinutes ~/ 60;
  remainingMinutes -= hours * 60;
  final minutes = remainingMinutes;

  final parts = <String>[];
  if (days > 0) {
    parts.add('$days ${days == 1 ? 'day' : 'days'}');
  }
  if (hours > 0) {
    parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
  }
  if (minutes > 0 || parts.isEmpty) {
    parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
  }
  return parts.join(', ');
}
