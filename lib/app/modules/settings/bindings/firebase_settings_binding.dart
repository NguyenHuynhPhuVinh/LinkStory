import 'package:get/get.dart';
import '../controllers/firebase_settings_controller.dart';

class FirebaseSettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseSettingsController>(
      () => FirebaseSettingsController(),
    );
  }
}
