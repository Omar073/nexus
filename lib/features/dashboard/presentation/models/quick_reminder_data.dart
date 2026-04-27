import 'package:flutter/material.dart';

/// View-model for a quick reminder card.
class QuickReminderData {
  const QuickReminderData({
    required this.timeLabel,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  final String timeLabel;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
}
