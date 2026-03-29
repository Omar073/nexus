import 'package:flutter/material.dart';

/// Scrolls the task list to a chosen category.
class CategoryScrollHelper {
  CategoryScrollHelper({
    required this.categoryKeys,
    required this.getCurrentTabIndex,
  });

  /// Map of category keys keyed by "tabIndex:categoryId"
  final Map<String, GlobalKey> categoryKeys;

  /// Function to get the current tab index
  final int Function() getCurrentTabIndex;

  /// Scroll to a specific category section.
  void scrollToCategory(String? categoryId, {required bool mounted}) {
    final keyStr = '${getCurrentTabIndex()}:$categoryId';
    final key = categoryKeys[keyStr];

    // Early exit if no valid context
    if (key?.currentContext == null) return;

    // Capture references before async gap
    final targetContext = key!.currentContext!;
    final scrollable = Scrollable.maybeOf(targetContext);
    if (scrollable == null) return;

    final targetRenderObject = targetContext.findRenderObject() as RenderBox?;
    final scrollableRenderObject =
        scrollable.context.findRenderObject() as RenderBox?;
    if (targetRenderObject == null || scrollableRenderObject == null) return;

    final scrollPosition = scrollable.position;

    // Use post-frame callback to ensure scroll happens after bottom sheet closes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        // Calculate the target's position relative to the scrollable viewport
        final targetOffset = targetRenderObject.localToGlobal(
          Offset.zero,
          ancestor: scrollableRenderObject,
        );

        // Calculate the new scroll offset
        final currentOffset = scrollPosition.pixels;
        const headerOffset = 48.0;
        final targetScrollOffset =
            currentOffset + targetOffset.dy - headerOffset;

        // Clamp to valid scroll range
        final clampedOffset = targetScrollOffset.clamp(
          scrollPosition.minScrollExtent,
          scrollPosition.maxScrollExtent,
        );

        // Animate to the target position
        // ignore: unawaited_futures
        scrollPosition.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    });
  }
}
