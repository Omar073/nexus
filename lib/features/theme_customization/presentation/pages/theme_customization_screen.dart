import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexus/features/settings/presentation/state_management/settings_controller.dart';
import 'package:nexus/features/theme_customization/presentation/widgets/colors/color_section.dart';
import 'package:nexus/features/theme_customization/presentation/logic/theme_customization_logic.dart';

/// Colors, presets, and nav bar style tuning.
class ThemeCustomizationScreen extends StatefulWidget {
  const ThemeCustomizationScreen({super.key});

  @override
  State<ThemeCustomizationScreen> createState() =>
      _ThemeCustomizationScreenState();
}

class _ThemeCustomizationScreenState extends State<ThemeCustomizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _currentTabIndex;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    // TabController will be created in didChangeDependencies
    // when we have access to context
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize TabController only once with correct initial index
    if (!_isControllerInitialized) {
      final settings = context.read<SettingsController>();
      _currentTabIndex = initialThemeTabIndex(settings);
      _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: _currentTabIndex,
      );
      _tabController.addListener(_onTabChanged);
      _isControllerInitialized = true;
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging == false) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    if (_isControllerInitialized) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch controller for changes to rebuild UI when colors change
    final settings = context.watch<SettingsController>();
    final isLight = _currentTabIndex == 0;
    final previewTheme = buildThemeCustomizationPreviewTheme(
      settings: settings,
      isLight: isLight,
    );

    return AnimatedTheme(
      data: previewTheme,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Customize Appearance'),
            actions: [
              IconButton(
                onPressed: () => saveThemePresetWithFeedback(
                  context: context,
                  settings: context.read<SettingsController>(),
                ),
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save as preset',
              ),
              TextButton(
                onPressed: () => resetThemeColorsWithFeedback(
                  context: context,
                  settings: context.read<SettingsController>(),
                ),
                child: Text(
                  'Reset',
                  style: TextStyle(color: previewTheme.colorScheme.primary),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Light Theme'),
                Tab(text: 'Dark Theme'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              ColorSection(
                brightness: Brightness.light,
                currentPrimary: settings.lightColors.primary,
                currentSecondary: settings.lightColors.secondary,
                defaultPrimary: const Color(0xFF3F51B5),
                defaultSecondary: const Color(0xFF009688),
              ),
              ColorSection(
                brightness: Brightness.dark,
                currentPrimary: settings.darkColors.primary,
                currentSecondary: settings.darkColors.secondary,
                defaultPrimary: const Color(0xFF9FA8DA),
                defaultSecondary: const Color(0xFF80CBC4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
