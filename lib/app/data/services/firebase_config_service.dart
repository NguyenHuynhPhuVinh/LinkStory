import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseConfigService {
  // Singleton pattern
  static final FirebaseConfigService _instance = FirebaseConfigService._internal();
  factory FirebaseConfigService() => _instance;
  FirebaseConfigService._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const String _configKey = 'firebase_config';
  static const String _apiKeyKey = 'firebase_api_key';

  // Observable states
  final RxBool isConfigured = false.obs;
  final RxString currentApiKey = ''.obs;
  final RxString currentProjectId = ''.obs;

  // Initialize service
  Future<void> init() async {
    await _loadCurrentConfig();
  }

  // Load current Firebase configuration
  Future<void> _loadCurrentConfig() async {
    try {
      final configJson = await _secureStorage.read(key: _configKey);
      final apiKey = await _secureStorage.read(key: _apiKeyKey);

      if (configJson != null && apiKey != null) {
        final config = jsonDecode(configJson);
        currentApiKey.value = apiKey;
        currentProjectId.value = config['project_id'] ?? '';
        isConfigured.value = true;
        print('✅ Loaded existing Firebase config: ${currentProjectId.value}');
      } else {
        // Load default config
        currentApiKey.value = 'AIzaSyAdI1gJYSBM2BM7xy9TubFo5unyCmjFGD8';
        currentProjectId.value = 'linkstory-43c2e';
        isConfigured.value = true;
        print('📱 Using default Firebase config');
      }
    } catch (e) {
      print('❌ Error loading Firebase config: $e');
      isConfigured.value = false;
    }
  }

  // Parse and validate google-services.json content
  Map<String, dynamic>? parseGoogleServicesJson(String jsonContent) {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);
      
      // Validate required fields
      if (!data.containsKey('project_info') || !data.containsKey('client')) {
        throw Exception('Invalid google-services.json format');
      }

      final projectInfo = data['project_info'] as Map<String, dynamic>;
      final clients = data['client'] as List<dynamic>;
      
      if (clients.isEmpty) {
        throw Exception('No client configuration found');
      }

      final client = clients.first as Map<String, dynamic>;
      final apiKeys = client['api_key'] as List<dynamic>;
      
      if (apiKeys.isEmpty) {
        throw Exception('No API key found');
      }

      final apiKey = apiKeys.first['current_key'] as String;
      final projectId = projectInfo['project_id'] as String;
      final appId = client['client_info']['mobilesdk_app_id'] as String;

      return {
        'project_id': projectId,
        'api_key': apiKey,
        'app_id': appId,
        'project_number': projectInfo['project_number'],
        'storage_bucket': projectInfo['storage_bucket'],
      };
    } catch (e) {
      print('❌ Error parsing google-services.json: $e');
      return null;
    }
  }

  // Update Firebase configuration
  Future<bool> updateFirebaseConfig(String googleServicesJsonContent) async {
    try {
      // Parse the JSON content
      final config = parseGoogleServicesJson(googleServicesJsonContent);
      if (config == null) {
        Get.snackbar(
          'Lỗi',
          'File google-services.json không hợp lệ',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }

      // Save configuration to secure storage
      await _secureStorage.write(key: _configKey, value: jsonEncode(config));
      await _secureStorage.write(key: _apiKeyKey, value: config['api_key']);

      // Update observable values
      currentApiKey.value = config['api_key'];
      currentProjectId.value = config['project_id'];
      isConfigured.value = true;

      // Save to app directory for runtime use
      await _saveConfigToAppDirectory(config);

      Get.snackbar(
        'Thành công',
        'Đã cập nhật cấu hình Firebase\nProject: ${config['project_id']}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      return true;
    } catch (e) {
      print('❌ Error updating Firebase config: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật cấu hình Firebase: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Save config to app directory for runtime use
  Future<void> _saveConfigToAppDirectory(Map<String, dynamic> config) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final configFile = File('${appDir.path}/firebase_config.json');
      await configFile.writeAsString(jsonEncode(config));
      print('✅ Saved Firebase config to app directory');
    } catch (e) {
      print('❌ Error saving config to app directory: $e');
    }
  }

  // Get current API key for translation service
  String get apiKey => currentApiKey.value;

  // Get current project ID
  String get projectId => currentProjectId.value;

  // Reset to default configuration
  Future<void> resetToDefault() async {
    try {
      await _secureStorage.delete(key: _configKey);
      await _secureStorage.delete(key: _apiKeyKey);
      
      // Load default config
      await _loadCurrentConfig();
      
      Get.snackbar(
        'Đã reset',
        'Đã khôi phục cấu hình Firebase mặc định',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error resetting Firebase config: $e');
    }
  }

  // Export current configuration
  Map<String, dynamic> exportConfig() {
    return {
      'project_id': currentProjectId.value,
      'api_key': currentApiKey.value,
      'configured_at': DateTime.now().toIso8601String(),
    };
  }
}
