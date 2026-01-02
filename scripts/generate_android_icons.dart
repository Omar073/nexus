import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:nexus/core/services/debug/debug_logger_service.dart';

void main() async {
  // Source icon path
  final sourceIcon = File('app_logos/app_icon_black.png');
  if (!await sourceIcon.exists()) {
    mPrint('Error: Source icon not found at ${sourceIcon.path}');
    exit(1);
  }

  // Read source image
  final sourceBytes = await sourceIcon.readAsBytes();
  final sourceImage = img.decodeImage(sourceBytes);
  if (sourceImage == null) {
    mPrint('Error: Could not decode source image');
    exit(1);
  }

  // Icon sizes for each density
  final densities = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // Generate icons for each density
  for (final entry in densities.entries) {
    final folder = entry.key;
    final size = entry.value;

    // Resize image
    final resized = img.copyResize(
      sourceImage,
      width: size,
      height: size,
      interpolation: img.Interpolation.cubic,
    );

    // Create output directory if it doesn't exist
    final outputDir = Directory('android/app/src/main/res/$folder');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // Save resized icon
    final outputFile = File('${outputDir.path}/ic_launcher.png');
    final outputBytes = img.encodePng(resized);
    await outputFile.writeAsBytes(outputBytes);

    mPrint('Generated ${outputFile.path} (${size}x$size)');
  }

  mPrint('All Android icons generated successfully!');
}
