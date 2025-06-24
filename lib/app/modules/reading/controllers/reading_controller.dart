import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../../data/services/webview_scraper_service.dart';
import '../../../data/services/chapter_translation_service.dart';
import '../../../data/services/history_service.dart';
import '../../../data/models/reading_history_model.dart';
import '../../story_detail/controllers/story_detail_controller.dart';

class ReadingController extends GetxController {
  late final LibraryService _libraryService;
  late final ChapterService _chapterService;
  late final WebViewScraperService _scraperService;
  late final ChapterTranslationService _chapterTranslationService;
  late final HistoryService _historyService;
  
  // Observable states
  final Rx<Story?> story = Rx<Story?>(null);
  final Rx<Chapter?> currentChapter = Rx<Chapter?>(null);
  final RxList<Chapter> allChapters = <Chapter>[].obs;
  final RxString chapterContent = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isScrapingContent = false.obs;
  final RxDouble scrollProgress = 0.0.obs;
  final RxBool showAppBar = true.obs;
  final RxDouble fontSize = 16.0.obs;
  final RxDouble lineHeight = 1.5.obs;
  final RxString fontFamily = 'Default'.obs;
  final RxBool isDarkMode = false.obs;

  // Controllers
  final ScrollController scrollController = ScrollController();

  // Reading session tracking
  String? _currentSessionId;
  DateTime? _sessionStartTime;
  int _sessionWordsRead = 0;
  
  @override
  void onInit() {
    super.onInit();
    
    // Get services from GetX
    try {
      _libraryService = Get.find<LibraryService>();
    } catch (e) {
      Get.put(LibraryService());
      _libraryService = Get.find<LibraryService>();
    }

    try {
      _chapterService = Get.find<ChapterService>();
    } catch (e) {
      Get.put(ChapterService());
      _chapterService = Get.find<ChapterService>();
    }

    _scraperService = WebViewScraperService();

    try {
      _chapterTranslationService = Get.find<ChapterTranslationService>();
    } catch (e) {
      Get.put(ChapterTranslationService());
      _chapterTranslationService = Get.find<ChapterTranslationService>();
    }

    try {
      _historyService = Get.find<HistoryService>();
    } catch (e) {
      Get.put(HistoryService());
      _historyService = Get.find<HistoryService>();
    }
    
    // Get chapter from arguments
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      final chapterArg = args['chapter'];
      final storyArg = args['story'];
      
      if (chapterArg is Chapter) {
        currentChapter.value = chapterArg;
      }
      
      if (storyArg is Story) {
        story.value = storyArg;
      }
    }
    
