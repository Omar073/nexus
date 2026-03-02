import 'package:flutter/material.dart';
import 'package:nexus/features/wrapper/presentation/pages/app_wrapper.dart';

class AppDrawerButton extends StatelessWidget {
  const AppDrawerButton({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu, color: color),
      onPressed: () {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold != null && scaffold.hasDrawer) {
          scaffold.openDrawer();
        } else {
          AppWrapper.scaffoldKey.currentState?.openDrawer();
        }
      },
      tooltip: 'Open menu',
    );
  }
}
