import 'package:get/get.dart';
import '../../library/controllers/library_controller.dart';
import '../../history/controllers/history_controller.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';

class HomeController extends GetxController {
  // Observable cho current tab index
  final currentIndex = 0.obs;

  // Danh sách các tab
  final List<String> tabTitles = [
    'Thư viện',
    'Đọc truyện',
    'AI',
    'Lịch sử',
    'Cài đặt',
  ];

  // Services
  late final LibraryService _libraryService;
  late final ChapterService _chapterService;

  // Preload state
  bool _hasPreloadedChapters = false;

  // Thay đổi tab
  void changeTabIndex(int index) {
    final previousIndex = currentIndex.value;
    currentIndex.value = index;

    // Notify library controller when switching to library tab
    if (index == 0 && previousIndex != 0) {
      try {
        final libraryController = Get.find<LibraryController>();
        libraryController.onTabVisible();
      } catch (e) {
        // LibraryController might not be initialized yet
        print('LibraryController not found: $e');
      }
    }

    // Notify history controller when switching to history tab
    if (index == 3 && previousIndex != 3) {
      try {
        final historyController = Get.find<HistoryController>();
        historyController.onTabFocused();

        // Preload chapters from cache when user goes to history tab
        _preloadChaptersFromCache();
      } catch (e) {
        // HistoryController might not be initialized yet
        print('HistoryController not found: $e');
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
  }

  @override
  void onReady() {
    super.onReady();
    // Delay preload to ensure all services are ready
    Future.delayed(const Duration(seconds: 1), () {
      _preloadChaptersFromCache();
    });
  }

  // Initialize services
  void _initializeServices() {
    try {
      _libraryService = Get.find<LibraryService>();
      _chapterService = Get.find<ChapterService>();
      print('🏠 HomeController services initialized successfully');
    } catch (e) {
      print('🏠 Error initializing services: $e');
    }
  }

  // Preload all chapters from cache for all stories
  Future<void> _preloadChaptersFromCache() async {
    if (_hasPreloadedChapters) {
      print('🏠 Chapters already preloaded from cache, skipping...');
      return;
    }

    try {
      print('🏠 Starting to preload chapters from cache...');

      // Ensure ChapterService is initialized
      await _chapterService.init();

      // Get all stories from library
      final stories = _libraryService.getAllStories();
      print(
        '🏠 Found ${stories.length} stories to preload chapters from cache',
      );

      if (stories.isEmpty) {
        print('🏠 No stories found, skipping preload');
        return;
      }

      int totalChapters = 0;
      int storiesWithChapters = 0;

      // Load chapters from cache for each story
      for (final story in stories) {
        try {
          final cachedChapters = _chapterService.getChaptersByStoryId(story.id);

          if (cachedChapters.isNotEmpty) {
            totalChapters += cachedChapters.length;
            storiesWithChapters++;

            final chaptersWithContent = cachedChapters
                .where((c) => c.hasContent)
                .length;
            print(
              '🏠 ✅ ${story.title}: ${cachedChapters.length} chapters (${chaptersWithContent} with content)',
            );
          } else {
            print('🏠 ⚠️ ${story.title}: No cached chapters found');
          }
        } catch (e) {
          print('🏠 ❌ Error loading chapters for ${story.title}: $e');
        }
      }

      print(
        '🏠 📊 Preload summary: $totalChapters chapters from $storiesWithChapters/${stories.length} stories',
      );
      print('🏠 ✅ Finished preloading chapters from cache');
      _hasPreloadedChapters = true;
    } catch (e) {
      print('🏠 ❌ Error in preload process: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
