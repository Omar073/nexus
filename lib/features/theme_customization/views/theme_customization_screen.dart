import 'package:flutter/material.dart';
import 'package:nexus/features/settings/models/custom_colors_store.dart';
import 'package:provider/provider.dart';
import 'package:nexus/features/settings/controllers/settings_controller.dart';
import 'package:nexus/features/theme_customization/views/widgets/preview/theme_preview_card.dart';
import 'package:nexus/features/theme_customization/views/widgets/colors/color_option_grid.dart';
import 'package:nexus/features/theme_customization/views/widgets/presets/preset_list_section.dart';
import 'package:nexus/features/theme_customization/views/widgets/presets/save_preset_dialog.dart';
import 'package:nexus/features/theme_customization/views/widgets/nav_bar_styles/nav_bar_style_section.dart';

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
  bool _initialTabSet = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging == false) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set initial tab based on current theme mode (only once)
    if (!_initialTabSet) {
      _initialTabSet = true;
      final settings = context.read<SettingsController>();
      final isDark = settings.themeMode == ThemeMode.dark;
      _currentTabIndex = isDark ? 1 : 0;
      if (isDark && _tabController.index != 1) {
        // Use addPostFrameCallback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _tabController.animateTo(1);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
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
              _buildColorSection(
                brightness: Brightness.light,
                currentPrimary: settings.lightColors.primary,
                currentSecondary: settings.lightColors.secondary,
                defaultPrimary: const Color(0xFF3F51B5),
                defaultSecondary: const Color(0xFF009688),
              ),
              _buildColorSection(
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

  Widget _buildColorSection({
    required Brightness brightness,
    required Color? currentPrimary,
    required Color? currentSecondary,
    required Color defaultPrimary,
    required Color defaultSecondary,
  }) {
    final isLight = brightness == Brightness.light;
    final textColor = isLight ? Colors.black87 : Colors.white;
    final bgColor = isLight ? const Color(0xFFF8FAFC) : const Color(0xFF000000);

    return Container(
      color: bgColor,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Preview Card
          ThemePreviewCard(
            primary: currentPrimary ?? defaultPrimary,
            secondary: currentSecondary ?? defaultSecondary,
            isLight: isLight,
          ),
          const SizedBox(height: 24),

          // Saved Presets
          PresetListSection(isLight: isLight),

          // Primary Color Section
          Text(
            'Primary Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used for buttons, highlights, and key elements',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ColorOptionGrid(
            options: CustomColorsStore.primaryOptions,
            selectedColor: currentPrimary ?? defaultPrimary,
            defaultColor: defaultPrimary,
            onColorSelected: (color) {
              context.read<SettingsController>().updatePrimaryColor(
                brightness,
                color,
              );
            },
          ),
          const SizedBox(height: 24),

          // Secondary Color Section
          Text(
            'Secondary Color',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Used for accents and secondary actions',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ColorOptionGrid(
            options: CustomColorsStore.secondaryOptions,
            selectedColor: currentSecondary ?? defaultSecondary,
            defaultColor: defaultSecondary,
            onColorSelected: (color) {
              context.read<SettingsController>().updateSecondaryColor(
                brightness,
                color,
              );
            },
          ),
          const SizedBox(height: 32),
          NavBarStyleSection(isLight: isLight),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
