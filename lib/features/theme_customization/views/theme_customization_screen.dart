import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/theme_customization/views/widgets/colors/color_section.dart';
import 'package:nexus/features/theme_customization/views/widgets/presets/save_preset_dialog.dart';

/// Screen for customizing app theme colors
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
      final isDark = settings.themeMode == ThemeMode.dark;
      _currentTabIndex = isDark ? 1 : 0;
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

    // Build theme colors based on current tab
    final previewPrimary = isLight
        ? (settings.lightColors.primary ?? const Color(0xFF3F51B5))
        : (settings.darkColors.primary ?? const Color(0xFF9FA8DA));

    // Create preview theme for the app bar
    final previewTheme = isLight
        ? ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: previewPrimary,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.black87,
              elevation: 0,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: previewPrimary,
              unselectedLabelColor: Colors.black54,
              indicatorColor: previewPrimary,
            ),
          )
        : ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: previewPrimary,
              surface: const Color(0xFF000000),
              onSurface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF000000),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            tabBarTheme: TabBarThemeData(
              labelColor: previewPrimary,
              unselectedLabelColor: Colors.white54,
              indicatorColor: previewPrimary,
            ),
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
                onPressed: () async {
                  final name = await SavePresetDialog.show(context);
                  if (name != null && context.mounted) {
                    context.read<SettingsController>().saveCurrentAsPreset(
                      name,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved preset "$name"')),
                    );
                  }
                },
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Save as preset',
              ),
              TextButton(
                onPressed: () {
                  context.read<SettingsController>().resetColors();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Colors reset to defaults')),
                  );
                },
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
          bottomNavigationBar: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: isLight ? Colors.white : const Color(0xFF000000),
              end: isLight ? Colors.white : const Color(0xFF000000),
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (context, bgColor, child) {
              return NavigationBar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                backgroundColor: bgColor,
                indicatorColor: previewPrimary.withValues(alpha: 0.2),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.checklist_outlined, color: previewPrimary),
                    selectedIcon: Icon(Icons.checklist, color: previewPrimary),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.note_outlined,
                      color: isLight ? Colors.black54 : Colors.white54,
                    ),
                    label: 'Notes',
                  ),
                  NavigationDestination(
                    icon: Icon(
                      Icons.settings_outlined,
                      color: isLight ? Colors.black54 : Colors.white54,
                    ),
                    label: 'Settings',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
