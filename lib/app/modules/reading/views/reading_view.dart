import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/reading_controller.dart';

class ReadingView extends GetView<ReadingController> {
  const ReadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      appBar: controller.showAppBar.value ? _buildAppBar() : null,
      body: _buildBody(),
      bottomNavigationBar: controller.showAppBar.value ? _buildBottomBar() : null,
    ));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: controller.isDarkMode.value ? Colors.grey[900] : Colors.white,
      foregroundColor: controller.isDarkMode.value ? Colors.white : Colors.black,
      elevation: 1,
      title: Obx(() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            controller.currentChapter.value?.title ?? 'Đang tải...',
            style: TextStyle(fontSize: 16.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (controller.story.value != null)
            Text(
              controller.story.value!.title,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      )),
      actions: [
        // Nút dịch chỉ hiển thị cho truyện Syosetu
        Obx(() {
          if (controller.isSyosetuStory && controller.currentChapter.value != null) {
            return IconButton(
              icon: controller.isTranslating
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          controller.isDarkMode.value ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : Icon(
                      controller.currentChapter.value!.isTranslated
                          ? Iconsax.translate5
                          : Iconsax.translate,
                      size: 20.sp,
                      color: controller.currentChapter.value!.isTranslated
                          ? Colors.green
                          : null,
                    ),
              onPressed: controller.isTranslating
                  ? null
                  : controller.translateCurrentChapter,
              tooltip: controller.currentChapter.value!.isTranslated
                  ? 'Đã dịch'
                  : 'Dịch chương',
            );
          }
          return const SizedBox.shrink();
        }),
        IconButton(
          icon: Icon(
            Theme.of(Get.context!).brightness == Brightness.dark
                ? Iconsax.sun_1
                : Iconsax.moon,
            size: 20.sp,
          ),
          onPressed: () {
            // Navigate to theme settings instead of local toggle
            Get.toNamed('/settings/theme');
          },
        ),
        IconButton(
          icon: Icon(Iconsax.setting_2, size: 20.sp),
          onPressed: _showReadingSettings,
        ),
      ],
    );
  }

  Widget _buildBody() {
    return GestureDetector(
      onTap: () {
        // Toggle app bar visibility
        controller.showAppBar.value = !controller.showAppBar.value;
      },
      child: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingView();
        }

        if (controller.chapterContent.value.isEmpty) {
          return _buildEmptyView();
        }

        return _buildContentView();
      }),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: controller.isDarkMode.value ? Colors.white : Colors.blue,
          ),
          SizedBox(height: 16.h),
          Obx(() => Text(
            controller.isScrapingContent.value 
                ? 'Đang scrape nội dung chương...'
                : 'Đang tải nội dung...',
            style: TextStyle(
              fontSize: 16.sp,
              color: controller.isDarkMode.value ? Colors.white : Colors.black,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_text,
            size: 64.sp,
            color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            'Không có nội dung',
            style: TextStyle(
              fontSize: 18.sp,
              color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Chương này có thể bị khóa hoặc cần đăng nhập',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: controller.scrapeChapterContent,
            icon: Icon(Iconsax.refresh, size: 18.sp),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    return Column(
      children: [
        // Progress indicator
        Obx(() => LinearProgressIndicator(
          value: controller.scrollProgress.value,
          backgroundColor: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(Get.context!).colorScheme.primary,
          ),
        )),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            controller: controller.scrollController,
            padding: EdgeInsets.all(20.w),
            child: Obx(() => SelectableText(
              controller.chapterContent.value,
              style: TextStyle(
                fontSize: controller.fontSize.value.sp,
                height: controller.lineHeight.value,
                color: Theme.of(Get.context!).colorScheme.onSurface,
                fontFamily: controller.fontFamily.value == 'Default'
                    ? null
                    : controller.fontFamily.value,
              ),
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: controller.isDarkMode.value ? Colors.grey[900] : Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous chapter
          IconButton(
            onPressed: controller.goToPreviousChapter,
            icon: Icon(
              Iconsax.arrow_left_2,
              color: Theme.of(Get.context!).colorScheme.onSurface,
            ),
            tooltip: 'Chương trước',
          ),
          
          // Chapter info
          Expanded(
            child: Obx(() => Text(
              controller.chapterNavigation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(Get.context!).colorScheme.onSurface,
              ),
            )),
          ),
          
          // Next chapter
          IconButton(
            onPressed: controller.goToNextChapter,
            icon: Icon(
              Iconsax.arrow_right_3,
              color: Theme.of(Get.context!).colorScheme.onSurface,
            ),
            tooltip: 'Chương tiếp',
          ),
        ],
      ),
    );
  }

  void _showReadingSettings() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: controller.isDarkMode.value ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cài đặt đọc truyện',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: controller.isDarkMode.value ? Colors.white : Colors.black,
              ),
            ),
            
            SizedBox(height: 20.h),
            
            // Font size
            Text(
              'Cỡ chữ',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: controller.isDarkMode.value ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                IconButton(
                  onPressed: controller.decreaseFontSize,
                  icon: Icon(
                    Iconsax.minus,
                    color: controller.isDarkMode.value ? Colors.white : Colors.black,
                  ),
                ),
                Expanded(
                  child: Obx(() => Slider(
                    value: controller.fontSize.value,
                    min: 12,
                    max: 24,
                    divisions: 12,
                    onChanged: (value) => controller.fontSize.value = value,
                  )),
                ),
                IconButton(
                  onPressed: controller.increaseFontSize,
                  icon: Icon(
                    Iconsax.add,
                    color: controller.isDarkMode.value ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16.h),
            
            // Line height
            Text(
              'Khoảng cách dòng',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: controller.isDarkMode.value ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Obx(() => Slider(
              value: controller.lineHeight.value,
              min: 1.0,
              max: 2.5,
              divisions: 15,
              onChanged: controller.setLineHeight,
            )),
            
            SizedBox(height: 16.h),
            
            // Theme settings
            ListTile(
              title: Text(
                'Cài đặt giao diện',
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                Iconsax.arrow_right_3,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
              ),
              onTap: () => Get.toNamed('/settings/theme'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
