import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../controllers/app_info_controller.dart';

class AppInfoView extends GetView<AppInfoController> {
  const AppInfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin ứng dụng'),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            children: [
              // App Logo/Icon Section
              _buildAppLogoSection(),
              
              SizedBox(height: 24.h),
              
              // App Info Card
              _buildAppInfoCard(),
              
              SizedBox(height: 24.h),
              
              // Additional Info Card
              _buildAdditionalInfoCard(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAppLogoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // App Icon
            Container(
              width: 80.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Iconsax.book,
                size: 40.sp,
                color: Colors.blue,
              ),
            ),
            
            SizedBox(height: 16.h),
            
            // App Name
            Text(
              controller.appName.value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 4.h),
            
            // Version
            Text(
              'Phiên bản ${controller.formattedVersion}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
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
            Text(
              'Thông tin chi tiết',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16.h),
            
            ...controller.appInfoItems.take(4).map((item) => 
              _buildInfoRow(item.label, item.value, _getIconForType(item.icon))
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
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
            Text(
              'Thông tin bổ sung',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16.h),
            
            ...controller.appInfoItems.skip(4).map((item) => 
              _buildInfoRow(item.label, item.value, _getIconForType(item.icon))
            ).toList(),
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
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'app':
        return Iconsax.mobile;
      case 'version':
        return Iconsax.code;
      case 'package':
        return Iconsax.box;
      case 'developer':
        return Iconsax.user;
      case 'language':
        return Iconsax.global;
      case 'framework':
        return Iconsax.code_circle;
      default:
        return Iconsax.info_circle;
    }
  }
}
