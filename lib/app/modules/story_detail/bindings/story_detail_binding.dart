import 'package:get/get.dart';
import '../controllers/story_detail_controller.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../../data/services/translation_service.dart';
import '../../../data/services/chapter_translation_service.dart';

class StoryDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký services như singleton
    Get.put<LibraryService>(LibraryService(), permanent: true);
    Get.put<ChapterService>(ChapterService(), permanent: true);

    // Đăng ký translation services
    Get.put<TranslationService>(TranslationService(), permanent: true);
    Get.put<ChapterTranslationService>(ChapterTranslationService(), permanent: true);

    // Đăng ký StoryDetailController
    Get.lazyPut<StoryDetailController>(
      () => StoryDetailController(),
    );
  }
}
