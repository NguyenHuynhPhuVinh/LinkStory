import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getwidget/getwidget.dart';

import '../controllers/settings_controller.dart';
import '../../../routes/app_pages.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings List
            _buildSettingsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    final settingsItems = [
      SettingsItem(
        title: 'Giao diện',
        subtitle: 'Tùy chỉnh giao diện sáng, tối hoặc theo hệ thống',
        icon: Iconsax.brush_2,
        onTap: () => Get.toNamed(Routes.THEME_SETTINGS),
      ),
      SettingsItem(
        title: 'Cấu hình Firebase',
        subtitle: 'Quản lý cấu hình Firebase và API keys',
        icon: Iconsax.cloud,
        onTap: () => Get.toNamed(Routes.FIREBASE_SETTINGS),
      ),
      SettingsItem(
        title: 'Thông tin ứng dụng',
        subtitle: 'Xem thông tin chi tiết về ứng dụng',
        icon: Iconsax.info_circle,
        onTap: () => Get.toNamed(Routes.APP_INFO),
      ),
    ];

    return Column(
      children: settingsItems.map((item) => _buildSettingsCard(item)).toList(),
    );
  }

  Widget _buildSettingsCard(SettingsItem item) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        leading: Container(
          width: 48.w,
          height: 48.h,
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            item.icon,
            color: Theme.of(Get.context!).colorScheme.primary,
            size: 24.sp,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          item.subtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          size: 20.sp,
          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.4),
        ),
        onTap: item.onTap,
      ),
    );
  }
}

class SettingsItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  SettingsItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
}
