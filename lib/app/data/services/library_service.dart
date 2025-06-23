import 'package:hive/hive.dart';
import '../models/story_model.dart';

class LibraryService {
  static const String _boxName = 'stories';
  Box<Story>? _storyBox;

  // Singleton pattern
  static final LibraryService _instance = LibraryService._internal();
  factory LibraryService() => _instance;
  LibraryService._internal();

  // Initialize service
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StoryAdapter());
    }
    _storyBox = await Hive.openBox<Story>(_boxName);
  }

  // Thêm truyện vào thư viện
  Future<bool> addStory(Story story) async {
    try {
      // Kiểm tra xem truyện đã tồn tại chưa
      if (await isStoryExists(story.id)) {
        return false; // Truyện đã tồn tại
      }

      await _storyBox?.put(story.id, story);
      return true;
    } catch (e) {
      print('Error adding story to library: $e');
      return false;
    }
  }

  // Kiểm tra truyện có tồn tại trong thư viện không
  Future<bool> isStoryExists(String storyId) async {
    return _storyBox?.containsKey(storyId) ?? false;
  }

  // Kiểm tra URL có tồn tại trong thư viện không
  Future<bool> isUrlExists(String url) async {
    final stories = getAllStories();
    return stories.any((story) => story.sourceUrl == url);
  }

  // Lấy tất cả truyện trong thư viện
  List<Story> getAllStories() {
    return _storyBox?.values.toList() ?? [];
  }

  // Lấy truyện theo ID
  Story? getStoryById(String id) {
    return _storyBox?.get(id);
  }

  // Lấy truyện theo URL
  Story? getStoryByUrl(String url) {
    final stories = getAllStories();
    try {
      return stories.firstWhere((story) => story.sourceUrl == url);
    } catch (e) {
      return null;
    }
  }

  // Cập nhật truyện
  Future<void> updateStory(Story story) async {
    final updatedStory = story.copyWith(updatedAt: DateTime.now());
    await _storyBox?.put(story.id, updatedStory);
  }

  // Xóa truyện khỏi thư viện
  Future<void> removeStory(String id) async {
    await _storyBox?.delete(id);
  }

  // Lấy truyện yêu thích
  List<Story> getFavoriteStories() {
    return getAllStories().where((story) => story.isFavorite).toList();
  }

  // Lấy truyện đang đọc (có tiến độ)
  List<Story> getReadingStories() {
    return getAllStories()
        .where((story) => story.readChapters > 0 && !story.isCompleted)
        .toList();
  }

  // Lấy truyện đã hoàn thành đọc
  List<Story> getCompletedStories() {
    return getAllStories().where((story) => story.isCompleted).toList();
  }

  // Lấy truyện mới thêm
  List<Story> getRecentStories({int limit = 10}) {
    final stories = getAllStories();
    stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return stories.take(limit).toList();
  }

  // Lấy truyện đã đọc gần đây
  List<Story> getRecentlyReadStories({int limit = 10}) {
    final stories = getAllStories()
        .where((story) => story.lastReadAt != null)
        .toList();
    stories.sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
    return stories.take(limit).toList();
  }

  // Tìm kiếm truyện
  List<Story> searchStories(String query) {
    if (query.isEmpty) return getAllStories();

    final lowercaseQuery = query.toLowerCase();
    return getAllStories().where((story) {
      return story.title.toLowerCase().contains(lowercaseQuery) ||
             story.author.toLowerCase().contains(lowercaseQuery) ||
             story.description.toLowerCase().contains(lowercaseQuery) ||
             story.genres.any((genre) => genre.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Lọc truyện theo thể loại
  List<Story> getStoriesByGenre(String genre) {
    return getAllStories()
        .where((story) => story.genres.contains(genre))
        .toList();
  }

  // Lọc truyện theo trạng thái
  List<Story> getStoriesByStatus(String status) {
    return getAllStories()
        .where((story) => story.status == status)
        .toList();
  }

  // Lọc truyện theo website nguồn
  List<Story> getStoriesByWebsite(String website) {
    return getAllStories()
        .where((story) => story.sourceWebsite == website)
        .toList();
  }

  // Đánh dấu truyện là yêu thích
  Future<void> toggleFavorite(String storyId) async {
    final story = getStoryById(storyId);
    if (story != null) {
      final updatedStory = story.copyWith(
        isFavorite: !story.isFavorite,
        updatedAt: DateTime.now(),
      );
      await updateStory(updatedStory);
    }
  }

  // Cập nhật tiến độ đọc
  Future<void> updateReadingProgress(String storyId, int readChapters) async {
    final story = getStoryById(storyId);
    if (story != null) {
      final updatedStory = story.copyWith(
        readChapters: readChapters,
        lastReadAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateStory(updatedStory);
    }
  }

  // Đánh giá truyện
  Future<void> rateStory(String storyId, double rating) async {
    final story = getStoryById(storyId);
    if (story != null && rating >= 0.0 && rating <= 5.0) {
      final updatedStory = story.copyWith(
        rating: rating,
        updatedAt: DateTime.now(),
      );
      await updateStory(updatedStory);
    }
  }

  // Lấy thống kê thư viện
  Map<String, dynamic> getLibraryStats() {
    final stories = getAllStories();
    final favoriteCount = stories.where((s) => s.isFavorite).length;
    final readingCount = stories.where((s) => s.readChapters > 0 && !s.isCompleted).length;
    final completedCount = stories.where((s) => s.isCompleted).length;

    final genreCount = <String, int>{};
    for (final story in stories) {
      for (final genre in story.genres) {
        genreCount[genre] = (genreCount[genre] ?? 0) + 1;
      }
    }

    return {
      'total': stories.length,
      'favorites': favoriteCount,
      'reading': readingCount,
      'completed': completedCount,
      'genres': genreCount,
    };
  }

  // Lấy tất cả thể loại
  List<String> getAllGenres() {
    final genres = <String>{};
    for (final story in getAllStories()) {
      genres.addAll(story.genres);
    }
    return genres.toList()..sort();
  }

  // Lấy tất cả website nguồn
  List<String> getAllSourceWebsites() {
    final websites = <String>{};
    for (final story in getAllStories()) {
      websites.add(story.sourceWebsite);
    }
    return websites.toList()..sort();
  }

  // Đóng service
  Future<void> close() async {
    await _storyBox?.close();
  }

  // Xóa toàn bộ thư viện (cẩn thận!)
  Future<void> clearLibrary() async {
    await _storyBox?.clear();
  }

  // Export thư viện ra JSON
  Map<String, dynamic> exportLibrary() {
    final stories = getAllStories();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0',
      'stories': stories.map((story) => story.toJson()).toList(),
    };
  }

  // Import thư viện từ JSON
  Future<int> importLibrary(Map<String, dynamic> data) async {
    try {
      final storiesData = data['stories'] as List<dynamic>;
      int importedCount = 0;

      for (final storyData in storiesData) {
        try {
          final story = Story.fromJson(storyData as Map<String, dynamic>);
          if (await addStory(story)) {
            importedCount++;
          }
        } catch (e) {
          print('Error importing story: $e');
        }
      }

      return importedCount;
    } catch (e) {
      print('Error importing library: $e');
      return 0;
    }
  }
}