    // Setup scroll listener
    scrollController.addListener(_onScroll);
  }

  @override
  void onReady() {
    super.onReady();
    _initializeReading();
  }

  @override
  void onClose() {
    _endReadingSession();
    scrollController.dispose();
    super.onClose();
  }
  
  // Initialize reading
  Future<void> _initializeReading() async {
    try {
      await _chapterService.init();

      if (story.value != null) {
        // Load all chapters for navigation
        allChapters.value = _chapterService.getChaptersByStoryId(story.value!.id);
      }

      if (currentChapter.value != null) {
        // Get fresh chapter data from database to check if content exists
        final freshChapter = _chapterService.getChapterById(currentChapter.value!.id);
        if (freshChapter != null) {
          currentChapter.value = freshChapter;
        }

        // Start reading session
        _startReadingSession();

        await loadChapterContent();

        // Track reading immediately when chapter is opened (before marking as read)
        await _trackChapterReadNow();

        await markChapterAsRead();
      }
    } catch (e) {
      print('Error initializing reading: $e');
    }
  }
  
  // Load chapter content
  Future<void> loadChapterContent() async {
    if (currentChapter.value == null) return;

    try {
      isLoading.value = true;

      print('Loading content for chapter: ${currentChapter.value!.title}');
      print('Chapter hasContent: ${currentChapter.value!.hasContent}');
      print('Chapter content length: ${currentChapter.value!.content.length}');

      // Check if chapter already has content
      if (currentChapter.value!.hasContent) {
        // Hiển thị nội dung (ưu tiên bản dịch nếu có)
        chapterContent.value = currentChapter.value!.displayContent;
        print('✅ Loaded cached content for: ${currentChapter.value!.title} (${currentChapter.value!.displayContent.length} chars)');
      } else {
        print('❌ No cached content, need to scrape: ${currentChapter.value!.title}');
        // Need to scrape content
        await scrapeChapterContent();
      }
    } catch (e) {
      print('Error loading chapter content: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải nội dung chương',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Scrape chapter content
  Future<void> scrapeChapterContent() async {
    if (currentChapter.value == null) return;
    
    try {
      isScrapingContent.value = true;
      
      Get.snackbar(
        'Đang tải',
        'Đang scrape nội dung chương...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      
      final content = await _scraperService.scrapeChapterContent(currentChapter.value!.url);
      
      if (content.isNotEmpty) {
        // Update chapter with content
        await _chapterService.updateChapterContent(currentChapter.value!.id, content);
        
        // Update local chapter object
        currentChapter.value = currentChapter.value!.copyWith(
          content: content,
          wordCount: _countWords(content),
        );
        
        chapterContent.value = content;

        Get.snackbar(
          'Thành công',
          'Đã tải nội dung chương',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể scrape nội dung chương. Có thể chương bị khóa hoặc cần đăng nhập.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      print('Error scraping chapter content: $e');
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra khi scrape nội dung: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isScrapingContent.value = false;
    }
  }
  
  // Mark chapter as read
  Future<void> markChapterAsRead() async {
    if (currentChapter.value == null) return;

    try {
      await _chapterService.markChapterAsRead(currentChapter.value!.id);

      // Update local chapter object
      currentChapter.value = currentChapter.value!.copyWith(isRead: true);

      // Update story progress
      if (story.value != null) {
        final readChapters = allChapters.where((c) => c.isRead).length + 1;
        final updatedStory = story.value!.copyWith(
          readChapters: readChapters,
          lastReadAt: DateTime.now(),
        );

        await _libraryService.updateStory(updatedStory);
        story.value = updatedStory;
      }

      // Track chapter read completion
      _trackChapterContentLoaded();
    } catch (e) {
      print('Error marking chapter as read: $e');
    }
  }
  
  // Navigate to next chapter
  Future<void> goToNextChapter() async {
    if (currentChapter.value == null || allChapters.isEmpty) return;

    final currentIndex = allChapters.indexWhere((c) => c.id == currentChapter.value!.id);
    if (currentIndex != -1 && currentIndex < allChapters.length - 1) {
      final nextChapter = allChapters[currentIndex + 1];
      print('📚 Navigating to next chapter: ${nextChapter.title}');
      await _navigateToChapter(nextChapter);
    } else {
      Get.snackbar(
        'Thông báo',
        'Đây là chương cuối cùng',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Navigate to previous chapter
  Future<void> goToPreviousChapter() async {
    if (currentChapter.value == null || allChapters.isEmpty) return;

    final currentIndex = allChapters.indexWhere((c) => c.id == currentChapter.value!.id);
    if (currentIndex > 0) {
      final previousChapter = allChapters[currentIndex - 1];
      print('📚 Navigating to previous chapter: ${previousChapter.title}');
      await _navigateToChapter(previousChapter);
    } else {
      Get.snackbar(
        'Thông báo',
        'Đây là chương đầu tiên',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  // Navigate to specific chapter
  Future<void> _navigateToChapter(Chapter chapter) async {
    // Refresh all chapters list to get latest data
    if (story.value != null) {
      allChapters.value = _chapterService.getChaptersByStoryId(story.value!.id);
    }

    // Get fresh chapter data from database to check if content exists
    final freshChapter = _chapterService.getChapterById(chapter.id);
    if (freshChapter != null) {
      currentChapter.value = freshChapter;
      print('Loaded fresh chapter data for: ${freshChapter.title}, hasContent: ${freshChapter.hasContent}');
    } else {
      currentChapter.value = chapter;
      print('Using original chapter data for: ${chapter.title}');
    }

    chapterContent.value = '';
    scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    await loadChapterContent();

    // Track reading when navigating to new chapter
    await _trackChapterReadNow();

    await markChapterAsRead();
  }
  
  // Scroll listener
  void _onScroll() {
    if (scrollController.hasClients) {
      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.position.pixels;
      
      if (maxScroll > 0) {
        scrollProgress.value = currentScroll / maxScroll;
      }
      
      // Auto-hide app bar when scrolling down
      final isScrollingDown = scrollController.position.userScrollDirection == ScrollDirection.reverse;
      if (isScrollingDown && showAppBar.value) {
        showAppBar.value = false;
      } else if (!isScrollingDown && !showAppBar.value) {
        showAppBar.value = true;
      }
    }
  }
  
  // Reading settings
  void increaseFontSize() {
    if (fontSize.value < 24) {
      fontSize.value += 1;
    }
  }
  
  void decreaseFontSize() {
    if (fontSize.value > 12) {
      fontSize.value -= 1;
    }
  }
  
  void toggleDarkMode() {
    isDarkMode.value = !isDarkMode.value;
  }
  
  void setLineHeight(double height) {
    lineHeight.value = height;
  }
  
  void setFontFamily(String family) {
    fontFamily.value = family;
  }
  
  // Helper methods
  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
  
  // Get reading progress percentage
  double get readingProgress {
    if (allChapters.isEmpty || currentChapter.value == null) return 0.0;
    
    final currentIndex = allChapters.indexWhere((c) => c.id == currentChapter.value!.id);
    if (currentIndex == -1) return 0.0;
    
    return (currentIndex + 1) / allChapters.length;
  }
  
  // Get chapter navigation info
  String get chapterNavigation {
    if (allChapters.isEmpty || currentChapter.value == null) return '';

    final currentIndex = allChapters.indexWhere((c) => c.id == currentChapter.value!.id);
    if (currentIndex == -1) return '';

    return '${currentIndex + 1}/${allChapters.length}';
  }

  // Kiểm tra xem có phải truyện Syosetu không
  bool get isSyosetuStory {
    return _chapterTranslationService.isSyosetuStory(story.value);
  }

  // Kiểm tra xem chương có đang được dịch không
  bool get isTranslating {
    return currentChapter.value != null &&
           _chapterTranslationService.isChapterTranslating(currentChapter.value!.id);
  }

  // Dịch chương hiện tại
  Future<void> translateCurrentChapter() async {
    if (currentChapter.value == null) return;

    // Track translation action
    if (story.value != null && _currentSessionId != null) {
      await _historyService.trackTranslation(
        story.value!,
        _currentSessionId!,
        'vi', // Vietnamese
        chapter: currentChapter.value!,
      );
    }

    final success = await _chapterTranslationService.translateChapter(
      currentChapter.value!,
      story.value,
    );

    if (success) {
      // Lấy lại chapter đã cập nhật từ database
      final updatedChapter = _chapterTranslationService.getUpdatedChapter(currentChapter.value!.id);
      if (updatedChapter != null) {
        currentChapter.value = updatedChapter;

        // Reload nội dung hiển thị
        chapterContent.value = updatedChapter.displayContent;
      }
    }
  }

  // ==================== READING SESSION TRACKING ====================

  void _startReadingSession() {
    _currentSessionId = _historyService.generateSessionId();
    _sessionStartTime = DateTime.now();
    _sessionWordsRead = 0;
    print('📚 Started reading session: $_currentSessionId');
  }

  void _endReadingSession() {
    if (_currentSessionId != null && _sessionStartTime != null) {
      // Calculate reading duration
      final duration = DateTime.now().difference(_sessionStartTime!);

      // Calculate reading speed (words per minute)
      double readingSpeed = 0.0;
      if (duration.inMinutes > 0 && _sessionWordsRead > 0) {
        readingSpeed = _sessionWordsRead / duration.inMinutes;
      }

      // Track session end if we have meaningful data
      if (duration.inSeconds > 10) { // Only track sessions longer than 10 seconds
        _trackReadingSession(duration.inSeconds, readingSpeed);
      }
    }
  }

  Future<void> _trackReadingSession(int durationSeconds, double readingSpeed) async {
    if (story.value == null || currentChapter.value == null || _currentSessionId == null) return;

    try {
      print('📚 Tracking reading session: ${story.value!.title} - ${currentChapter.value!.title}');
      await _historyService.trackChapterRead(
        story: story.value!,
        chapter: currentChapter.value!,
        sessionId: _currentSessionId!,
        readingDuration: durationSeconds,
        scrollProgress: scrollProgress.value,
        wordsRead: _sessionWordsRead,
        readingSpeed: readingSpeed,
        isOffline: false, // TODO: Detect offline mode
        translationLanguage: currentChapter.value!.isTranslated ? 'vi' : null,
      );
      print('📚 Successfully tracked reading session');
    } catch (e) {
      print('Error tracking reading session: $e');
    }
  }

  // Track when chapter content is loaded
  void _trackChapterContentLoaded() {
    if (currentChapter.value != null) {
      _sessionWordsRead = currentChapter.value!.wordCount;
    }
  }

  // Track chapter read immediately (when starting to read)
  Future<void> _trackChapterReadNow() async {
    if (story.value == null || currentChapter.value == null || _currentSessionId == null) {
      print('📚 Cannot track - missing data: story=${story.value != null}, chapter=${currentChapter.value != null}, session=${_currentSessionId != null}');
      return;
    }

    try {
      print('📚 Tracking chapter reading start: ${story.value!.title} - ${currentChapter.value!.title}');

      // Always create new entry when switching chapters to track reading progress
        // Create reading history entry for current reading position
        final historyEntry = ReadingHistory(
          id: '${story.value!.id}_${currentChapter.value!.id}_${DateTime.now().millisecondsSinceEpoch}',
          storyId: story.value!.id,
          storyTitle: story.value!.title,
          storyAuthor: story.value!.author,
          storyCoverUrl: story.value!.coverImageUrl.isNotEmpty ? story.value!.coverImageUrl : '',
          chapterId: currentChapter.value!.id,
          chapterTitle: currentChapter.value!.title,
          chapterNumber: currentChapter.value!.chapterNumber,
          action: ReadingAction.read,
          sourceWebsite: story.value!.sourceWebsite,
          sessionId: _currentSessionId!,
          readingDuration: 0, // Just started reading
          wordsRead: 0, // Will be updated later
          scrollProgress: 0.0, // Just started
        );

        await _historyService.addHistory(historyEntry);
        print('📚 Successfully tracked chapter reading start');
    } catch (e) {
      print('📚 Error tracking chapter read: $e');
    }
  }


}
