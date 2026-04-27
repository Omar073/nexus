import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_wheel_column.dart';

class NexusTimePickerInlineEditor extends StatelessWidget {
  const NexusTimePickerInlineEditor({
    super.key,
    required this.isEditing,
    required this.wheel,
    required this.selectedColor,
    required this.textStyle,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onTapOutside,
    this.onChanged,
    required this.textInputAction,
    this.width = 74,
  });

  final bool isEditing;
  final Widget wheel;
  final Color selectedColor;
  final TextStyle? textStyle;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final TapRegionCallback onTapOutside;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IgnorePointer(ignoring: isEditing, child: wheel),
        if (isEditing)
          Align(
            alignment: Alignment.center,
            child: Container(
              width: width,
              height: nexusTimePickerWheelItemExtent,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlign: TextAlign.center,
                style: textStyle,
                keyboardType: TextInputType.number,
                maxLength: 2,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                textInputAction: textInputAction,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                onTapOutside: onTapOutside,
              ),
            ),
          ),
      ],
    );
  }
}
