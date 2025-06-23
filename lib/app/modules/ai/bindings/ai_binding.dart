import 'package:get/get.dart';
import '../controllers/ai_controller.dart';

class AiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiController>(
      () => AiController(),
    );
  }
}
