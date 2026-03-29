import 'package:flutter/material.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:provider/provider.dart';

/// Retention, auto-delete, and sort preferences.
class TaskManagementSection extends StatelessWidget {
  const TaskManagementSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Task Management', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-delete completed tasks'),
          subtitle: const Text('Automatically delete old completed tasks'),
          value: controller.autoDeleteCompletedTasks,
          onChanged: (v) => controller.setAutoDeleteCompletedTasks(v),
        ),
        if (controller.autoDeleteCompletedTasks) ...[
          const SizedBox(height: 8),
          Text(
            'Completed retention (days)',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: controller.completedRetentionDays.toDouble(),
                  min: 1,
                  max: 365,
                  divisions: 364,
                  label: controller.completedRetentionDays.toString(),
                  onChanged: (v) =>
                      controller.setCompletedRetentionDays(v.round()),
                ),
              ),
              SizedBox(
                width: 56,
                child: Text(
                  controller.completedRetentionDays.toString(),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
