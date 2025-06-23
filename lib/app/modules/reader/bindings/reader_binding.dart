import 'package:get/get.dart';
import '../controllers/reader_controller.dart';
import '../../../data/services/website_service.dart';

class ReaderBinding extends Bindings {
  @override
  void dependencies() {
    // Đăng ký WebsiteService như singleton
    Get.put<WebsiteService>(WebsiteService(), permanent: true);

    // Đăng ký ReaderController
    Get.lazyPut<ReaderController>(() => ReaderController());
  }
}
