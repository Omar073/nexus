import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';

class RemindersPlaceholderScreen extends StatelessWidget {
  const RemindersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navReminders)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}


