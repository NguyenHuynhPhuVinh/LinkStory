import 'package:hive/hive.dart';
import '../models/ai_settings_model.dart';

class AiSettingsService {
  static const String _boxName = 'ai_settings';
  static const String _settingsKey = 'current_settings';
  
  Box<AiSettings>? _settingsBox;
  AiSettings? _currentSettings;

  // Initialize service
  Future<void> init() async {
    try {
      // Register adapters if not already registered
      if (!Hive.isAdapterRegistered(15)) {
        Hive.registerAdapter(AiSettingsAdapter());
      }

      // Open box
      _settingsBox = await Hive.openBox<AiSettings>(_boxName);
      
      // Load current settings or create default
      await _loadOrCreateDefaultSettings();
      
      print('✅ AI Settings Service initialized');
    } catch (e) {
      print('❌ Error initializing AI Settings Service: $e');
      rethrow;
    }
  }

  // Load existing settings or create default
  Future<void> _loadOrCreateDefaultSettings() async {
    try {
      _currentSettings = _settingsBox?.get(_settingsKey);
      
      if (_currentSettings == null) {
        // Create default settings
        _currentSettings = AiSettings.defaultSettings();
        await saveSettings(_currentSettings!);
        print('✅ Created default AI settings');
      } else {
        print('✅ Loaded existing AI settings');
      }
    } catch (e) {
      print('❌ Error loading AI settings: $e');
      // Fallback to default settings
      _currentSettings = AiSettings.defaultSettings();
    }
  }

  // Get current settings
  AiSettings getCurrentSettings() {
    return _currentSettings ?? AiSettings.defaultSettings();
  }

  // Save settings
  Future<void> saveSettings(AiSettings settings) async {
    try {
      await _settingsBox?.put(_settingsKey, settings);
      _currentSettings = settings;
      print('✅ AI settings saved successfully');
    } catch (e) {
      print('❌ Error saving AI settings: $e');
      throw Exception('Không thể lưu cài đặt AI: $e');
    }
  }

  // Update specific setting
  Future<void> updateModelName(String modelName) async {
    final updatedSettings = getCurrentSettings().copyWith(
      modelName: modelName,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateSystemPrompt(String systemPrompt) async {
    final updatedSettings = getCurrentSettings().copyWith(
      systemPrompt: systemPrompt,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateTemperature(double temperature) async {
    final updatedSettings = getCurrentSettings().copyWith(
      temperature: temperature,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateTopP(double topP) async {
    final updatedSettings = getCurrentSettings().copyWith(
      topP: topP,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateTopK(int topK) async {
    final updatedSettings = getCurrentSettings().copyWith(
      topK: topK,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateMaxOutputTokens(int maxOutputTokens) async {
    final updatedSettings = getCurrentSettings().copyWith(
      maxOutputTokens: maxOutputTokens,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateSafetySettings(List<String> safetySettings) async {
    final updatedSettings = getCurrentSettings().copyWith(
      safetySettings: safetySettings,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateStreaming(bool enableStreaming) async {
    final updatedSettings = getCurrentSettings().copyWith(
      enableStreaming: enableStreaming,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateMarkdown(bool enableMarkdown) async {
    final updatedSettings = getCurrentSettings().copyWith(
      enableMarkdown: enableMarkdown,
    );
    await saveSettings(updatedSettings);
  }

  Future<void> updateLanguage(String language) async {
    final updatedSettings = getCurrentSettings().copyWith(
      language: language,
    );
    await saveSettings(updatedSettings);
  }

  // Reset to default settings
  Future<void> resetToDefault() async {
    final defaultSettings = AiSettings.defaultSettings();
    await saveSettings(defaultSettings);
  }

  // Export settings to JSON
  Map<String, dynamic> exportSettings() {
    return getCurrentSettings().toJson();
  }

  // Import settings from JSON
  Future<void> importSettings(Map<String, dynamic> json) async {
    try {
      final settings = AiSettings.fromJson(json);
      await saveSettings(settings);
    } catch (e) {
      print('❌ Error importing AI settings: $e');
      throw Exception('Không thể nhập cài đặt AI: $e');
    }
  }

  // Validate settings
  bool validateSettings(AiSettings settings) {
    // Validate temperature (0.0 - 2.0)
    if (settings.temperature < 0.0 || settings.temperature > 2.0) {
      return false;
    }

    // Validate topP (0.0 - 1.0)
    if (settings.topP < 0.0 || settings.topP > 1.0) {
      return false;
    }

    // Validate topK (1 - 100)
    if (settings.topK < 1 || settings.topK > 100) {
      return false;
    }

    // Validate maxOutputTokens (1 - 32768)
    if (settings.maxOutputTokens < 1 || settings.maxOutputTokens > 32768) {
      return false;
    }

    // Validate model name
    final validModels = AiModels.availableModels.map((m) => m['id']).toList();
    if (!validModels.contains(settings.modelName)) {
      return false;
    }

    // Validate safety settings
    final validSafetyOptions = SafetySettings.options.map((o) => o['id']).toList();
    for (final setting in settings.safetySettings) {
      if (!validSafetyOptions.contains(setting)) {
        return false;
      }
    }

    return true;
  }

  // Get settings summary for display
  Map<String, String> getSettingsSummary() {
    final settings = getCurrentSettings();
    return {
      'Mô hình AI': AiModels.getModelName(settings.modelName),
      'Temperature': settings.temperature.toStringAsFixed(1),
      'Top P': settings.topP.toStringAsFixed(1),
      'Top K': settings.topK.toString(),
      'Max Tokens': settings.maxOutputTokens.toString(),
      'Streaming': settings.enableStreaming ? 'Bật' : 'Tắt',
      'Markdown': settings.enableMarkdown ? 'Bật' : 'Tắt',
      'Ngôn ngữ': settings.language == 'vi' ? 'Tiếng Việt' : 'English',
    };
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      await _settingsBox?.clear();
      _currentSettings = null;
      await _loadOrCreateDefaultSettings();
      print('✅ Cleared all AI settings data');
    } catch (e) {
      print('❌ Error clearing AI settings data: $e');
      throw Exception('Không thể xóa dữ liệu cài đặt AI: $e');
    }
  }

  // Close service
  Future<void> close() async {
    await _settingsBox?.close();
  }
}
