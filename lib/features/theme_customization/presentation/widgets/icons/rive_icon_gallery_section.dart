import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:rive/rive.dart';

import 'rive_icon_gallery_config.dart';
import 'rive_icon_gallery_pulse_resolver.dart';

/// Previews every artboard in each bundled `.riv` file (discovered at runtime).
class RiveIconGallerySection extends StatefulWidget {
  const RiveIconGallerySection({super.key});

  @override
  State<RiveIconGallerySection> createState() => _RiveIconGallerySectionState();
}

class _RiveIconGallerySectionState extends State<RiveIconGallerySection> {
  final List<RiveWidgetController> _controllers = [];

  /// Per-tile tap action (Som: trigger fire; other file: `active` boolean pulse).
  final List<VoidCallback?> _pulseCallbacks = [];

  final List<File> _files = [];

  /// Flat list aligned with [_controllers] / [_pulseCallbacks].
  final List<String> _sectionTitles = [];

  /// Trigger-driven tiles: delayed second fire to return to idle.
  final List<Timer?> _triggerResetTimers = [];

  bool _loaded = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAll());
  }

  Future<List<String>> _enumerateArtboardNames(File file) async {
    final names = <String>[];
    for (var i = 0; i < 512; i++) {
      final ab = file.artboardAt(i);
      if (ab == null) break;
      names.add(ab.name);
      ab.dispose();
    }
    return names;
  }

  Future<void> _loadAll() async {
    try {
      for (final (path, sectionTitle) in kRiveGallerySources) {
        final file = await File.asset(path, riveFactory: Factory.flutter);
        if (file == null) {
          mDebugPrint('[RiveIconGallerySection] Missing asset: $path');
          continue;
        }
        _files.add(file);

        final names = await _enumerateArtboardNames(file);
        for (final name in names) {
          if ((path == kSomIconAnimationRivPath &&
                  kSomIconAnimationSkippedArtboards.contains(name)) ||
              (path == kAnimatedIconSetRivPath &&
                  kAnimatedIconSetSkippedArtboards.contains(name))) {
            continue;
          }
          try {
            final controller = RiveWidgetController(
              file,
              artboardSelector: ArtboardSelector.byName(name),
              stateMachineSelector: StateMachineSelector.byDefault(),
            );

            final tileIndex = _controllers.length;
            _controllers.add(controller);
            _triggerResetTimers.add(null);
            _pulseCallbacks.add(
              RiveIconGalleryPulseResolver.build(
                controller: controller,
                assetPath: path,
                tileIndex: tileIndex,
                triggerResetTimers: _triggerResetTimers,
                isMounted: () => mounted,
              ),
            );
            _sectionTitles.add(sectionTitle);
          } catch (e) {
            mDebugPrint(
              '[RiveIconGallerySection] Skip artboard "$name" in $path: $e',
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _loaded = true;
          if (_controllers.isEmpty) {
            _loadError = 'No Rive artboards could be loaded.';
          }
        });
      }
    } catch (e, st) {
      mDebugPrint('[RiveIconGallerySection] Failed to load: $e\n$st');
      if (mounted) {
        setState(() {
          _loaded = true;
          _loadError = 'Could not load Rive assets.';
        });
      }
    }
  }

  void _pulse(int index) {
    _pulseCallbacks[index]?.call();
  }

  @override
  void dispose() {
    for (final t in _triggerResetTimers) {
      t?.cancel();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _files) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Animated icons (Rive)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'All artboards from the bundled .riv files. Tap to play '
                '(trigger or `active` input when available).',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!_loaded)
          SizedBox(
            height: kRiveGalleryBodyReservedHeight,
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_loadError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Text(
              _loadError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          )
        else
          _buildGallery(theme),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildGallery(ThemeData theme) {
    final bySection = <String, List<int>>{};
    for (var i = 0; i < _controllers.length; i++) {
      final title = _sectionTitles[i];
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
                return _buildTile(theme, globalIndex);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTile(ThemeData theme, int index) {
    final hasPulse = _pulseCallbacks[index] != null;
    final ab = _controllers[index].artboard;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasPulse ? () => _pulse(index) : null,
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
                child: IgnorePointer(
                  // Prevent Rive state machines from also consuming pointer
                  // events (hover/click loops). Taps are handled by InkWell.
                  child: RiveWidget(controller: _controllers[index]),
                ),
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
