import 'package:get/get.dart';
import '../controllers/reading_controller.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../../data/services/translation_service.dart';
import '../../../data/services/chapter_translation_service.dart';
import '../../../data/services/history_service.dart';

class ReadingBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký services như singleton với fenix để tự động tái tạo khi cần
    Get.lazyPut<LibraryService>(() => LibraryService(), fenix: true);
    Get.lazyPut<ChapterService>(() => ChapterService(), fenix: true);
    Get.lazyPut<HistoryService>(() => HistoryService(), fenix: true);

    // Đăng ký translation services
    Get.lazyPut<TranslationService>(() => TranslationService(), fenix: true);
    Get.lazyPut<ChapterTranslationService>(() => ChapterTranslationService(), fenix: true);

    // Đăng ký ReadingController
    Get.lazyPut<ReadingController>(
      () => ReadingController(),
    );
  }
}
