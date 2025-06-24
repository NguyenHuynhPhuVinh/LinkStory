import 'package:get/get.dart';
import '../controllers/theme_settings_controller.dart';

class ThemeSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ThemeSettingsController>(
      () => ThemeSettingsController(),
    );
  }
}
