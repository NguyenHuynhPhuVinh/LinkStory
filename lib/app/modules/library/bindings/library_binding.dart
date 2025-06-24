import 'package:get/get.dart';
import '../controllers/library_controller.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/history_service.dart';

class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký services với fenix để tự động tái tạo khi cần
    Get.lazyPut<LibraryService>(() => LibraryService(), fenix: true);
    Get.lazyPut<HistoryService>(() => HistoryService(), fenix: true);

    // Đăng ký LibraryController
    Get.lazyPut<LibraryController>(
      () => LibraryController(),
    );
  }
}
