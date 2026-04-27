import 'package:flutter/material.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_inline_input_utils.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_sheet_content.dart';
import 'package:nexus/core/widgets/time_picker/nexus_time_picker_utils.dart';
import 'package:wheel_picker/wheel_picker.dart';

/// Bottom-sheet wheel picker for selecting a single time value.
class NexusTimePickerSheet extends StatefulWidget {
  const NexusTimePickerSheet({
    super.key,
    required this.initialTime,
    required this.title,
    this.minuteInterval = 1,
  }) : assert(minuteInterval > 0 && minuteInterval <= 30);

  final TimeOfDay initialTime;
  final String title;
  final int minuteInterval;

  @override
  State<NexusTimePickerSheet> createState() => _NexusTimePickerSheetState();
}

class _NexusTimePickerSheetState extends State<NexusTimePickerSheet> {
  late bool _use24Hour;
  WheelPickerController? _hourController;
  WheelPickerController? _minuteController;
  WheelPickerController? _periodController;
  bool _didInitControllers = false;
  late int _hour;
  late int _minute;
  late int _periodIndex;
  late int _lastHourIndex12;
  final TextEditingController _inlineInputController = TextEditingController();
  final FocusNode _inlineInputFocusNode = FocusNode();
  NexusTimePickerInlineField? _inlineEditField;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitControllers) return;
    _didInitControllers = true;
    _use24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    _hour = widget.initialTime.hour;
    _minute = normalizeMinute(widget.initialTime.minute, widget.minuteInterval);
    _periodIndex = _hour >= 12 ? 1 : 0;
    _lastHourIndex12 = hour12ToIndex(_hour);
    _hourController = WheelPickerController(
      itemCount: _use24Hour ? 24 : 12,
      initialIndex: _use24Hour ? _hour : hour12ToIndex(_hour),
    );
    _minuteController = WheelPickerController(
      itemCount: 60 ~/ widget.minuteInterval,
      initialIndex: _minute ~/ widget.minuteInterval,
    );
    if (!_use24Hour) {
      _periodController = WheelPickerController(
        itemCount: 2,
        initialIndex: _periodIndex,
      );
    }
  }

  @override
  void dispose() {
    _inlineInputController.dispose();
    _inlineInputFocusNode.dispose();
    _hourController?.dispose();
    _minuteController?.dispose();
    _periodController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final selectedOverlayColor = theme.colorScheme.primary.withValues(
      alpha: .18,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: NexusTimePickerSheetContent(
        title: widget.title,
        textStyle: textStyle,
        selectedOverlayColor: selectedOverlayColor,
        use24Hour: _use24Hour,
        minuteInterval: widget.minuteInterval,
        hourController: _hourController!,
        minuteController: _minuteController!,
        periodController: _periodController,
        inlineEditField: _inlineEditField,
        inlineInputController: _inlineInputController,
        inlineInputFocusNode: _inlineInputFocusNode,
        onCancel: () {
          _cancelInlineEdit();
          Navigator.of(context).pop();
        },
        onDone: () {
          _commitInlineEdit();
          Navigator.of(context).pop(_selectedTime());
        },
        onStartHourInlineEdit: _startHourInlineEdit,
        onStartMinuteInlineEdit: _startMinuteInlineEdit,
        onHourChanged: _onHourChanged,
        onMinuteChanged: _onMinuteChanged,
        onPeriodChanged: _onPeriodChanged,
        onHourInputChanged: _maybeAutoAdvanceHourInput,
        onInlineSubmitted: (field) {
          _commitInlineEditInternal(
            advanceToMinuteAfterHour: field == NexusTimePickerInlineField.hour,
          );
        },
        onInlineTapOutside: _commitInlineEdit,
      ),
    );
  }

  void _onHourChanged(int index) {
    if (_inlineEditField == NexusTimePickerInlineField.hour) return;
    if (!_use24Hour) {
      final delta = index - _lastHourIndex12;
      if (delta <= -6 || delta >= 6) {
        _periodIndex = (_periodIndex + 1) % 2;
        _periodController?.setCurrent(_periodIndex);
      }
      _lastHourIndex12 = index;
    }
    setState(() {
      _hour = _use24Hour ? index : composeHour24(index + 1, _periodIndex);
    });
  }

  void _onMinuteChanged(int index) {
    if (_inlineEditField == NexusTimePickerInlineField.minute) return;
    setState(() {
      _minute = index * widget.minuteInterval;
    });
  }

  void _startHourInlineEdit() {
    _startInlineEdit(
      NexusTimePickerInlineField.hour,
      _use24Hour ? _hour : hour24To12(_hour),
    );
  }

  void _startMinuteInlineEdit() {
    _startInlineEdit(NexusTimePickerInlineField.minute, _minute);
  }

  void _startInlineEdit(NexusTimePickerInlineField field, int currentValue) {
    setState(() {
      _inlineEditField = field;
      _inlineInputController.text = currentValue.toString().padLeft(2, '0');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _inlineInputFocusNode.requestFocus();
      _inlineInputController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _inlineInputController.text.length,
      );
    });
  }

  void _cancelInlineEdit() {
    _inlineInputFocusNode.unfocus();
    if (_inlineEditField == null) return;
    setState(() {
      _inlineEditField = null;
      _inlineInputController.clear();
    });
  }

  void _commitInlineEdit() {
    _commitInlineEditInternal(advanceToMinuteAfterHour: false);
  }

  void _commitInlineEditInternal({required bool advanceToMinuteAfterHour}) {
    final field = _inlineEditField;
    if (field == null) return;

    final raw = int.tryParse(_inlineInputController.text.trim());
    if (raw == null) {
      _cancelInlineEdit();
      return;
    }
    if (field == NexusTimePickerInlineField.hour) {
      final minHour = _use24Hour ? 0 : 1;
      final maxHour = _use24Hour ? 23 : 12;
      final typed = raw.clamp(minHour, maxHour);
      if (_use24Hour) {
        _hourController?.setCurrent(typed);
        setState(() {
          _hour = typed;
          _inlineEditField = null;
        });
      } else {
        final hourIndex = typed - 1;
        _hourController?.setCurrent(hourIndex);
        setState(() {
          _lastHourIndex12 = hourIndex;
          _hour = composeHour24(typed, _periodIndex);
          _inlineEditField = null;
        });
      }
      _inlineInputController.clear();
      if (advanceToMinuteAfterHour) {
        _startMinuteInlineEdit();
      } else {
        _inlineInputFocusNode.unfocus();
      }
      return;
    }
    final typed = raw.clamp(0, 59);
    final normalized = normalizeMinute(typed, widget.minuteInterval);
    final minuteIndex = normalized ~/ widget.minuteInterval;
    _minuteController?.setCurrent(minuteIndex);
    setState(() {
      _minute = normalized;
      _inlineEditField = null;
    });
    _inlineInputController.clear();
    _inlineInputFocusNode.unfocus();
  }

  void _maybeAutoAdvanceHourInput(String value) {
    if (_inlineEditField != NexusTimePickerInlineField.hour) return;
    if (shouldAutoCommitHourInput(use24Hour: _use24Hour, rawValue: value)) {
      _commitInlineEditInternal(advanceToMinuteAfterHour: true);
    }
  }

  void _onPeriodChanged(int index) {
    setState(() {
      _periodIndex = index;
      _hour = composeHour24(hour24To12(_hour), _periodIndex);
    });
  }

  TimeOfDay _selectedTime() => TimeOfDay(hour: _hour, minute: _minute);
}
