import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/services/firebase_config_service.dart';

class SettingsController extends GetxController {
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
      print('❌ Error uploading google-services file: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể đọc file: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Show restart dialog
  void _showRestartDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Cần khởi động lại'),
        content: const Text(
          'Cấu hình Firebase đã được cập nhật.\n'
          'Ứng dụng cần được khởi động lại để áp dụng thay đổi.\n\n'
          'Bạn có muốn khởi động lại ngay bây giờ không?'
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Để sau'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _restartApp();
            },
            child: const Text('Khởi động lại'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Restart app (close and let user reopen)
  void _restartApp() {
    Get.snackbar(
      'Đang khởi động lại...',
      'Vui lòng mở lại ứng dụng',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // Close app after a short delay
    Future.delayed(const Duration(seconds: 2), () {
      exit(0);
    });
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

  // Show current configuration details
  void showConfigDetails() {
    final config = _firebaseConfigService.exportConfig();

    Get.dialog(
      AlertDialog(
        title: const Text('Cấu hình Firebase hiện tại'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigRow('Project ID', config['project_id']),
            _buildConfigRow('API Key', '${config['api_key'].substring(0, 20)}...'),
            _buildConfigRow('Cấu hình lúc', config['configured_at'] ?? 'Mặc định'),
          ],
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

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
