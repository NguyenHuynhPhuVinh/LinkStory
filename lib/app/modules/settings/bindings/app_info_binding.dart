import 'package:get/get.dart';
import '../controllers/app_info_controller.dart';

class AppInfoBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppInfoController>(
      () => AppInfoController(),
    );
  }
}
