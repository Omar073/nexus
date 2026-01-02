import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nexus/core/widgets/circular_checkbox.dart';
import 'package:nexus/features/tasks/models/task.dart';

/// Task item card for task lists.
/// Shows task title, due time, and actions.
/// Supports slide + fade animation when toggling completion.
class TaskItem extends StatefulWidget {
  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    this.onTap,
    this.isOverdue = false,
    this.isCompleted = false,
    this.animateExit = false,
  });

  final Task task;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final bool isOverdue;
  final bool isCompleted;

  /// When true, toggling completion will animate before calling onToggle.
  final bool animateExit;

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget content = GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isCompleted
              ? (isDark ? Colors.black : Colors.grey.shade50)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(
                    alpha: widget.isCompleted ? 0.05 : 0.1,
                  )
                : (widget.isCompleted
                      ? Colors.grey.shade100
                      : Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            CircularCheckbox(
              value: widget.isCompleted,
              onChanged: _handleToggle,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration: widget.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.task.startDate != null ||
                      widget.task.dueDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (widget.isOverdue) ...[
                          Icon(
                            Icons.error_outline,
                            size: 14,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          _formatTaskDuration(widget.task),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: widget.isOverdue
                                ? Colors.red.shade400
                                : widget.isCompleted
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
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

  String _formatTaskDuration(Task task) {
    if (task.startDate == null && task.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String format(DateTime d) {
      final date = DateTime(d.year, d.month, d.day);
      if (date == today) {
        return 'Today';
      }
      final diff = date.difference(today).inDays.abs();
      if (diff < 7) {
        return DateFormat('EEE, MMM d').format(d);
      }
      return DateFormat('MMM d').format(d);
    }

    if (task.startDate != null && task.dueDate != null) {
      return '${format(task.startDate!)} - ${format(task.dueDate!)}';
    }

    if (task.startDate != null) {
      return 'Starts ${format(task.startDate!)}';
    }

    return 'Due ${format(task.dueDate!)}';
  }
}
