import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

import 'rive_icon_gallery_config.dart';

class RiveIconGalleryPulseResolver {
  const RiveIconGalleryPulseResolver._();

  static VoidCallback? build({
    required RiveWidgetController controller,
    required String assetPath,
    required int tileIndex,
    required List<Timer?> triggerResetTimers,
    required bool Function() isMounted,
  }) {
    final sm = controller.stateMachine;

    if (assetPath == kSomIconAnimationRivPath) {
      return _buildSomPulse(
        sm: sm,
        tileIndex: tileIndex,
        triggerResetTimers: triggerResetTimers,
        isMounted: isMounted,
      );
    }

    if (assetPath == kAnimatedIconSetRivPath) {
      final namedTriggerPulse = _buildNamedTriggerPulse(
        sm: sm,
        tileIndex: tileIndex,
        triggerResetTimers: triggerResetTimers,
        isMounted: isMounted,
        triggerNames: kAnimatedIconSetPulseTriggerNames,
      );
      if (namedTriggerPulse != null) return namedTriggerPulse;

      final firstTriggerPulse = _buildFirstTriggerPulse(
        sm: sm,
        tileIndex: tileIndex,
        triggerResetTimers: triggerResetTimers,
        isMounted: isMounted,
      );
      if (firstTriggerPulse != null) return firstTriggerPulse;
    }

    final boolPulse = _buildBooleanPulse(sm: sm, isMounted: isMounted);
    if (boolPulse != null) return boolPulse;

    return _buildPointerPulse(
      sm: sm,
      artboard: controller.artboard,
      pointerId: tileIndex,
      isMounted: isMounted,
    );
  }

  static VoidCallback? _buildSomPulse({
    required StateMachine sm,
    required int tileIndex,
    required List<Timer?> triggerResetTimers,
    required bool Function() isMounted,
  }) {
    // Som icons commonly gate transitions behind hover/active booleans.
    // Drive those alongside trigger input so tap behaves like editor preview.
    // ignore: deprecated_member_use
    final hovered = sm.boolean('isHovered');
    // ignore: deprecated_member_use
    final active = sm.boolean('isActive');
    for (final name in kSomPulseTriggerNames) {
      // ignore: deprecated_member_use
      final trigger = sm.trigger(name);
      if (trigger == null) continue;
      return () {
        if (!isMounted()) return;
        triggerResetTimers[tileIndex]?.cancel();
        hovered?.value = true;
        active?.value = true;
        trigger.fire();
        triggerResetTimers[tileIndex] = Timer(kSecondTriggerDelay, () {
          triggerResetTimers[tileIndex] = null;
          if (!isMounted()) return;
          trigger.fire();
          active?.value = false;
          hovered?.value = false;
        });
      };
    }
    return null;
  }

  static VoidCallback? _buildNamedTriggerPulse({
    required StateMachine sm,
    required int tileIndex,
    required List<Timer?> triggerResetTimers,
    required bool Function() isMounted,
    required List<String> triggerNames,
  }) {
    for (final name in triggerNames) {
      // ignore: deprecated_member_use
      final trigger = sm.trigger(name);
      if (trigger == null) continue;
      return () {
        if (!isMounted()) return;
        triggerResetTimers[tileIndex]?.cancel();
        trigger.fire();
        triggerResetTimers[tileIndex] = Timer(kSecondTriggerDelay, () {
          triggerResetTimers[tileIndex] = null;
          if (!isMounted()) return;
          trigger.fire();
        });
      };
    }
    return null;
  }

  static VoidCallback? _buildFirstTriggerPulse({
    required StateMachine sm,
    required int tileIndex,
    required List<Timer?> triggerResetTimers,
    required bool Function() isMounted,
  }) {
    // Some third-party packs use arbitrary trigger names; fallback to first trigger.
    // ignore: deprecated_member_use
    for (final input in sm.inputs) {
      if (input is! TriggerInput) continue;
      return () {
        if (!isMounted()) return;
        triggerResetTimers[tileIndex]?.cancel();
        input.fire();
        triggerResetTimers[tileIndex] = Timer(kSecondTriggerDelay, () {
          triggerResetTimers[tileIndex] = null;
          if (!isMounted()) return;
          input.fire();
        });
      };
    }
    return null;
  }

  static VoidCallback? _buildBooleanPulse({
    required StateMachine sm,
    required bool Function() isMounted,
  }) {
    const boolNames = [
      'active',
      'Click',
      'click',
      'Hover',
      'hover',
      'isActive',
      'isHovered',
    ];
    for (final name in boolNames) {
      // ignore: deprecated_member_use
      final boolInput = sm.boolean(name);
      if (boolInput == null) continue;
      return () {
        if (!isMounted()) return;
        boolInput.value = true;
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (!isMounted()) return;
            boolInput.value = false;
          }),
        );
      };
    }

    // Final boolean fallback for packs that use custom boolean names.
    // ignore: deprecated_member_use
    for (final input in sm.inputs) {
      if (input is! BooleanInput) continue;
      return () {
        if (!isMounted()) return;
        input.value = true;
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 900), () {
            if (!isMounted()) return;
            input.value = false;
          }),
        );
      };
    }
    return null;
  }

  static VoidCallback _buildPointerPulse({
    required StateMachine sm,
    required Artboard artboard,
    required int pointerId,
    required bool Function() isMounted,
  }) {
    return () {
      if (!isMounted()) return;
      final pos = Vec2D.fromValues(artboard.width * 0.5, artboard.height * 0.5);
      sm.pointerDown(pos, pointerId: pointerId);
      sm.pointerUp(pos, pointerId: pointerId);
    };
  }
}
