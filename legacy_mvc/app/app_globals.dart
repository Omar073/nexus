import 'package:flutter/material.dart';

/// Global ScaffoldMessenger key for showing snackbars from anywhere in the app
///
/// Services and other code can use this key to show snackbars without
/// needing access to BuildContext.
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
