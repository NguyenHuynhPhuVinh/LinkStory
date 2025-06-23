import 'package:get/get.dart';
import '../controllers/library_controller.dart';
import '../../../data/services/library_service.dart';

class LibraryBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký LibraryService như singleton
    Get.put<LibraryService>(LibraryService(), permanent: true);

    // Đăng ký LibraryController
    Get.lazyPut<LibraryController>(
      () => LibraryController(),
    );
  }
}
