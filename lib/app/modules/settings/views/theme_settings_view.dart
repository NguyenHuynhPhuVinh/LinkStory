import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/theme_settings_controller.dart';

class ThemeSettingsView extends GetView<ThemeSettingsController> {
  const ThemeSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao diện'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Theme Info
            _buildCurrentThemeCard(),
            
            SizedBox(height: 24.h),
            
            // Theme Options
            _buildThemeOptionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentThemeCard() {
    return Obx(() => Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                controller.currentThemeIcon,
                color: Theme.of(Get.context!).colorScheme.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao diện hiện tại',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    controller.currentThemeDisplayName,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildThemeOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn giao diện',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // Theme Options List
        Obx(() => Column(
          children: controller.availableThemes
              .map((theme) => _buildThemeOption(theme))
              .toList(),
        )),
      ],
    );
  }

  Widget _buildThemeOption(AppThemeMode theme) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: controller.isThemeSelected(theme)
            ? BorderSide(
                color: Theme.of(Get.context!).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 8.h,
        ),
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: controller.isThemeSelected(theme)
                ? Theme.of(Get.context!).colorScheme.primary.withOpacity(0.2)
                : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            theme.icon,
            color: controller.isThemeSelected(theme)
                ? Theme.of(Get.context!).colorScheme.primary
                : Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
            size: 20.sp,
          ),
        ),
        title: Text(
          theme.displayName,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: controller.isThemeSelected(theme)
                ? FontWeight.w600
                : FontWeight.normal,
            color: controller.isThemeSelected(theme)
                ? Theme.of(Get.context!).colorScheme.primary
                : null,
          ),
        ),
        subtitle: Text(
          _getThemeDescription(theme),
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: controller.isThemeSelected(theme)
            ? Icon(
                Iconsax.tick_circle,
                color: Theme.of(Get.context!).colorScheme.primary,
                size: 20.sp,
              )
            : null,
        onTap: () => controller.changeTheme(theme),
      ),
    );
  }

  String _getThemeDescription(AppThemeMode theme) {
    switch (theme) {
      case AppThemeMode.light:
        return 'Giao diện sáng, dễ nhìn ban ngày';
      case AppThemeMode.dark:
        return 'Giao diện tối, bảo vệ mắt ban đêm';
      case AppThemeMode.system:
        return 'Tự động theo cài đặt hệ thống';
    }
  }
}
