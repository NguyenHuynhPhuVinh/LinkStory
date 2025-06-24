import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../data/models/reading_history_model.dart';
import '../../../data/models/story_model.dart';
import '../../../data/models/chapter_model.dart';
import '../../../data/services/history_service.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../story_detail/controllers/story_detail_controller.dart';

class HistoryController extends GetxController {
  // Services
  late final HistoryService _historyService;
  late final LibraryService _libraryService;

  // Observable states
  final RxList<ReadingHistory> allHistory = <ReadingHistory>[].obs;
  final RxList<ReadingHistory> filteredHistory = <ReadingHistory>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final Rx<HistoryFilter> currentFilter = HistoryFilter.all.obs;
  final Rx<HistorySortBy> currentSort = HistorySortBy.dateDesc.obs;
  final RxString selectedDateRange = 'Tất cả'.obs;

  // No tab controller needed - single view only

  // Date range selection
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  // Search controller
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // Initialize services
    try {
      _historyService = Get.find<HistoryService>();
      _libraryService = Get.find<LibraryService>();
    } catch (e) {
      print('Error finding services: $e');
      Get.snackbar('Lỗi', 'Không thể khởi tạo dịch vụ lịch sử');
      return;
    }

    // Load initial data
    loadHistory();

    // Listen to search changes
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _applyFilters();
    });

    // Listen to filter changes
    ever(currentFilter, (_) => _applyFilters());
    ever(currentSort, (_) => _applyFilters());
    ever(startDate, (_) => _applyFilters());
    ever(endDate, (_) => _applyFilters());
  }

  @override
  void onReady() {
    super.onReady();
    // Auto-reload when view becomes ready
    refreshHistory();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // ==================== DATA LOADING ====================

  // Load all history
  Future<void> loadHistory() async {
    try {
      isLoading.value = true;
      final history = _historyService.getAllHistory();
      print('📚 Loaded ${history.length} history items');
      allHistory.assignAll(history);
      _applyFilters();
      print('📚 After filtering: ${filteredHistory.length} items');
    } catch (e) {
      print('Error loading history: $e');
      Get.snackbar('Lỗi', 'Không thể tải lịch sử đọc');
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh data
  Future<void> refreshHistory() async {
    await loadHistory();
  }

  // Method to be called when tab becomes active
  void onTabFocused() {
    print('📚 History tab focused - refreshing data');
    refreshHistory();
  }

  // ==================== FILTERING & SORTING ====================

  void _applyFilters() {
    List<ReadingHistory> filtered = List.from(allHistory);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered
          .where(
            (history) =>
                history.storyTitle.toLowerCase().contains(query) ||
                history.storyAuthor.toLowerCase().contains(query) ||
                (history.chapterTitle?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    // Apply action filter
    switch (currentFilter.value) {
      case HistoryFilter.read:
        filtered = filtered
            .where((h) => h.action == ReadingAction.read)
            .toList();
        break;
      case HistoryFilter.library:
        filtered = filtered
            .where(
              (h) =>
                  h.action == ReadingAction.addToLibrary ||
                  h.action == ReadingAction.removeFromLibrary,
            )
            .toList();
        break;
      case HistoryFilter.favorite:
        filtered = filtered
            .where(
              (h) =>
                  h.action == ReadingAction.favorite ||
                  h.action == ReadingAction.unfavorite,
            )
            .toList();
        break;
      case HistoryFilter.translate:
        filtered = filtered
            .where((h) => h.action == ReadingAction.translate)
            .toList();
        break;
      case HistoryFilter.all:
        // No additional filtering
        break;
    }

    // Apply date range filter
    if (startDate.value != null && endDate.value != null) {
      filtered = filtered
          .where(
            (history) =>
                history.readAt.isAfter(startDate.value!) &&
                history.readAt.isBefore(
                  endDate.value!.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    // Apply sorting
    switch (currentSort.value) {
      case HistorySortBy.dateDesc:
        filtered.sort((a, b) => b.readAt.compareTo(a.readAt));
        break;
      case HistorySortBy.dateAsc:
        filtered.sort((a, b) => a.readAt.compareTo(b.readAt));
        break;
      case HistorySortBy.storyTitle:
        filtered.sort((a, b) => a.storyTitle.compareTo(b.storyTitle));
        break;
      case HistorySortBy.readingTime:
        filtered.sort((a, b) => b.readingDuration.compareTo(a.readingDuration));
        break;
    }

    filteredHistory.assignAll(filtered);
  }

  // Set filter
  void setFilter(HistoryFilter filter) {
    currentFilter.value = filter;
  }

  // Set sort
  void setSort(HistorySortBy sort) {
    currentSort.value = sort;
  }

  // Set date range
  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;

    if (start != null && end != null) {
      selectedDateRange.value = '${_formatDate(start)} - ${_formatDate(end)}';
    } else {
      selectedDateRange.value = 'Tất cả';
    }
  }

  // Clear filters
  void clearFilters() {
    searchController.clear();
    currentFilter.value = HistoryFilter.all;
    currentSort.value = HistorySortBy.dateDesc;
    startDate.value = null;
    endDate.value = null;
    selectedDateRange.value = 'Tất cả';
  }

  // ==================== HISTORY ACTIONS ====================

  // Delete single history item
  Future<void> deleteHistoryItem(String historyId) async {
    try {
      await _historyService.deleteHistory(historyId);
      await refreshHistory();
      Get.snackbar('Thành công', 'Đã xóa lịch sử');
    } catch (e) {
      print('Error deleting history: $e');
      Get.snackbar('Lỗi', 'Không thể xóa lịch sử');
    }
  }

  // Delete multiple history items
  Future<void> deleteMultipleHistory(List<String> historyIds) async {
    try {
      for (final id in historyIds) {
        await _historyService.deleteHistory(id);
      }
      await refreshHistory();
      Get.snackbar('Thành công', 'Đã xóa ${historyIds.length} mục lịch sử');
    } catch (e) {
      print('Error deleting multiple history: $e');
      Get.snackbar('Lỗi', 'Không thể xóa lịch sử');
    }
  }

  // Clear all history
  Future<void> clearAllHistory() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử đọc?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Xóa'),
            ),
          ],
        ),
      );

      if (result == true) {
        await _historyService.clearAllHistory();
        await refreshHistory();
        Get.snackbar('Thành công', 'Đã xóa toàn bộ lịch sử');
      }
    } catch (e) {
      print('Error clearing all history: $e');
      Get.snackbar('Lỗi', 'Không thể xóa lịch sử');
    }
  }

  // Navigate to story detail
  void navigateToStoryDetail(String storyId) {
    final story = _libraryService.getStoryById(storyId);
    if (story != null) {
      Get.toNamed('/story-detail', arguments: story);
    } else {
      Get.snackbar('Lỗi', 'Không tìm thấy thông tin truyện');
    }
  }

  // Continue reading from history
  void continueReading(ReadingHistory history) {
    final story = _libraryService.getStoryById(history.storyId);
    if (story != null) {
      if (history.chapterId != null) {
        // Get the actual chapter object from ChapterService
        try {
          final chapterService = Get.find<ChapterService>();

          // Debug: Check how many chapters exist for this story
          final storyChapters = chapterService.getChaptersByStoryId(
            history.storyId,
          );
          print(
            '📚 Total chapters for story ${history.storyId}: ${storyChapters.length}',
          );
          if (storyChapters.isNotEmpty) {
            print(
              '📚 Available chapters: ${storyChapters.map((c) => '${c.chapterNumber}:${c.title}').join(', ')}',
            );
          }

          // First try to find by exact ID
          Chapter? chapter = chapterService.getChapterById(history.chapterId!);
          print('📚 Found by ID: ${chapter?.title}');

          // If not found by ID, try to find by story and chapter number
          if (chapter == null && history.chapterNumber != null) {
            chapter = storyChapters
                .where((c) => c.chapterNumber == history.chapterNumber)
                .firstOrNull;
            print('📚 Found chapter by number: ${chapter?.title}');
          }

          // If still not found, try to find by title
          if (chapter == null && history.chapterTitle != null) {
            chapter = storyChapters
                .where(
                  (c) =>
                      c.title == history.chapterTitle ||
                      c.displayTitle == history.chapterTitle,
                )
                .firstOrNull;
            print('📚 Found chapter by title: ${chapter?.title}');
          }

          if (chapter != null) {
            // Navigate directly to reading page with chapter object
            Get.toNamed(
              '/reading',
              arguments: {'story': story, 'chapter': chapter},
            );
            print(
              '📚 Navigating to chapter: ${history.chapterTitle} of story: ${history.storyTitle}',
            );
          } else {
            print(
              '📚 Chapter not found with ID: ${history.chapterId}, number: ${history.chapterNumber}, title: ${history.chapterTitle}',
            );

            // If no chapters exist, try to load them automatically
            if (storyChapters.isEmpty) {
              print('📚 No chapters found, trying to auto-load chapters...');
              _autoLoadChaptersAndNavigate(story, history);
            } else {
              Get.snackbar(
                'Lỗi',
                'Không tìm thấy chương "${history.chapterTitle}".\nChương có thể đã bị xóa hoặc thay đổi.',
              );
            }
          }
        } catch (e) {
          print('📚 Error getting chapter: $e');
          Get.snackbar('Lỗi', 'Không thể tải thông tin chương');
        }
      } else {
        // If no specific chapter, navigate to story detail to choose chapter
        Get.toNamed('/story-detail', arguments: story);
      }
    } else {
      // Story not found in library, show error message
      print('📚 Story not found in library: ${history.storyId}');
      Get.snackbar(
        'Lỗi',
        'Truyện "${history.storyTitle}" không còn trong thư viện.\nVui lòng thêm lại truyện để tiếp tục đọc.',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Auto-load chapters and navigate
  Future<void> _autoLoadChaptersAndNavigate(
    Story story,
    ReadingHistory history,
  ) async {
    try {
      Get.snackbar(
        'Đang tải...',
        'Đang tải thông tin chương...',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.BOTTOM,
      );

      // Navigate to story detail to trigger chapter loading
      print('📚 Auto-loading chapters for story: ${story.title}');

      // Navigate to story detail to trigger chapter loading
      Get.toNamed('/story-detail', arguments: story);

      // Wait a bit for the story detail to load chapters
      await Future.delayed(const Duration(milliseconds: 1500));

      // After loading, try to find the chapter again
      final chapterService = Get.find<ChapterService>();
      final storyChapters = chapterService.getChaptersByStoryId(
        history.storyId,
      );
      print('📚 After navigation to story detail, found ${storyChapters.length} chapters');

      Chapter? chapter;
      if (history.chapterNumber != null) {
        chapter = storyChapters
            .where((c) => c.chapterNumber == history.chapterNumber)
            .firstOrNull;
        print('📚 Found by number: ${chapter?.title}');
      }

      if (chapter == null && history.chapterTitle != null) {
        chapter = storyChapters
            .where(
              (c) =>
                  c.title == history.chapterTitle ||
                  c.displayTitle == history.chapterTitle,
            )
            .firstOrNull;
        print('📚 Found by title: ${chapter?.title}');
      }

      if (chapter != null) {
        // Navigate directly to reading page, replacing the story detail page
        Get.offNamed(
          '/reading',
          arguments: {'story': story, 'chapter': chapter},
        );
        print(
          '📚 Successfully auto-loaded and navigated to chapter: ${chapter.title}',
        );
      } else {
        print('📚 Still no chapter found after auto-load');
        // Stay on story detail page if chapter not found
        Get.snackbar(
          'Thông báo',
          'Đã tải thông tin truyện. Vui lòng chọn chương để đọc.',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      print('📚 Error auto-loading chapters: $e');
      Get.snackbar('Lỗi', 'Không thể tải thông tin chương: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  // Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Format duration for display
  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  // Get relative time string
  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  // Export history
  Future<void> exportHistory() async {
    try {
      final data = _historyService.exportHistory();
      // TODO: Implement file saving logic
      Get.snackbar('Thành công', 'Đã xuất lịch sử đọc');
    } catch (e) {
      print('Error exporting history: $e');
      Get.snackbar('Lỗi', 'Không thể xuất lịch sử');
    }
  }

  // Import history
  Future<void> importHistory(Map<String, dynamic> data) async {
    try {
      final importedCount = await _historyService.importHistory(data);
      await refreshHistory();
      Get.snackbar('Thành công', 'Đã nhập $importedCount mục lịch sử');
    } catch (e) {
      print('Error importing history: $e');
      Get.snackbar('Lỗi', 'Không thể nhập lịch sử');
    }
  }
}

// Enums for filtering and sorting
enum HistoryFilter { all, read, library, favorite, translate }

enum HistorySortBy { dateDesc, dateAsc, storyTitle, readingTime }
