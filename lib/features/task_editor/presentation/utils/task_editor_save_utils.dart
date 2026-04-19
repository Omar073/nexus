import 'package:flutter/material.dart';

DateTime? buildDueDateTime(DateTime? dueDate, TimeOfDay? dueTime) {
  if (dueDate == null) return null;
  return DateTime(
    dueDate.year,
    dueDate.month,
    dueDate.day,
    dueTime?.hour ?? 0,
    dueTime?.minute ?? 0,
  );
}

String? optionalDescription(String rawText) {
  return rawText.trim().isEmpty ? null : rawText;
}
