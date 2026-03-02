import 'package:flutter/material.dart';
import 'package:nexus/features/tasks/domain/entities/task_entity.dart';
import 'package:nexus/features/tasks/presentation/widgets/tiles/task_item_content.dart';

/// Task item card for task lists.
/// Shows task title, due time, and actions.
/// Supports slide + fade animation when toggling completion.
class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onDelete,
    this.isOverdue = false,
    this.isCompleted = false,
    this.animateExit = false,
    this.isSelected = false,
  });

  final TaskEntity task;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isOverdue;
  final bool isCompleted;

  /// When true, toggling completion will animate before calling onToggle.
  final bool animateExit;

  /// Whether this task is currently selected in multi-select mode.
  final bool isSelected;

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _sizeAnimation;

  bool _isAnimating = false;
  bool? _pendingToggleValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _sizeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Slide direction will be set dynamically
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0), // Default: slide right
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _pendingToggleValue != null) {
        widget.onToggle(_pendingToggleValue!);
        _pendingToggleValue = null;
        _isAnimating = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleToggle(bool newValue) {
    if (widget.animateExit && !_isAnimating) {
      setState(() {
        _isAnimating = true;
        _pendingToggleValue = newValue;

        // Determine slide direction based on action
        // Marking as done (newValue = true) -> slide right
        // Marking as undone (newValue = false) -> slide left
        final slideEnd = newValue
            ? const Offset(1.0, 0.0) // Slide right
            : const Offset(-1.0, 0.0); // Slide left

        _slideAnimation = Tween<Offset>(
          begin: Offset.zero,
          end: slideEnd,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      });

      _controller.forward(from: 0.0);
    } else if (!_isAnimating) {
      widget.onToggle(newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = TaskItemContent(
      task: widget.task,
      isCompleted: widget.isCompleted,
      isOverdue: widget.isOverdue,
      onToggle: _handleToggle,
      onTap: widget.onTap,
      onDelete: widget.onDelete,
      isSelected: widget.isSelected,
    );

    // If animating, wrap with slide + fade + size transitions
    if (_isAnimating) {
      content = SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SizeTransition(
            sizeFactor: _sizeAnimation,
            axisAlignment: -1.0,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
