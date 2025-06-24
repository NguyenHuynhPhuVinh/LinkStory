import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/ai_settings_model.dart';
import '../../../data/services/ai_settings_service.dart';
import '../../ai/controllers/ai_controller.dart';

class AiSettingsController extends GetxController {
  // Services
  late final AiSettingsService _aiSettingsService;

  // Observable variables
  final currentSettings = Rxn<AiSettings>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Form controllers
  final systemPromptController = TextEditingController();
  final temperatureController = TextEditingController();
  final topPController = TextEditingController();
  final topKController = TextEditingController();
  final maxTokensController = TextEditingController();

  // Observable for character count
  final systemPromptLength = 0.obs;

  // Form values
  final selectedModel = ''.obs;
  final temperature = 0.7.obs;
  final topP = 0.9.obs;
  final topK = 40.obs;
  final maxOutputTokens = 8192.obs;
  final safetySettings = <String>[].obs;
  final enableStreaming = true.obs;
  final enableMarkdown = true.obs;
  final selectedLanguage = 'vi'.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to system prompt changes
    systemPromptController.addListener(() {
      systemPromptLength.value = systemPromptController.text.length;
    });
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      isLoading.value = true;
      // Wait for service to be ready
      int attempts = 0;
      while (attempts < 10) {
        try {
          _aiSettingsService = Get.find<AiSettingsService>();
          break;
        } catch (e) {
          attempts++;
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      if (_aiSettingsService == null) {
        throw Exception('Không thể tìm thấy AiSettingsService sau 10 lần thử');
      }

      await loadSettings();
    } catch (e) {
      print('❌ Error initializing AI Settings Controller: $e');
      errorMessage.value = 'Không thể khởi tạo cài đặt AI: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Load current settings
  Future<void> loadSettings() async {
    try {
      final settings = _aiSettingsService.getCurrentSettings();
      currentSettings.value = settings;
      _updateFormValues(settings);
      print('✅ Loaded AI settings');
    } catch (e) {
      print('❌ Error loading AI settings: $e');
      errorMessage.value = 'Không thể tải cài đặt AI: $e';
    }
  }

  // Update form values from settings
  void _updateFormValues(AiSettings settings) {
    selectedModel.value = settings.modelName;
    systemPromptController.text = settings.systemPrompt;
    temperature.value = settings.temperature;
    topP.value = settings.topP;
    topK.value = settings.topK;
    maxOutputTokens.value = settings.maxOutputTokens;
    safetySettings.value = List<String>.from(settings.safetySettings);
    enableStreaming.value = settings.enableStreaming;
    enableMarkdown.value = settings.enableMarkdown;
    selectedLanguage.value = settings.language;

    // Update text controllers
    temperatureController.text = settings.temperature.toString();
    topPController.text = settings.topP.toString();
    topKController.text = settings.topK.toString();
    maxTokensController.text = settings.maxOutputTokens.toString();

    // Update character count
    systemPromptLength.value = systemPromptController.text.length;
  }

  // Save settings
  Future<void> saveSettings() async {
    try {
      isLoading.value = true;
      clearError();

      final settings = AiSettings(
        modelName: selectedModel.value,
        systemPrompt: systemPromptController.text.trim(),
        temperature: temperature.value,
        topP: topP.value,
        topK: topK.value,
        maxOutputTokens: maxOutputTokens.value,
        safetySettings: List<String>.from(safetySettings),
        enableStreaming: enableStreaming.value,
        enableMarkdown: enableMarkdown.value,
        language: selectedLanguage.value,
        createdAt: currentSettings.value?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validate settings
      if (!_aiSettingsService.validateSettings(settings)) {
        throw Exception('Cài đặt không hợp lệ. Vui lòng kiểm tra lại các giá trị.');
      }

      await _aiSettingsService.saveSettings(settings);
      currentSettings.value = settings;

      // Update AI model in chat service
      try {
        final aiController = Get.find<AiController>();
        await aiController.updateAiModel();
      } catch (e) {
        print('⚠️ Could not update AI model in chat service: $e');
        // Don't throw error as settings were saved successfully
      }

      Get.snackbar(
        'Thành công',
        'Đã lưu cài đặt AI',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Saved AI settings');
    } catch (e) {
      print('❌ Error saving AI settings: $e');
      errorMessage.value = 'Không thể lưu cài đặt: $e';
      Get.snackbar(
        'Lỗi',
        'Không thể lưu cài đặt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Reset to default settings
  Future<void> resetToDefault() async {
    try {
      isLoading.value = true;
      await _aiSettingsService.resetToDefault();
      await loadSettings();

      // Update AI model in chat service
      try {
        final aiController = Get.find<AiController>();
        await aiController.updateAiModel();
      } catch (e) {
        print('⚠️ Could not update AI model in chat service: $e');
        // Don't throw error as settings were reset successfully
      }

      Get.snackbar(
        'Thành công',
        'Đã khôi phục cài đặt mặc định',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Reset AI settings to default');
    } catch (e) {
      print('❌ Error resetting AI settings: $e');
      errorMessage.value = 'Không thể khôi phục cài đặt mặc định: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Update individual settings
  void updateModel(String modelName) {
    selectedModel.value = modelName;
  }

  void updateTemperature(double value) {
    temperature.value = value;
    temperatureController.text = value.toStringAsFixed(1);
  }

  void updateTopP(double value) {
    topP.value = value;
    topPController.text = value.toStringAsFixed(1);
  }

  void updateTopK(int value) {
    topK.value = value;
    topKController.text = value.toString();
  }

  void updateMaxTokens(int value) {
    maxOutputTokens.value = value;
    maxTokensController.text = value.toString();
  }

  void updateSafetySetting(int index, String value) {
    if (index < safetySettings.length) {
      safetySettings[index] = value;
    }
  }

  void toggleStreaming() {
    enableStreaming.value = !enableStreaming.value;
  }

  void toggleMarkdown() {
    enableMarkdown.value = !enableMarkdown.value;
  }

  void updateLanguage(String language) {
    selectedLanguage.value = language;
  }

  // Validate individual fields
  String? validateTemperature(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
    final temp = double.tryParse(value);
    if (temp == null) return 'Giá trị không hợp lệ';
    if (temp < 0.0 || temp > 2.0) return 'Giá trị phải từ 0.0 đến 2.0';
    return null;
  }

  String? validateTopP(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
    final topPValue = double.tryParse(value);
    if (topPValue == null) return 'Giá trị không hợp lệ';
    if (topPValue < 0.0 || topPValue > 1.0) return 'Giá trị phải từ 0.0 đến 1.0';
    return null;
  }

  String? validateTopK(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
    final topKValue = int.tryParse(value);
    if (topKValue == null) return 'Giá trị không hợp lệ';
    if (topKValue < 1 || topKValue > 100) return 'Giá trị phải từ 1 đến 100';
    return null;
  }

  String? validateMaxTokens(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập giá trị';
    final tokens = int.tryParse(value);
    if (tokens == null) return 'Giá trị không hợp lệ';
    if (tokens < 1 || tokens > 32768) return 'Giá trị phải từ 1 đến 32768';
    return null;
  }

  // Export/Import settings
  Map<String, dynamic> exportSettings() {
    return _aiSettingsService.exportSettings();
  }

  Future<void> importSettings(Map<String, dynamic> json) async {
    try {
      isLoading.value = true;
      await _aiSettingsService.importSettings(json);
      await loadSettings();

      // Update AI model in chat service
      try {
        final aiController = Get.find<AiController>();
        await aiController.updateAiModel();
      } catch (e) {
        print('⚠️ Could not update AI model in chat service: $e');
        // Don't throw error as settings were imported successfully
      }

      Get.snackbar(
        'Thành công',
        'Đã nhập cài đặt AI',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error importing AI settings: $e');
      errorMessage.value = 'Không thể nhập cài đặt: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Get settings summary
  Map<String, String> getSettingsSummary() {
    return _aiSettingsService.getSettingsSummary();
  }

  // Clear error
  void clearError() {
    errorMessage.value = '';
  }

  @override
  void onClose() {
    systemPromptController.dispose();
    temperatureController.dispose();
    topPController.dispose();
    topKController.dispose();
    maxTokensController.dispose();
    super.onClose();
  }
}
