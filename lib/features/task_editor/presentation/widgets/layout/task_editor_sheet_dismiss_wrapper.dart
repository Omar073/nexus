import 'package:flutter/material.dart';

/// Enables pull-down-to-dismiss from anywhere inside the sheet.
class TaskEditorSheetDismissWrapper extends StatefulWidget {
  const TaskEditorSheetDismissWrapper({
    super.key,
    required this.child,
    required this.onDismiss,
  });

  static const double dismissDragThreshold = 120;

  final Widget child;
  final VoidCallback onDismiss;

  @override
  State<TaskEditorSheetDismissWrapper> createState() =>
      _TaskEditorSheetDismissWrapperState();
}

class _TaskEditorSheetDismissWrapperState
    extends State<TaskEditorSheetDismissWrapper> {
  double _downwardDragDistance = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        final delta = details.primaryDelta ?? 0;
        if (delta > 0) {
          _downwardDragDistance += delta;
        }
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final shouldDismiss =
            _downwardDragDistance >=
                TaskEditorSheetDismissWrapper.dismissDragThreshold ||
            velocity > 1000;
        _downwardDragDistance = 0;
        if (shouldDismiss) {
          widget.onDismiss();
        }
      },
      onVerticalDragCancel: () {
        _downwardDragDistance = 0;
      },
      child: widget.child,
    );
  }
}
