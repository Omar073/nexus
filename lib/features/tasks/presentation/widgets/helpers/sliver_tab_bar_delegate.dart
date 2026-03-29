import 'package:flutter/material.dart';

/// Pinned tab bar delegate for task filter tabs.
class SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: backgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(SliverTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}
