import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/theme_service.dart';

enum AppThemeMode {
  light('Sáng', Icons.light_mode),
  dark('Tối', Icons.dark_mode),
  system('Hệ thống', Icons.brightness_auto);

  const AppThemeMode(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

class ThemeSettingsController extends GetxController {
  final ThemeService _themeService = Get.find<ThemeService>();
  final Rx<AppThemeMode> currentTheme = AppThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeTheme();
  }

  void _initializeTheme() {
    // Convert ThemeMode to AppThemeMode
    switch (_themeService.themeMode.value) {
      case ThemeMode.light:
        currentTheme.value = AppThemeMode.light;
        break;
      case ThemeMode.dark:
        currentTheme.value = AppThemeMode.dark;
        break;
      case ThemeMode.system:
        currentTheme.value = AppThemeMode.system;
        break;
    }

    print('✅ Theme Settings initialized: ${currentTheme.value.displayName}');
  }

  Future<void> changeTheme(AppThemeMode appThemeMode) async {
    try {
      currentTheme.value = appThemeMode;

      // Convert AppThemeMode to ThemeMode
      ThemeMode themeMode;
      switch (appThemeMode) {
        case AppThemeMode.light:
          themeMode = ThemeMode.light;
          break;
        case AppThemeMode.dark:
          themeMode = ThemeMode.dark;
          break;
        case AppThemeMode.system:
          themeMode = ThemeMode.system;
          break;
      }

      // Apply theme through ThemeService
      await _themeService.changeTheme(themeMode);

      // Force rebuild all widgets by updating the app
      await Future.delayed(const Duration(milliseconds: 100));

      Get.snackbar(
        'Đã thay đổi giao diện',
        'Giao diện ${appThemeMode.displayName} đã được áp dụng',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      print('✅ Theme changed to: ${appThemeMode.displayName}');
    } catch (e) {
      print('❌ Error changing theme: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể thay đổi giao diện: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Get current theme display info
  String get currentThemeDisplayName => currentTheme.value.displayName;
  IconData get currentThemeIcon => currentTheme.value.icon;
  
  // Get all available themes
  List<AppThemeMode> get availableThemes => AppThemeMode.values;
  
  // Check if theme is selected
  bool isThemeSelected(AppThemeMode theme) => currentTheme.value == theme;
}
