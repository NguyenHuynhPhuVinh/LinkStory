import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getwidget/getwidget.dart';

import '../controllers/settings_controller.dart';

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
            // Firebase Configuration Section
            _buildSectionHeader('Cấu hình Firebase', Iconsax.cloud),
            _buildFirebaseConfigSection(),

            SizedBox(height: 24.h),

            // App Information Section
            _buildSectionHeader('Thông tin ứng dụng', Iconsax.info_circle),
            _buildAppInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20.sp,
            color: Theme.of(Get.context!).colorScheme.primary,
          ),
          SizedBox(width: 8.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(Get.context!).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirebaseConfigSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Configuration Status
            Obx(() => _buildConfigStatusCard()),

            SizedBox(height: 16.h),

            // Upload Button
            Obx(() => GFButton(
              onPressed: controller.isLoading.value
                  ? null
                  : controller.uploadGoogleServicesFile,
              text: controller.isLoading.value
                  ? 'Đang xử lý...'
                  : 'Tải lên google-services.json',
              icon: controller.isLoading.value
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Iconsax.document_upload, size: 18.sp),
              type: GFButtonType.solid,
              shape: GFButtonShape.pills,
              size: GFSize.LARGE,
              fullWidthButton: true,
            )),

            SizedBox(height: 12.h),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: GFButton(
                    onPressed: controller.showConfigDetails,
                    text: 'Xem chi tiết',
                    icon: Icon(Iconsax.eye, size: 16.sp),
                    type: GFButtonType.outline,
                    shape: GFButtonShape.pills,
                    size: GFSize.MEDIUM,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GFButton(
                    onPressed: controller.resetFirebaseConfig,
                    text: 'Reset',
                    icon: Icon(Iconsax.refresh, size: 16.sp),
                    type: GFButtonType.outline,
                    color: Colors.red,
                    shape: GFButtonShape.pills,
                    size: GFSize.MEDIUM,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Instructions
            _buildInstructionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigStatusCard() {
    final isConfigured = controller.firebaseConfig.isConfigured.value;
    final projectId = controller.firebaseConfig.currentProjectId.value;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isConfigured
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isConfigured ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConfigured ? Iconsax.tick_circle : Iconsax.warning_2,
            color: isConfigured ? Colors.green : Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConfigured ? 'Đã cấu hình' : 'Chưa cấu hình',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isConfigured ? Colors.green : Colors.orange,
                  ),
                ),
                if (projectId.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Project: $projectId',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                color: Colors.blue,
                size: 16.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Hướng dẫn',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '1. Tải file google-services.json từ Firebase Console\n'
            '2. Nhấn "Tải lên google-services.json"\n'
            '3. Chọn file và đợi xử lý\n'
            '4. Khởi động lại ứng dụng để áp dụng',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            _buildInfoRow('Phiên bản', '1.0.0', Iconsax.code),
            _buildInfoRow('Nhà phát triển', 'TomiSakae', Iconsax.user),
            _buildInfoRow('Ngôn ngữ', 'Tiếng Việt', Iconsax.global),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18.sp,
            color: Colors.grey[600],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
