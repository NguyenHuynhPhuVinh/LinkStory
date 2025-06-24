import 'package:get/get.dart';
import '../controllers/ai_controller.dart';
import '../../../data/services/ai_chat_service.dart';

class AiBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize AI Chat Service
    Get.putAsync<AiChatService>(() async {
      final service = AiChatService();
      await service.init();
      return service;
    });

    Get.lazyPut<AiController>(
      () => AiController(),
    );
  }
}
