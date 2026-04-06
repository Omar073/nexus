import 'package:flutter/material.dart';
import 'package:nexus/core/services/debug/debug_logger_service.dart';
import 'package:nexus/app/app_globals.dart';

/// Common snackbar utility for displaying snackbars throughout the app
///
/// Provides a simple API to show snackbars with just a message and color.
/// Can be used from anywhere in the app with access to BuildContext.
class CommonSnackbar {
  /// Shows a snackbar using the global ScaffoldMessenger key
  ///
  /// Can be called from anywhere without BuildContext (e.g., from services).
  ///
  /// [message] - Message to display
  /// [backgroundColor] - Background color of the snackbar
  /// [duration] - Optional duration (defaults to 3 seconds)
  static void showGlobal(
    String message,
    Color backgroundColor, {
    Duration? duration,
  }) {
    final messenger = appMessengerKey.currentState;
    if (messenger == null) {
      mDebugPrint('Warning: ScaffoldMessenger not available');
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shows a snackbar with the given message and background color
  ///
  /// [context] - BuildContext to show the snackbar
  /// [message] - Message to display
  /// [backgroundColor] - Background color of the snackbar
  /// [duration] - Optional duration (defaults to 3 seconds)
  static void show(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Duration? duration,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Extension method for easier usage: `context.showSnackbar(message, color)`
  static void showSnackbar(
    BuildContext context,
    String message,
    Color backgroundColor, {
    Duration? duration,
  }) {
    show(context, message, backgroundColor, duration: duration);
  }
}

/// Extension on BuildContext for easier snackbar usage
extension SnackbarExtension on BuildContext {
  /// Shows a snackbar with the given message and background color
  ///
  /// Example: `context.showSnackbar('Hello', Colors.green)`
  void showSnackbar(
    String message,
    Color backgroundColor, {
    Duration? duration,
  }) {
    CommonSnackbar.show(this, message, backgroundColor, duration: duration);
  }
}
