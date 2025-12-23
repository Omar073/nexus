import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nexus/features/splash/controllers/app_initializer.dart';
import 'package:nexus/features/splash/models/initialization_results.dart';

/// Splash screen that displays app name based on theme and initializes critical services
class SplashScreen extends StatefulWidget {
  final void Function(CriticalInitializationResult) onInitializationComplete;

  const SplashScreen({super.key, required this.onInitializationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitializing = true;
  String? _errorMessage;
  static const Duration _minimumDisplayDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initializeCritical();
  }

  Future<void> _initializeCritical() async {
    try {
      // Start critical initialization and minimum duration timer in parallel
      final initFuture = AppInitializer.initializeCritical();
      final minDurationFuture = Future.delayed(_minimumDisplayDuration);

      // Wait for both to complete
      final results = await Future.wait([initFuture, minDurationFuture]);

      if (!mounted) return;

      // Get the critical initialization result (first item in results)
      final result = results[0] as CriticalInitializationResult;

      if (!mounted) return;

      // Pass result to parent and trigger navigation
      widget.onInitializationComplete(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize app: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    // Determine which image to show based on theme
    // Note: File names are opposite to content - black.jpg contains white text, white.jpg contains black text
    final imageAsset = isDark
        ? 'app_logos/app_name_black.jpg'
        : 'app_logos/app_name_white.jpg';

    // Background color matches theme
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: _errorMessage != null
            ? _buildErrorState()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App name image
                  Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if image fails to load
                      return Text(
                        'NEXUS',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Subtle loading indicator
                  if (_isInitializing)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
                _isInitializing = true;
              });
              _initializeCritical();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
