import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/history_controller.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.trash),
            onPressed: () {
              Get.snackbar('Thông báo', 'Chức năng xóa lịch sử sẽ được phát triển');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.clock,
              size: 64.sp,
              color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'Lịch sử đọc',
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
