import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/ai_settings_controller.dart';
import '../../../data/models/ai_settings_model.dart';

class AiSettingsView extends GetView<AiSettingsController> {
  const AiSettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt AI Trợ lý'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Iconsax.refresh),
                    SizedBox(width: 8),
                    Text('Khôi phục mặc định'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Iconsax.export),
                    SizedBox(width: 8),
                    Text('Xuất cài đặt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Iconsax.import),
                    SizedBox(width: 8),
                    Text('Nhập cài đặt'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (controller.errorMessage.value.isNotEmpty)
                Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Iconsax.warning_2, color: Colors.red, size: 20.sp),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            controller.errorMessage.value,
                            style: TextStyle(color: Colors.red, fontSize: 14.sp),
                          ),
                        ),
                        IconButton(
                          onPressed: controller.clearError,
                          icon: Icon(Iconsax.close_circle, color: Colors.red, size: 20.sp),
                        ),
                      ],
                    ),
                  ),
                ),

              // Model Selection
              _buildModelSection(),
              SizedBox(height: 12.h),

              // System Prompt
              _buildSystemPromptSection(),
              SizedBox(height: 12.h),

              // Generation Parameters
              _buildGenerationParametersSection(),
              SizedBox(height: 12.h),

              // Safety Settings
              _buildSafetySettingsSection(),
              SizedBox(height: 12.h),

              // Features
              _buildFeaturesSection(),
              SizedBox(height: 12.h),

              // Language
              _buildLanguageSection(),
              SizedBox(height: 16.h),

              // Save Button
              SizedBox(height: 8.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.saveSettings,
                  icon: Icon(Iconsax.save_2, size: 16.sp),
                  label: const Text('Lưu cài đặt'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildModelSection() {
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
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.cpu,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Mô hình AI',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Obx(() => Column(
              children: AiModels.availableModels.map((model) {
                final isSelected = controller.selectedModel.value == model['id'];
                return Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    leading: Radio<String>(
                      value: model['id']!,
                      groupValue: controller.selectedModel.value,
                      onChanged: (value) => controller.updateModel(value!),
                    ),
                    title: Text(
                      model['name']!,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Theme.of(Get.context!).colorScheme.primary : null,
                      ),
                    ),
                    subtitle: Text(
                      model['description']!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    onTap: () => controller.updateModel(model['id']!),
                  ),
                );
              }).toList(),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemPromptSection() {
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
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.message_programming,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Prompt',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Hướng dẫn cho AI về cách trả lời và hành xử',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: controller.systemPromptController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Nhập system prompt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                filled: true,
                fillColor: Theme.of(Get.context!).colorScheme.surface,
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _resetSystemPrompt,
                  icon: Icon(Iconsax.refresh, size: 16.sp),
                  label: const Text('Khôi phục mặc định'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  ),
                ),
                const Spacer(),
                Obx(() => Text(
                  '${controller.systemPromptLength.value} ký tự',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerationParametersSection() {
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
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.setting_2,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tham số sinh văn bản',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Điều chỉnh cách AI tạo ra phản hồi',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Temperature
            _buildSliderParameter(
              'Temperature',
              'Độ sáng tạo (0.0 = chính xác, 2.0 = sáng tạo)',
              controller.temperature,
              0.0,
              2.0,
              controller.updateTemperature,
            ),
            SizedBox(height: 16.h),

            // Top P
            _buildSliderParameter(
              'Top P',
              'Ngưỡng xác suất tích lũy (0.0 - 1.0)',
              controller.topP,
              0.0,
              1.0,
              controller.updateTopP,
            ),
            SizedBox(height: 16.h),

            // Top K
            _buildIntSliderParameter(
              'Top K',
              'Số lượng token được xem xét (1 - 100)',
              controller.topK,
              1,
              100,
              controller.updateTopK,
            ),
            SizedBox(height: 16.h),

            // Max Output Tokens
            _buildIntSliderParameter(
              'Max Output Tokens',
              'Số token tối đa trong phản hồi (1 - 32768)',
              controller.maxOutputTokens,
              1,
              32768,
              controller.updateMaxTokens,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderParameter(
    String title,
    String description,
    RxDouble value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            Obx(() => Text(
              value.value.toStringAsFixed(1),
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            )),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        SizedBox(height: 8.h),
        Obx(() => Slider(
          value: value.value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          onChanged: onChanged,
        )),
      ],
    );
  }

  Widget _buildIntSliderParameter(
    String title,
    String description,
    RxInt value,
    int min,
    int max,
    Function(int) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            Obx(() => Text(
              value.value.toString(),
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            )),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          description,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        SizedBox(height: 8.h),
        Obx(() => Slider(
          value: value.value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          onChanged: (val) => onChanged(val.round()),
        )),
      ],
    );
  }

  Widget _buildSafetySettingsSection() {
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
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.shield_security,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài đặt an toàn',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Kiểm soát nội dung có thể gây hại',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...SafetyCategories.categories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category['name']!,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      category['description']!,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 8.h),
                    Obx(() => DropdownButtonFormField<String>(
                      value: index < controller.safetySettings.length
                          ? controller.safetySettings[index]
                          : 'BLOCK_MEDIUM_AND_ABOVE',
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        filled: true,
                        fillColor: Theme.of(Get.context!).colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      ),
                      isExpanded: true,
                      items: SafetySettings.options.map((option) {
                        return DropdownMenuItem<String>(
                          value: option['id'],
                          child: Text(
                            option['name']!,
                            style: TextStyle(fontSize: 14.sp),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          controller.updateSafetySetting(index, value);
                        }
                      },
                    )),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
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
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.flash,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tính năng',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Bật/tắt các tính năng nâng cao',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Streaming
            Obx(() => Row(
              children: [
                Icon(
                  Iconsax.flash_1,
                  size: 16.sp,
                  color: controller.enableStreaming.value
                      ? Theme.of(Get.context!).colorScheme.primary
                      : Colors.grey,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streaming',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Hiển thị phản hồi theo thời gian thực',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.enableStreaming.value,
                  onChanged: (_) => controller.toggleStreaming(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            )),

            SizedBox(height: 8.h),

            // Markdown
            Obx(() => Row(
              children: [
                Icon(
                  Iconsax.code,
                  size: 16.sp,
                  color: controller.enableMarkdown.value
                      ? Theme.of(Get.context!).colorScheme.primary
                      : Colors.grey,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Markdown',
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'Hỗ trợ định dạng văn bản nâng cao',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: controller.enableMarkdown.value,
                  onChanged: (_) => controller.toggleMarkdown(),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
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
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Iconsax.language_square,
                    color: Theme.of(Get.context!).colorScheme.primary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ngôn ngữ',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Chọn ngôn ngữ ưu tiên cho AI',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Obx(() => Column(
              children: [
                // Vietnamese
                InkWell(
                  onTap: () => controller.updateLanguage('vi'),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'vi',
                          groupValue: controller.selectedLanguage.value,
                          onChanged: (value) => controller.updateLanguage(value!),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tiếng Việt',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: controller.selectedLanguage.value == 'vi'
                                      ? Theme.of(Get.context!).colorScheme.primary
                                      : null,
                                ),
                              ),
                              Text(
                                'AI sẽ ưu tiên trả lời bằng tiếng Việt',
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // English
                InkWell(
                  onTap: () => controller.updateLanguage('en'),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'en',
                          groupValue: controller.selectedLanguage.value,
                          onChanged: (value) => controller.updateLanguage(value!),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'English',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: controller.selectedLanguage.value == 'en'
                                      ? Theme.of(Get.context!).colorScheme.primary
                                      : null,
                                ),
                              ),
                              Text(
                                'AI will prioritize English responses',
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
          ],
        ),
      ),
    );
  }

  // Helper methods
  void _resetSystemPrompt() {
    controller.systemPromptController.text = AiSettings.defaultSettings().systemPrompt;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset':
        _confirmReset();
        break;
      case 'export':
        _exportSettings();
        break;
      case 'import':
        _importSettings();
        break;
    }
  }

  void _confirmReset() {
    Get.dialog(
      AlertDialog(
        title: const Text('Khôi phục cài đặt mặc định'),
        content: const Text('Bạn có chắc chắn muốn khôi phục tất cả cài đặt về mặc định?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.resetToDefault();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Khôi phục'),
          ),
        ],
      ),
    );
  }

  void _exportSettings() {
    try {
      final settings = controller.exportSettings();
      // TODO: Implement export functionality (save to file, share, etc.)
      Get.snackbar(
        'Xuất cài đặt',
        'Tính năng xuất cài đặt sẽ được cập nhật trong phiên bản tiếp theo',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể xuất cài đặt: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _importSettings() {
    // TODO: Implement import functionality (file picker, etc.)
    Get.snackbar(
      'Nhập cài đặt',
      'Tính năng nhập cài đặt sẽ được cập nhật trong phiên bản tiếp theo',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
