import 'package:flutter/material.dart';

/// App-wide bottom-sheet helper with safe defaults for Android system insets.
Future<T?> showNexusBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = true,
  bool useSafeArea = true,
  bool isDismissible = true,
  bool enableDrag = true,
  bool? showDragHandle,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
  BoxConstraints? constraints,
  RouteSettings? routeSettings,
  AnimationController? transitionAnimationController,
  Offset? anchorPoint,
  AnimationStyle? sheetAnimationStyle,
  bool requestFocus = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    shape: shape,
    clipBehavior: clipBehavior,
    constraints: constraints,
    routeSettings: routeSettings,
    transitionAnimationController: transitionAnimationController,
    anchorPoint: anchorPoint,
    sheetAnimationStyle: sheetAnimationStyle,
    requestFocus: requestFocus,
  );
}
