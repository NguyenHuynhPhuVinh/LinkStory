import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/chapter_model.dart';
import '../models/story_model.dart';
import 'translation_service.dart';
import 'chapter_service.dart';

class ChapterTranslationService extends GetxService {
  late final TranslationService _translationService;
  late final ChapterService _chapterService;

  // Observable states
  final RxBool isTranslating = false.obs;
  final RxString translatingChapterId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _translationService = Get.find<TranslationService>();
    _chapterService = Get.find<ChapterService>();

    // Initialize translation service
    _initializeTranslationService();
  }

  // Initialize translation service
  Future<void> _initializeTranslationService() async {
    try {
      await _translationService.init();
      print('✅ ChapterTranslationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing ChapterTranslationService: $e');
    }
  }

  // Kiểm tra xem có phải truyện Syosetu không
  bool isSyosetuStory(Story? story) {
    return story?.sourceWebsite.toLowerCase().contains('syosetu') ?? false;
  }

  // Dịch một chương cụ thể
  Future<bool> translateChapter(Chapter chapter, Story? story) async {
    if (!isSyosetuStory(story)) {
      Get.snackbar(
        'Thông báo',
        'Tính năng dịch chỉ hỗ trợ truyện từ Syosetu',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    // Kiểm tra xem chương đã có nội dung chưa
    if (!chapter.hasContent) {
      Get.snackbar(
        'Lỗi',
        'Chương chưa có nội dung để dịch. Vui lòng tải nội dung trước.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    // Kiểm tra xem đã dịch chưa
    if (chapter.isTranslated) {
      Get.snackbar(
        'Thông báo',
        'Chương này đã được dịch rồi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }

    try {
      isTranslating.value = true;
      translatingChapterId.value = chapter.id;

      Get.snackbar(
        'Đang dịch...',
        'Đang dịch chương "${chapter.title}"',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Gọi service dịch
      final translationResult = await _translationService.translateChapter(
        title: chapter.title,
        content: chapter.content,
      );

      if (translationResult != null) {
        // Cập nhật chapter với bản dịch
        await _chapterService.updateChapterTranslation(
          chapter.id,
          translationResult['title'] ?? chapter.title,
          translationResult['content'] ?? chapter.content,
        );

        Get.snackbar(
          'Dịch thành công',
          'Chương "${chapter.title}" đã được dịch sang tiếng Việt',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );

        return true;
      } else {
        Get.snackbar(
          'Lỗi dịch',
          'Không thể dịch chương. Vui lòng thử lại sau.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      print('Error translating chapter: $e');
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra khi dịch chương: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    } finally {
      isTranslating.value = false;
      translatingChapterId.value = '';
    }
  }

  // Kiểm tra xem chương có đang được dịch không
  bool isChapterTranslating(String chapterId) {
    return isTranslating.value && translatingChapterId.value == chapterId;
  }

  // Lấy chapter đã cập nhật từ database
  Chapter? getUpdatedChapter(String chapterId) {
    return _chapterService.getChapterById(chapterId);
  }
}
