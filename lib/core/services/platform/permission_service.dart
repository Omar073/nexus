import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Wraps OS permission prompts (mic, notifications, etc.).

class PermissionService {
  Future<bool> ensureNotifications() async {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  Future<bool> ensureMicrophone() async {
    if (kIsWeb) return false;
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<bool> ensureCamera() async {
    if (kIsWeb) return false;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> ensureGalleryRead() async {
    if (kIsWeb) return false;
    // Android 13+ uses READ_MEDIA_IMAGES; permission_handler maps via photos.
    if (Platform.isAndroid) {
      final p1 = await Permission.photos.request();
      if (p1.isGranted) return true;
      final p2 = await Permission.storage.request();
      return p2.isGranted;
    }
    final status = await Permission.photos.request();
    return status.isGranted;
  }
}
