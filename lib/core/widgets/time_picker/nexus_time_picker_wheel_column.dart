import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wheel_picker/wheel_picker.dart';

const double nexusTimePickerWheelItemExtent = 52;
const double nexusTimePickerVisibleRows = 3;

class NexusTimePickerWheelColumn extends StatefulWidget {
  const NexusTimePickerWheelColumn({
    super.key,
    required this.controller,
    required this.looping,
    required this.selectedColor,
    required this.textStyle,
    required this.labelBuilder,
    required this.onChanged,
    this.onTap,
  });

  final WheelPickerController controller;
  final bool looping;
  final Color selectedColor;
  final TextStyle? textStyle;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onChanged;
  final VoidCallback? onTap;

  @override
  State<NexusTimePickerWheelColumn> createState() =>
      _NexusTimePickerWheelColumnState();
}

class _NexusTimePickerWheelColumnState
    extends State<NexusTimePickerWheelColumn> {
  Offset? _downPosition;
  DateTime? _downAt;
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          _downPosition = event.position;
          _downAt = DateTime.now();
          _moved = false;
        },
        onPointerMove: (event) {
          final start = _downPosition;
          if (start == null) return;
          if ((event.position - start).distance > 8) {
            _moved = true;
          }
        },
        onPointerUp: (_) {
          final startedAt = _downAt;
          if (widget.onTap == null || startedAt == null) return;
          final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
          if (!_moved && elapsedMs <= 300) {
            widget.onTap!.call();
          }
        },
        child: WheelPicker(
          controller: widget.controller,
          selectedIndexColor: widget.selectedColor,
          looping: widget.looping,
          style: const WheelPickerStyle(
            itemExtent: nexusTimePickerWheelItemExtent,
            diameterRatio: 1000,
            squeeze: 1.0,
            surroundingOpacity: .38,
            magnification: 1.0,
          ),
          onIndexChanged: (index, _) {
            HapticFeedback.selectionClick();
            widget.onChanged(index);
          },
          builder: (context, index) {
            return Center(
              child: Text(widget.labelBuilder(index), style: widget.textStyle),
            );
          },
        ),
      ),
    );
  }
}
