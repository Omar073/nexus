import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/bottom_sheet/nexus_bottom_sheet.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_sheet.dart';

/// Shows Nexus shared wheel-style time picker.
Future<TimeOfDay?> showNexusTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
  String title = 'Select time',
  int minuteInterval = 1,
}) {
  return showNexusBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => NexusTimePickerSheet(
      initialTime: initialTime,
      title: title,
      minuteInterval: minuteInterval,
    ),
  );
}
