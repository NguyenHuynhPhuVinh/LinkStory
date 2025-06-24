import 'package:get/get.dart';
import '../controllers/history_controller.dart';
import '../../../data/services/history_service.dart';
import '../../../data/services/library_service.dart';

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure services are available
    Get.lazyPut<HistoryService>(() => HistoryService(), fenix: true);
    Get.lazyPut<LibraryService>(() => LibraryService(), fenix: true);

    Get.lazyPut<HistoryController>(
      () => HistoryController(),
    );
  }
}
