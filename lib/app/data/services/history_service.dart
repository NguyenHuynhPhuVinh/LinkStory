import 'package:hive/hive.dart';
import 'package:get/get.dart';
import '../models/reading_history_model.dart';
import '../models/story_model.dart';
import '../models/chapter_model.dart';

class HistoryService extends GetxService {
  static const String _boxName = 'reading_history';
  Box<ReadingHistory>? _historyBox;

  // Singleton pattern
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  // Getter for easy access
  static HistoryService get to => Get.find<HistoryService>();

  // Initialize service
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(ReadingHistoryAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ReadingActionAdapter());
    }
    _historyBox = await Hive.openBox<ReadingHistory>(_boxName);
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await init();
  }

  // ==================== CRUD OPERATIONS ====================

  // Thêm lịch sử đọc mới
  Future<bool> addHistory(ReadingHistory history) async {
    try {
      await _historyBox?.put(history.id, history);
      return true;
    } catch (e) {
      print('Error adding reading history: $e');
      return false;
    }
  }

  // Lấy tất cả lịch sử
  List<ReadingHistory> getAllHistory() {
    return _historyBox?.values.toList() ?? [];
  }

  // Lấy lịch sử theo ID
  ReadingHistory? getHistoryById(String id) {
    return _historyBox?.get(id);
  }

  // Cập nhật lịch sử
  Future<void> updateHistory(ReadingHistory history) async {
    await _historyBox?.put(history.id, history);
  }

  // Xóa lịch sử theo ID
  Future<void> deleteHistory(String id) async {
    await _historyBox?.delete(id);
  }

  // Xóa tất cả lịch sử
  Future<void> clearAllHistory() async {
    await _historyBox?.clear();
  }

  // ==================== TRACKING METHODS ====================

  // Track khi đọc chương
  Future<void> trackChapterRead({
    required Story story,
    required Chapter chapter,
    required String sessionId,
    int readingDuration = 0,
    double scrollProgress = 0.0,
    int wordsRead = 0,
    double readingSpeed = 0.0,
    bool isOffline = false,
    String? translationLanguage,
  }) async {
    final history = ReadingHistory(
      id: '${story.id}_${chapter.id}_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      chapterId: chapter.id,
      chapterTitle: chapter.displayTitle,
      chapterNumber: chapter.chapterNumber,
      readingDuration: readingDuration,
      scrollProgress: scrollProgress,
      action: ReadingAction.read,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
      wordsRead: wordsRead,
      readingSpeed: readingSpeed,
      isOffline: isOffline,
      translationLanguage: translationLanguage,
      metadata: {
        'volumeTitle': chapter.volumeTitle,
        'volumeNumber': chapter.volumeNumber,
        'wordCount': chapter.wordCount,
        'hasImages': chapter.hasImages,
      },
    );

    await addHistory(history);
  }

  // Track khi thêm truyện vào thư viện
  Future<void> trackAddToLibrary(Story story, String sessionId) async {
    final history = ReadingHistory(
      id: '${story.id}_add_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      action: ReadingAction.addToLibrary,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
    );

    await addHistory(history);
  }

  // Track khi xóa truyện khỏi thư viện
  Future<void> trackRemoveFromLibrary(Story story, String sessionId) async {
    final history = ReadingHistory(
      id: '${story.id}_remove_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      action: ReadingAction.removeFromLibrary,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
    );

    await addHistory(history);
  }

  // Track khi đánh dấu yêu thích
  Future<void> trackFavorite(Story story, String sessionId, bool isFavorite) async {
    final history = ReadingHistory(
      id: '${story.id}_fav_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      action: isFavorite ? ReadingAction.favorite : ReadingAction.unfavorite,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
    );

    await addHistory(history);
  }

  // Track khi đánh giá truyện
  Future<void> trackRating(Story story, String sessionId, double rating) async {
    final history = ReadingHistory(
      id: '${story.id}_rate_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      action: ReadingAction.rate,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
      metadata: {'rating': rating},
    );

    await addHistory(history);
  }

  // Track khi chia sẻ
  Future<void> trackShare(Story story, String sessionId, {Chapter? chapter}) async {
    final history = ReadingHistory(
      id: '${story.id}_share_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      chapterId: chapter?.id,
      chapterTitle: chapter?.displayTitle,
      chapterNumber: chapter?.chapterNumber,
      action: ReadingAction.share,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
    );

    await addHistory(history);
  }

  // Track khi dịch
  Future<void> trackTranslation(Story story, String sessionId, String language, {Chapter? chapter}) async {
    final history = ReadingHistory(
      id: '${story.id}_trans_${DateTime.now().millisecondsSinceEpoch}',
      storyId: story.id,
      storyTitle: story.displayTitle,
      storyAuthor: story.author,
      storyCoverUrl: story.coverImageUrl,
      chapterId: chapter?.id,
      chapterTitle: chapter?.displayTitle,
      chapterNumber: chapter?.chapterNumber,
      action: ReadingAction.translate,
      sourceWebsite: story.sourceWebsite,
      sessionId: sessionId,
      translationLanguage: language,
    );

    await addHistory(history);
  }

  // ==================== QUERY METHODS ====================

  // Lấy lịch sử theo truyện
  List<ReadingHistory> getHistoryByStory(String storyId) {
    return getAllHistory()
        .where((history) => history.storyId == storyId)
        .toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));
  }

  // Lấy lịch sử đọc gần đây
  List<ReadingHistory> getRecentHistory({int limit = 50}) {
    final history = getAllHistory();
    history.sort((a, b) => b.readAt.compareTo(a.readAt));
    return history.take(limit).toList();
  }

  // Lấy lịch sử theo ngày
  List<ReadingHistory> getHistoryByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getAllHistory()
        .where((history) => 
            history.readAt.isAfter(startOfDay) && 
            history.readAt.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));
  }

  // Lấy lịch sử theo khoảng thời gian
  List<ReadingHistory> getHistoryByDateRange(DateTime startDate, DateTime endDate) {
    return getAllHistory()
        .where((history) => 
            history.readAt.isAfter(startDate) && 
            history.readAt.isBefore(endDate))
        .toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));
  }

  // Lấy lịch sử theo hành động
  List<ReadingHistory> getHistoryByAction(ReadingAction action) {
    return getAllHistory()
        .where((history) => history.action == action)
        .toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));
  }

  // Lấy lịch sử đọc chương
  List<ReadingHistory> getChapterReadHistory() {
    return getHistoryByAction(ReadingAction.read)
        .where((history) => history.isChapterRead)
        .toList();
  }

  // Lấy truyện đã đọc gần đây (unique stories)
  List<ReadingHistory> getRecentlyReadStories({int limit = 20}) {
    final readHistory = getChapterReadHistory();
    final Map<String, ReadingHistory> uniqueStories = {};

    for (final history in readHistory) {
      if (!uniqueStories.containsKey(history.storyId) ||
          uniqueStories[history.storyId]!.readAt.isBefore(history.readAt)) {
        uniqueStories[history.storyId] = history;
      }
    }

    final result = uniqueStories.values.toList();
    result.sort((a, b) => b.readAt.compareTo(a.readAt));
    return result.take(limit).toList();
  }

  // Lấy lịch sử gần nhất cho truyện và chương cụ thể
  ReadingHistory? getHistoryByStoryAndChapter(String storyId, String chapterId) {
    final entries = getAllHistory()
        .where((history) =>
            history.storyId == storyId &&
            history.chapterId == chapterId)
        .toList();

    if (entries.isEmpty) return null;

    // Sort by readAt descending and return the most recent
    entries.sort((a, b) => b.readAt.compareTo(a.readAt));
    return entries.first;
  }



  // ==================== UTILITY METHODS ====================

  // Tạo session ID mới
  String generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Kiểm tra xem có lịch sử không
  bool get hasHistory => getAllHistory().isNotEmpty;

  // Lấy lịch sử mới nhất
  ReadingHistory? get latestHistory {
    final history = getAllHistory();
    if (history.isEmpty) return null;
    history.sort((a, b) => b.readAt.compareTo(a.readAt));
    return history.first;
  }

  // Export lịch sử ra JSON
  Map<String, dynamic> exportHistory() {
    final history = getAllHistory();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'version': '1.0',
      'total_records': history.length,
      'history': history.map((h) => h.toJson()).toList(),
    };
  }

  // Import lịch sử từ JSON
  Future<int> importHistory(Map<String, dynamic> data) async {
    try {
      final historyData = data['history'] as List<dynamic>;
      int importedCount = 0;

      for (final historyItem in historyData) {
        try {
          final history = ReadingHistory.fromJson(historyItem as Map<String, dynamic>);
          if (await addHistory(history)) {
            importedCount++;
          }
        } catch (e) {
          print('Error importing history item: $e');
        }
      }

      return importedCount;
    } catch (e) {
      print('Error importing history: $e');
      return 0;
    }
  }
}
