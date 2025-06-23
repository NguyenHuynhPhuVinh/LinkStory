import 'package:get/get.dart';
import '../../library/controllers/library_controller.dart';

class HomeController extends GetxController {
  // Observable cho current tab index
  final currentIndex = 0.obs;

  // Danh sách các tab
  final List<String> tabTitles = [
    'Thư viện',
    'Đọc truyện',
    'AI',
    'Lịch sử',
    'Cài đặt',
  ];

  // Thay đổi tab
  void changeTabIndex(int index) {
    final previousIndex = currentIndex.value;
    currentIndex.value = index;

    // Notify library controller when switching to library tab
    if (index == 0 && previousIndex != 0) {
      try {
        final libraryController = Get.find<LibraryController>();
        libraryController.onTabVisible();
      } catch (e) {
        // LibraryController might not be initialized yet
        print('LibraryController not found: $e');
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
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
