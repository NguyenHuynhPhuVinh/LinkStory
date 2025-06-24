import 'package:get/get.dart';
import '../data/services/library_service.dart';
import '../data/services/history_service.dart';
import '../data/services/theme_service.dart';
import '../data/services/chapter_service.dart';
import '../data/services/translation_service.dart';
import '../data/services/chapter_translation_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services - khởi tạo ngay từ đầu
    Get.put<ThemeService>(ThemeService(), permanent: true);
    Get.put<LibraryService>(LibraryService(), permanent: true);
    Get.put<HistoryService>(HistoryService(), permanent: true);
    
    // Other services - lazy load
    Get.lazyPut<ChapterService>(() => ChapterService(), fenix: true);
    Get.lazyPut<TranslationService>(() => TranslationService(), fenix: true);
    Get.lazyPut<ChapterTranslationService>(() => ChapterTranslationService(), fenix: true);
  }
}
