import 'package:get/get.dart';
import '../../../data/models/website_model.dart';
import '../../../data/services/website_service.dart';
import '../../../routes/app_pages.dart';

class ReaderController extends GetxController {
  final WebsiteService _websiteService = WebsiteService();

  // Observable cho danh sách websites
  final websites = <Website>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeWebsites();
  }

  // Khởi tạo danh sách websites
  Future<void> _initializeWebsites() async {
    try {
      isLoading.value = true;
      await _websiteService.init();
      await loadWebsites();
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách websites: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Tải danh sách websites
  Future<void> loadWebsites() async {
    final websiteList = _websiteService.getAllWebsites();
    websites.assignAll(websiteList);
  }

  // Mở website
  void openWebsite(Website website) {
    Get.toNamed(Routes.WEBVIEW, arguments: website);
  }

  // Refresh danh sách
  Future<void> refreshWebsites() async {
    await loadWebsites();
  }

  @override
  void onReady() {
    super.onReady();
  }

  @override
  void onClose() {
    super.onClose();
  }
}
