import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/services/firebase_config_service.dart';

class FirebaseSettingsController extends GetxController {
  final FirebaseConfigService _firebaseConfigService = FirebaseConfigService();

  // Observable states
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _firebaseConfigService.init();
      print('✅ Firebase Config Service initialized');
    } catch (e) {
      print('❌ Error initializing Firebase Config Service: $e');
    }
  }

  // Get Firebase config service for UI binding
  FirebaseConfigService get firebaseConfig => _firebaseConfigService;

  // Pick and upload google-services.json file
  Future<void> uploadGoogleServicesFile() async {
    try {
      isLoading.value = true;

      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);

        // Validate file name
        if (!result.files.single.name.contains('google-services')) {
          Get.snackbar(
            'Lỗi',
            'Vui lòng chọn file google-services.json',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange.withOpacity(0.8),
            colorText: Colors.white,
          );
          return;
        }

        // Read file content
        final content = await file.readAsString();

        // Update Firebase configuration
        final success = await _firebaseConfigService.updateFirebaseConfig(content);

        if (success) {
          // Show restart dialog
          _showRestartDialog();
        }
      } else {
        Get.snackbar(
          'Đã hủy',
          'Không có file nào được chọn',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra khi tải file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showRestartDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cập nhật thành công'),
        content: const Text(
          'Cấu hình Firebase đã được cập nhật.\n'
          'Vui lòng khởi động lại ứng dụng để áp dụng thay đổi.'
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Get.back();
              // Optionally exit the app
              // SystemNavigator.pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Show detailed Firebase configuration
  void showConfigDetails() {
    final projectId = _firebaseConfigService.projectId;
    final apiKey = _firebaseConfigService.apiKey;
    final isConfigured = _firebaseConfigService.isConfigured.value;
    final exportedConfig = _firebaseConfigService.exportConfig();

    Get.dialog(
      AlertDialog(
        title: const Text('Chi tiết cấu hình Firebase'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Project ID', projectId),
              _buildDetailRow('API Key', apiKey.isNotEmpty ? '${apiKey.substring(0, 10)}...' : 'Không có'),
              _buildDetailRow('Trạng thái', isConfigured ? 'Đã cấu hình' : 'Chưa cấu hình'),
              if (isConfigured) ...[
                const SizedBox(height: 16),
                const Text(
                  'Thông tin cấu hình:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Project ID: ${exportedConfig['project_id']}\n'
                    'API Key: ${exportedConfig['api_key']?.substring(0, 10)}...\n'
                    'Cấu hình lúc: ${exportedConfig['configured_at']}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value.isEmpty ? 'Không có' : value),
          ),
        ],
      ),
    );
  }

  // Reset Firebase configuration to default
  Future<void> resetFirebaseConfig() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận reset'),
        content: const Text(
          'Bạn có chắc chắn muốn khôi phục cấu hình Firebase mặc định?\n'
          'Thao tác này sẽ xóa cấu hình hiện tại.'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _firebaseConfigService.resetToDefault();
              _showRestartDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
