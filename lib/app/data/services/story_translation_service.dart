import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/story_model.dart';
import 'translation_service.dart';
import 'library_service.dart';

class StoryTranslationService {
  // Singleton pattern
  static final StoryTranslationService _instance = StoryTranslationService._internal();
  factory StoryTranslationService() => _instance;
  StoryTranslationService._internal();

  final TranslationService _translationService = TranslationService();
  final LibraryService _libraryService = LibraryService();

  // Observable states
  final RxBool isTranslating = false.obs;
  final RxString translatingStoryId = ''.obs;

  // Initialize service
  Future<void> init() async {
    try {
      await _translationService.init();
      print('✅ StoryTranslationService initialized successfully');
    } catch (e) {
      print('❌ Error initializing StoryTranslationService: $e');
    }
  }

  // Check if service is ready
  bool get isReady => _translationService.isReady;

  // Check if currently translating a specific story
  bool isTranslatingStory(String storyId) {
    return isTranslating.value && translatingStoryId.value == storyId;
  }

  // Translate story to Vietnamese
  Future<Story?> translateStory(Story story) async {
    if (!story.canBeTranslated) {
      Get.snackbar(
        'Không thể dịch',
        'Truyện này không thể dịch hoặc đã được dịch',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.withOpacity(0.8),
        colorText: Colors.white,
      );
      return null;
    }

    if (!_translationService.isReady) {
      Get.snackbar(
        'Lỗi',
        'Dịch vụ dịch thuật chưa sẵn sàng',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return null;
    }

    try {
      isTranslating.value = true;
      translatingStoryId.value = story.id;

      // Show loading snackbar
      Get.snackbar(
        'Đang dịch...',
        'Đang dịch thông tin truyện "${story.title}"',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.withOpacity(0.8),
        colorText: Colors.white,
      );

      // Call translation service
      final translatedInfo = await _translationService.translateStoryInfo(
        title: story.title,
        author: story.author,
        description: story.description,
        genres: story.genres,
      );

      if (translatedInfo != null) {
        // Update story with translated information
        final updatedStory = story.copyWith(
          translatedTitle: translatedInfo['title'],
          translatedAuthor: translatedInfo['author'],
          translatedDescription: translatedInfo['description'],
          translatedGenres: translatedInfo['genres']?.split(','),
          isTranslated: true,
          translatedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Save to library
        await _libraryService.updateStory(updatedStory);

        Get.snackbar(
          'Dịch thành công',
          'Truyện "${story.title}" đã được dịch sang tiếng Việt',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );

        return updatedStory;
      } else {
        Get.snackbar(
          'Lỗi dịch',
          'Không thể dịch thông tin truyện. Vui lòng thử lại sau.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      print('Error translating story: $e');
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra khi dịch truyện: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return null;
    } finally {
      isTranslating.value = false;
      translatingStoryId.value = '';
    }
  }

  // Quick translate method for single text
  Future<String?> translateText(String text) async {
    return await _translationService.translateText(text);
  }
}
