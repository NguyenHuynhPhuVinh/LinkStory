import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/ai_controller.dart';

class AiView extends GetView<AiController> {
  const AiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Trợ lý'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: () {
              // TODO: Navigate to AI settings screen
              Get.snackbar('Thông báo', 'Cài đặt AI sẽ được phát triển');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.cpu,
              size: 64.sp,
              color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'AI Trợ lý',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Đang phát triển...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
