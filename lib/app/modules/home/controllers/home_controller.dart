import 'package:get/get.dart';

class HomeController extends GetxController {
  // Observable cho current tab index
  final currentIndex = 0.obs;
  
  // Danh sách các tab
  final List<String> tabTitles = [
    'Thư viện',
    'Đọc truyện',
    'AI',
    'Lịch sử',
    'Cài đặt'
  ];

  // Thay đổi tab
  void changeTabIndex(int index) {
    currentIndex.value = index;
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
