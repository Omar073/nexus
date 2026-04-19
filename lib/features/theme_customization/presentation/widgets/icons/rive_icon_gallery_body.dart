import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class RiveIconGalleryBody extends StatelessWidget {
  const RiveIconGalleryBody({
    super.key,
    required this.controllers,
    required this.sectionTitles,
    required this.pulseCallbacks,
    required this.onPulse,
  });

  final List<RiveWidgetController> controllers;
  final List<String> sectionTitles;
  final List<VoidCallback?> pulseCallbacks;
  final ValueChanged<int> onPulse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bySection = <String, List<int>>{};
    for (var i = 0; i < controllers.length; i++) {
      final title = sectionTitles[i];
      bySection.putIfAbsent(title, () => []).add(i);
    }

    final sections = bySection.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var s = 0; s < sections.length; s++) ...[
          if (s > 0) const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Collection ${s + 1}',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sections[s].value.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final globalIndex = sections[s].value[i];
                return _RiveIconTile(
                  controller: controllers[globalIndex],
                  hasPulse: pulseCallbacks[globalIndex] != null,
                  onTap: () => onPulse(globalIndex),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _RiveIconTile extends StatelessWidget {
  const _RiveIconTile({
    required this.controller,
    required this.hasPulse,
    required this.onTap,
  });

  final RiveWidgetController controller;
  final bool hasPulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ab = controller.artboard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPulse ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: IgnorePointer(child: RiveWidget(controller: controller)),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 96,
                child: Text(
                  ab.name,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
