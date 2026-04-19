import 'package:flutter/material.dart';

/// Global safe-area wrapper for the full app tree.
///
/// Keeps all content above Android/iOS system insets (including navigation
/// bars and cutouts) without needing per-screen SafeArea guards.
class NexusRootSafeArea extends StatelessWidget {
  const NexusRootSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(maintainBottomViewPadding: true, child: child);
  }
}
