import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../../data/services/webview_scraper_service.dart';
import '../../story_detail/controllers/story_detail_controller.dart';

class ReadingController extends GetxController {
  late final LibraryService _libraryService;
  late final ChapterService _chapterService;
  late final WebViewScraperService _scraperService;
  
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
  
  @override
  void onInit() {
    super.onInit();
    
    // Get services from GetX
    _libraryService = Get.find<LibraryService>();
    _chapterService = Get.find<ChapterService>();
    _scraperService = WebViewScraperService();
    
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

        await loadChapterContent();
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
        chapterContent.value = currentChapter.value!.content;
        print('✅ Loaded cached content for: ${currentChapter.value!.title} (${currentChapter.value!.content.length} chars)');
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
}
