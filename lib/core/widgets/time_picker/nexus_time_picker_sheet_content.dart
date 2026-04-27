import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_inline_editor.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_wheel_column.dart';
import 'package:wheel_picker/wheel_picker.dart';

enum NexusTimePickerInlineField { hour, minute }

class NexusTimePickerSheetContent extends StatelessWidget {
  const NexusTimePickerSheetContent({
    super.key,
    required this.title,
    required this.textStyle,
    required this.selectedOverlayColor,
    required this.use24Hour,
    required this.minuteInterval,
    required this.hourController,
    required this.minuteController,
    required this.periodController,
    required this.inlineEditField,
    required this.inlineInputController,
    required this.inlineInputFocusNode,
    required this.onCancel,
    required this.onDone,
    required this.onStartHourInlineEdit,
    required this.onStartMinuteInlineEdit,
    required this.onHourChanged,
    required this.onMinuteChanged,
    required this.onPeriodChanged,
    required this.onHourInputChanged,
    required this.onInlineSubmitted,
    required this.onInlineTapOutside,
  });

  final String title;
  final TextStyle? textStyle;
  final Color selectedOverlayColor;
  final bool use24Hour;
  final int minuteInterval;
  final WheelPickerController hourController;
  final WheelPickerController minuteController;
  final WheelPickerController? periodController;
  final NexusTimePickerInlineField? inlineEditField;
  final TextEditingController inlineInputController;
  final FocusNode inlineInputFocusNode;
  final VoidCallback onCancel;
  final VoidCallback onDone;
  final VoidCallback onStartHourInlineEdit;
  final VoidCallback onStartMinuteInlineEdit;
  final ValueChanged<int> onHourChanged;
  final ValueChanged<int> onMinuteChanged;
  final ValueChanged<int> onPeriodChanged;
  final ValueChanged<String> onHourInputChanged;
  final ValueChanged<NexusTimePickerInlineField> onInlineSubmitted;
  final VoidCallback onInlineTapOutside;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            TextButton(onPressed: onCancel, child: const Text('Cancel')),
            FilledButton(onPressed: onDone, child: const Text('Done')),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: nexusTimePickerWheelItemExtent * nexusTimePickerVisibleRows,
          child: Row(
            children: [
              Expanded(
                child: _buildEditableColumn(
                  field: NexusTimePickerInlineField.hour,
                  wheel: NexusTimePickerWheelColumn(
                    onTap: onStartHourInlineEdit,
                    controller: hourController,
                    looping: true,
                    selectedColor: selectedOverlayColor,
                    textStyle: textStyle,
                    labelBuilder: (index) => use24Hour
                        ? index.toString().padLeft(2, '0')
                        : (index + 1).toString(),
                    onChanged: onHourChanged,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(':', style: textStyle),
              ),
              Expanded(
                child: _buildEditableColumn(
                  field: NexusTimePickerInlineField.minute,
                  wheel: NexusTimePickerWheelColumn(
                    onTap: onStartMinuteInlineEdit,
                    controller: minuteController,
                    looping: true,
                    selectedColor: selectedOverlayColor,
                    textStyle: textStyle,
                    labelBuilder: (index) =>
                        (index * minuteInterval).toString().padLeft(2, '0'),
                    onChanged: onMinuteChanged,
                  ),
                ),
              ),
              if (!use24Hour && periodController != null)
                Expanded(
                  child: NexusTimePickerWheelColumn(
                    controller: periodController!,
                    looping: false,
                    selectedColor: selectedOverlayColor,
                    textStyle: theme.textTheme.titleLarge,
                    labelBuilder: (index) => index == 0 ? 'AM' : 'PM',
                    onChanged: onPeriodChanged,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableColumn({
    required NexusTimePickerInlineField field,
    required Widget wheel,
  }) {
    final isEditing = inlineEditField == field;
    return NexusTimePickerInlineEditor(
      isEditing: isEditing,
      wheel: wheel,
      selectedColor: selectedOverlayColor,
      textStyle: textStyle,
      controller: inlineInputController,
      focusNode: inlineInputFocusNode,
      textInputAction: field == NexusTimePickerInlineField.hour
          ? TextInputAction.next
          : TextInputAction.done,
      onChanged: field == NexusTimePickerInlineField.hour
          ? onHourInputChanged
          : null,
      onSubmitted: (_) => onInlineSubmitted(field),
      onTapOutside: (_) => onInlineTapOutside(),
    );
  }
}
