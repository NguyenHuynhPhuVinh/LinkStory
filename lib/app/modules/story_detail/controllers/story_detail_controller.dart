import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../../data/services/story_translation_service.dart';
import '../../../data/services/chapter_translation_service.dart';
import '../../library/controllers/library_controller.dart';

class StoryDetailController extends GetxController {
  late final LibraryService _libraryService;
  late final ChapterService _chapterService;
  late final StoryTranslationService _storyTranslationService;
  late final ChapterTranslationService _chapterTranslationService;
  
  // Observable states
  final Rx<Story?> story = Rx<Story?>(null);
  final RxList<Chapter> chapters = <Chapter>[].obs;
  final RxList<Chapter> filteredChapters = <Chapter>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, read, unread
  final RxBool showSearch = false.obs;


  // Flag to prevent auto-refresh during translation
  bool _isTranslating = false;
  
  // Search controller
  final TextEditingController searchController = TextEditingController();
  
  @override
  void onInit() {
    super.onInit();

    // Get services from GetX
    _libraryService = Get.find<LibraryService>();
    _chapterService = Get.find<ChapterService>();
    _storyTranslationService = StoryTranslationService();
    _chapterTranslationService = Get.find<ChapterTranslationService>();

    // Initialize translation service
    _storyTranslationService.init();

    // Get story from arguments
    final storyArg = Get.arguments;
    if (storyArg is Story) {
      story.value = storyArg;
      print('📖 Story loaded from arguments: ${storyArg.title}, isTranslated: ${storyArg.isTranslated}');
    }

    // Listen to search changes
    searchQuery.listen((_) => _filterChapters());
    selectedFilter.listen((_) => _filterChapters());

    // Listen to translation state changes to reload story
    ever(_storyTranslationService.isTranslating, (isTranslating) {
      if (!isTranslating && story.value != null) {
        // Translation finished, reload story after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          print('🔄 Auto-reloading story after translation...');
          _reloadStoryFromDatabase();
        });
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    _initializeAndLoadChapters();
  }

  // Public method to reload story (can be called from UI)
  Future<void> reloadStory() async {
    await _reloadStoryFromDatabase();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
  
  // Initialize services and load chapters
  Future<void> _initializeAndLoadChapters() async {
    try {
      isLoading.value = true;
      await _chapterService.init();

      // Reload story from database to get latest data
      await _reloadStoryFromDatabase();

      await loadChapters();
    } catch (e) {
      print('Error initializing services: $e');
      isLoading.value = false;
    }
  }

  // Reload story from database
  Future<void> _reloadStoryFromDatabase() async {
    if (story.value == null) return;

    try {
      final freshStory = _libraryService.getStoryById(story.value!.id);
      if (freshStory != null) {
        print('🔄 Reloaded story from database: isTranslated=${freshStory.isTranslated}, title=${freshStory.displayTitle}');

        // Force reactive update by setting to null first, then to new value
        story.value = null;
        await Future.delayed(const Duration(milliseconds: 50));
        story.value = freshStory;

        // Force refresh
        story.refresh();
        update();

        print('✅ Story updated - current title: ${story.value?.displayTitle}, isTranslated: ${story.value?.isTranslated}');

        // Notify library controller to reload
        _notifyLibraryReload();
      }
    } catch (e) {
      print('❌ Error reloading story from database: $e');
    }
  }
  
  // Load chapters for this story
  Future<void> loadChapters() async {
    if (story.value == null) return;

    try {
      // Only set loading if not already loading
      if (!isLoading.value) {
        isLoading.value = true;
      }

      final allChapters = _chapterService.getChaptersByStoryId(story.value!.id);
      chapters.value = allChapters;
      _filterChapters();

      print('Loaded ${allChapters.length} chapters for story: ${story.value!.title}');
      print('📊 Story in loadChapters - isTranslated: ${story.value!.isTranslated}, displayTitle: ${story.value!.displayTitle}');

      // Debug: Check how many chapters have content
      final chaptersWithContent = allChapters.where((c) => c.hasContent).length;
      print('Chapters with content: $chaptersWithContent/${allChapters.length}');
    } catch (e) {
      print('Error loading chapters: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách chương',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Filter chapters
  void _filterChapters() {
    List<Chapter> filtered = List.from(chapters);
    
    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((chapter) {
        return chapter.title.toLowerCase().contains(query) ||
               chapter.volumeTitle.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply read status filter
    switch (selectedFilter.value) {
      case 'read':
        filtered = filtered.where((chapter) => chapter.isRead).toList();
        break;
      case 'unread':
        filtered = filtered.where((chapter) => !chapter.isRead).toList();
        break;
      case 'all':
      default:
        // No additional filtering
        break;
    }
    
    filteredChapters.value = filtered;
  }
  
  // Search chapters
  void searchChapters(String query) {
    searchQuery.value = query;
  }
  
  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }
  
  // Toggle search visibility
  void toggleSearch() {
    showSearch.value = !showSearch.value;
    if (!showSearch.value) {
      clearSearch();
    }
  }
  
  // Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }
  
  // Toggle favorite
  Future<void> toggleFavorite() async {
    if (story.value == null) return;
    
    try {
      await _libraryService.toggleFavorite(story.value!.id);
      
      // Update local story object
      story.value = story.value!.copyWith(
        isFavorite: !story.value!.isFavorite,
        updatedAt: DateTime.now(),
      );
      
      Get.snackbar(
        story.value!.isFavorite ? 'Đã thêm vào yêu thích' : 'Đã bỏ yêu thích',
        story.value!.title,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Error toggling favorite: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể cập nhật trạng thái yêu thích',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
  
  // Mark chapter as read
  Future<void> markChapterAsRead(Chapter chapter) async {
    try {
      await _chapterService.markChapterAsRead(chapter.id);
      
      // Update local chapter list
      final index = chapters.indexWhere((c) => c.id == chapter.id);
      if (index != -1) {
        chapters[index] = chapter.copyWith(isRead: true);
        _filterChapters();
      }
      
      // Update story read progress
      await _updateStoryProgress();
    } catch (e) {
      print('Error marking chapter as read: $e');
    }
  }
  
  // Mark chapter as unread
  Future<void> markChapterAsUnread(Chapter chapter) async {
    try {
      await _chapterService.markChapterAsUnread(chapter.id);
      
      // Update local chapter list
      final index = chapters.indexWhere((c) => c.id == chapter.id);
      if (index != -1) {
        chapters[index] = chapter.copyWith(isRead: false);
        _filterChapters();
      }
      
      // Update story read progress
      await _updateStoryProgress();
    } catch (e) {
      print('Error marking chapter as unread: $e');
    }
  }
  
  // Update story reading progress
  Future<void> _updateStoryProgress() async {
    if (story.value == null) return;
    
    final readChapters = chapters.where((c) => c.isRead).length;
    final updatedStory = story.value!.copyWith(
      readChapters: readChapters,
      lastReadAt: DateTime.now(),
    );
    
    await _libraryService.updateStory(updatedStory);
    story.value = updatedStory;
  }
  
  // Open chapter for reading
  Future<void> openChapter(Chapter chapter) async {
    // Get fresh chapter data from database to ensure we have latest content
    final freshChapter = _chapterService.getChapterById(chapter.id);
    final chapterToPass = freshChapter ?? chapter;

    print('Opening chapter: ${chapterToPass.title}');
    print('Chapter has content: ${chapterToPass.hasContent}');
    print('Content length: ${chapterToPass.content.length}');

    // Navigate to reading screen and wait for return
    await Get.toNamed('/reading', arguments: {
      'chapter': chapterToPass,
      'story': story.value,
    });

    // Refresh chapters when returning from reading screen
    print('Returned from reading screen - refreshing chapters');
    await loadChapters();
  }
  
  // Get chapter statistics
  Map<String, dynamic> getChapterStats() {
    return _chapterService.getChapterStats(story.value?.id ?? '');
  }

  // Kiểm tra xem có phải truyện Syosetu không
  bool get isSyosetuStory {
    return _chapterTranslationService.isSyosetuStory(story.value);
  }

  // Kiểm tra xem chương có đang được dịch không
  bool isChapterTranslating(String chapterId) {
    return _chapterTranslationService.isChapterTranslating(chapterId);
  }

  // Dịch một chương cụ thể
  Future<void> translateChapter(Chapter chapter) async {
    final success = await _chapterTranslationService.translateChapter(
      chapter,
      story.value,
    );

    if (success) {
      // Reload chapters để cập nhật UI
      await loadChapters();
    }
  }
  
  // Continue reading (next unread chapter)
  Future<void> continueReading() async {
    final nextChapter = _chapterService.getNextUnreadChapter(story.value?.id ?? '');
    if (nextChapter != null) {
      await openChapter(nextChapter);
    } else {
      // If no unread chapters, open the first chapter
      if (chapters.isNotEmpty) {
        await openChapter(chapters.first);
      } else {
        Get.snackbar(
          'Thông báo',
          'Chưa có chương nào để đọc',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
  
  // Refresh data
  Future<void> refresh() async {
    if (_isTranslating) {
      print('⏸️ Skipping refresh during translation');
      return;
    }
    print('Manual refresh triggered');
    await loadChapters();
  }

  // Translate story to Vietnamese
  Future<void> translateStory() async {
    final currentStory = story.value;
    if (currentStory == null) return;

    try {
      _isTranslating = true;

      final updatedStory = await _storyTranslationService.translateStory(currentStory);
      if (updatedStory != null) {
        print('✅ Translation completed, reloading story...');

        // Wait a bit to ensure database write is completed
        await Future.delayed(const Duration(milliseconds: 300));

        // Reload story from database
        await _reloadStoryFromDatabase();

        print('✅ Story reloaded - final title: ${story.value?.displayTitle}');
        print('🔍 Final check - isTranslated: ${story.value?.isTranslated}');
      }
    } finally {
      _isTranslating = false;
    }
  }

  // Get translation states
  RxBool get isTranslating => _storyTranslationService.isTranslating;

  // Notify library controller to reload after translation
  void _notifyLibraryReload() {
    try {
      final libraryController = Get.find<LibraryController>();
      print('📢 Notifying library controller to reload...');
      Future.delayed(const Duration(milliseconds: 300), () {
        libraryController.loadStories();
      });
    } catch (e) {
      print('❌ Library controller not found: $e');
    }
  }
}
