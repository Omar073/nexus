import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:rive/rive.dart';

import 'rive_icon_gallery_body.dart';
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
          RiveIconGalleryBody(
            controllers: _controllers,
            sectionTitles: _sectionTitles,
            pulseCallbacks: _pulseCallbacks,
            onPulse: _pulse,
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
