import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ThemeService extends GetxService {
  static const String _boxName = 'theme_settings';
  static const String _themeKey = 'theme_mode';
  
  Box? _themeBox;
  final Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  static ThemeService get to => Get.find();

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeTheme();
  }

  Future<void> _initializeTheme() async {
    try {
      _themeBox = await Hive.openBox(_boxName);
      
      // Load saved theme
      final savedTheme = _themeBox?.get(_themeKey, defaultValue: 'system');
      switch (savedTheme) {
        case 'light':
          themeMode.value = ThemeMode.light;
          break;
        case 'dark':
          themeMode.value = ThemeMode.dark;
          break;
        default:
          themeMode.value = ThemeMode.system;
      }
      
      print('✅ Theme Service initialized: ${themeMode.value}');
    } catch (e) {
      print('❌ Error initializing theme service: $e');
      themeMode.value = ThemeMode.system;
    }
  }

  Future<void> changeTheme(ThemeMode mode) async {
    try {
      themeMode.value = mode;
      
      // Save to storage
      String themeString;
      switch (mode) {
        case ThemeMode.light:
          themeString = 'light';
          break;
        case ThemeMode.dark:
          themeString = 'dark';
          break;
        case ThemeMode.system:
          themeString = 'system';
          break;
      }
      
      await _themeBox?.put(_themeKey, themeString);
      
      // Apply theme
      Get.changeThemeMode(mode);
      
      print('✅ Theme changed to: $mode');
    } catch (e) {
      print('❌ Error changing theme: $e');
    }
  }

  // Get theme data
  static ThemeData get lightTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),
  );
}
