import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/wrapper/views/app_drawer.dart';
import 'package:nexus/features/wrapper/views/widgets/nav_bar_builder.dart';
import 'package:provider/provider.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: widget.navigationShell.currentIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AppWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newIndex = widget.navigationShell.currentIndex;
    final currentIndex = _pageController.page?.round() ?? 0;

    if (newIndex != currentIndex) {
      if ((newIndex - currentIndex).abs() > 1) {
        _pageController.jumpToPage(newIndex);
      } else {
        _pageController.animateToPage(
          newIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _onPageChanged(int index) {
    if (index != widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navBarStyle = context.watch<SettingsController>().navBarStyle;

    return Scaffold(
      key: AppWrapper.scaffoldKey,
      drawer: const AppDrawer(),
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: widget.children,
      ),
      bottomNavigationBar: NavBarBuilder(
        style: navBarStyle,
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onTap,
      ),
    );
  }
}
