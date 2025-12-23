import 'package:flutter/material.dart';
import 'package:nexus/core/extensions/l10n_x.dart';

class NotesPlaceholderScreen extends StatelessWidget {
  const NotesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navNotes)),
      body: Center(child: Text(l10n.comingSoon)),
    );
  }
}


