import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/wrapper/views/app_drawer.dart';
import 'package:nexus/features/wrapper/views/widgets/nav_bar_builder.dart';
import 'package:provider/provider.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    return Scaffold(
      drawer: const AppDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavBarBuilder(
        style: navBarStyle,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
      ),
    );
  }
}
