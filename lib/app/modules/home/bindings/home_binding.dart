import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../library/controllers/library_controller.dart';
import '../../reader/controllers/reader_controller.dart';
import '../../ai/controllers/ai_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../settings/controllers/settings_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(),
    );

    // Đăng ký tất cả controller cho các tab trong HomeView
    Get.lazyPut<LibraryController>(
      () => LibraryController(),
    );

    Get.lazyPut<ReaderController>(
      () => ReaderController(),
    );

    Get.lazyPut<AiController>(
      () => AiController(),
    );

    Get.lazyPut<HistoryController>(
      () => HistoryController(),
    );

    Get.lazyPut<SettingsController>(
      () => SettingsController(),
    );
  }
}
