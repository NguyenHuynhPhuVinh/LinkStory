import 'package:get/get.dart';
import '../controllers/story_detail_controller.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';

class StoryDetailBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký services như singleton
    Get.put<LibraryService>(LibraryService(), permanent: true);
    Get.put<ChapterService>(ChapterService(), permanent: true);
    
    // Đăng ký StoryDetailController
    Get.lazyPut<StoryDetailController>(
      () => StoryDetailController(),
    );
  }
}
