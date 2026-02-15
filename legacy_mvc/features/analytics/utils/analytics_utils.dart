import 'package:flutter/material.dart';

/// Returns a color based on the progress ratio.
/// - Green if >= 80%
/// - Orange if >= 50%
/// - Red otherwise
/// - Grey if total is 0
Color getProgressColor(int done, int total) {
  if (total == 0) return Colors.grey;
  final ratio = done / total;
  if (ratio >= 0.8) return Colors.green;
  if (ratio >= 0.5) return Colors.orange;
  return Colors.red;
}

/// Calculates the completion rate as a percentage string.
String getCompletionRate(int completed, int active) {
  final total = completed + active;
  if (total == 0) return '0%';
  return '${(completed / total * 100).round()}%';
}

/// Calculates the on-time rate (non-overdue) as a percentage string.
String getOnTimeRate(int overdue, int active) {
  if (active == 0) return '100%';
  final onTime = active - overdue;
  return '${(onTime / active * 100).round()}%';
}
