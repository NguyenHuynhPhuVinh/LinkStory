import 'package:get/get.dart';

import '../controllers/ai_settings_controller.dart';
import '../../../data/services/ai_settings_service.dart';

class AiSettingsBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize AI Settings Service
    Get.putAsync<AiSettingsService>(() async {
      final service = AiSettingsService();
      await service.init();
      return service;
    }, permanent: true);

    Get.lazyPut<AiSettingsController>(
      () => AiSettingsController(),
    );
  }
}
