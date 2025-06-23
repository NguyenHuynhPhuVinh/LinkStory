import 'package:get/get.dart';
import '../controllers/reading_controller.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';

class ReadingBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký services như singleton
    Get.put<LibraryService>(LibraryService(), permanent: true);
    Get.put<ChapterService>(ChapterService(), permanent: true);
    
    // Đăng ký ReadingController
    Get.lazyPut<ReadingController>(
      () => ReadingController(),
    );
  }
}
