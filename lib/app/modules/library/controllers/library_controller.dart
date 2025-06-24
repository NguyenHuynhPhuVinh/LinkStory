import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/story_model.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/story_translation_service.dart';
import '../../../data/services/history_service.dart';

class LibraryController extends GetxController {
  late final LibraryService _libraryService;
  final StoryTranslationService _storyTranslationService = StoryTranslationService();
  late final HistoryService _historyService;

  // Observable states
  final RxList<Story> stories = <Story>[].obs;
  final RxList<Story> filteredStories = <Story>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedFilter = 'all'.obs; // all, favorites, reading, completed
  final RxString selectedSort = 'recent'.obs; // recent, title, author, rating

  // Search controller
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();

    // Get services from dependency injection
    _libraryService = Get.find<LibraryService>();
    _historyService = Get.find<HistoryService>();

    // Initialize translation service
    _storyTranslationService.init();

    // Listen to search changes
    searchQuery.listen((_) => _filterStories());
    selectedFilter.listen((_) => _filterStories());
    selectedSort.listen((_) => _filterStories());
  }

  @override
  void onReady() {
    super.onReady();
    _initializeAndLoadStories();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Called when tab becomes visible
  void onTabVisible() {
    // Only reload if we have stories (to refresh any new additions)
    // or if we haven't loaded yet
    if (stories.isNotEmpty || (!isLoading.value && stories.isEmpty)) {
      loadStories();
    }
  }

  // Initialize library service and load stories
  Future<void> _initializeAndLoadStories() async {
    try {
      isLoading.value = true;
      await _libraryService.init();
      await loadStories();
    } catch (e) {
      print('Error initializing library: $e');
      isLoading.value = false;
    }
  }

  // Load all stories from library
  Future<void> loadStories() async {
    try {
      // Don't set loading here if called from _initializeAndLoadStories
      if (!isLoading.value) {
        isLoading.value = true;
      }

      final allStories = _libraryService.getAllStories();
      stories.value = allStories;
      _filterStories();

      print('Loaded ${allStories.length} stories from library');
    } catch (e) {
      print('Error loading stories: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể tải danh sách truyện',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filter and sort stories
  void _filterStories() {
    List<Story> filtered = List.from(stories);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((story) {
        return story.title.toLowerCase().contains(query) ||
               story.author.toLowerCase().contains(query) ||
               story.description.toLowerCase().contains(query) ||
               story.genres.any((genre) => genre.toLowerCase().contains(query));
      }).toList();
    }

    // Apply category filter
    switch (selectedFilter.value) {
      case 'favorites':
        filtered = filtered.where((story) => story.isFavorite).toList();
        break;
      case 'reading':
        filtered = filtered.where((story) => story.readChapters > 0 && !story.isCompleted).toList();
        break;
      case 'completed':
        filtered = filtered.where((story) => story.isCompleted).toList();
        break;
      case 'all':
      default:
        // No additional filtering
        break;
    }

    // Apply sorting
    switch (selectedSort.value) {
      case 'title':
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'author':
        filtered.sort((a, b) => a.author.compareTo(b.author));
        break;
      case 'rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
    }

    filteredStories.value = filtered;
  }

  // Search stories
  void searchStories(String query) {
    searchQuery.value = query;
  }

  // Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  // Set filter
  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  // Set sort
  void setSort(String sort) {
    selectedSort.value = sort;
  }

  // Toggle favorite
  Future<void> toggleFavorite(Story story) async {
    try {
      final sessionId = _historyService.generateSessionId();
      final wasFavorite = story.isFavorite;

      await _libraryService.toggleFavorite(story.id);
      await loadStories(); // Reload to get updated data

      // Track favorite action
      await _historyService.trackFavorite(story, sessionId, !wasFavorite);

      Get.snackbar(
        wasFavorite ? 'Đã bỏ yêu thích' : 'Đã thêm vào yêu thích',
        story.title,
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

  // Remove story from library
  Future<void> removeStory(Story story) async {
    try {
      final sessionId = _historyService.generateSessionId();

      await _libraryService.removeStory(story.id);
      await loadStories(); // Reload to get updated data

      // Track remove from library action
      await _historyService.trackRemoveFromLibrary(story, sessionId);

      Get.snackbar(
        'Đã xóa',
        'Truyện "${story.title}" đã được xóa khỏi thư viện',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('Error removing story: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể xóa truyện khỏi thư viện',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }

  // Get library statistics
  Map<String, dynamic> getLibraryStats() {
    return _libraryService.getLibraryStats();
  }

  // Refresh library
  Future<void> refreshLibrary() async {
    await loadStories();
  }

  // Translate story to Vietnamese
  Future<void> translateStory(Story story) async {
    final updatedStory = await _storyTranslationService.translateStory(story);
    if (updatedStory != null) {
      // Reload stories to reflect changes
      await loadStories();
    }
  }

  // Get translation states
  RxBool get isTranslating => _storyTranslationService.isTranslating;
  RxString get translatingStoryId => _storyTranslationService.translatingStoryId;
}
