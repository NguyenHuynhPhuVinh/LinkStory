import 'package:hive/hive.dart';
import '../models/chapter_model.dart';

class ChapterService {
  static const String _boxName = 'chapters';
  Box<Chapter>? _chapterBox;

  // Singleton pattern
  static final ChapterService _instance = ChapterService._internal();
  factory ChapterService() => _instance;
  ChapterService._internal();

  // Initialize service
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ChapterAdapter());
    }
    _chapterBox = await Hive.openBox<Chapter>(_boxName);
  }

  // Thêm chapter vào database
  Future<bool> addChapter(Chapter chapter) async {
    try {
      // Kiểm tra xem chapter đã tồn tại chưa
      if (await isChapterExists(chapter.id)) {
        return false; // Chapter đã tồn tại
      }

      await _chapterBox?.put(chapter.id, chapter);
      return true;
    } catch (e) {
      print('Error adding chapter: $e');
      return false;
    }
  }

  // Thêm nhiều chapters cùng lúc
  Future<int> addChapters(List<Chapter> chapters) async {
    int addedCount = 0;
    for (final chapter in chapters) {
      if (await addChapter(chapter)) {
        addedCount++;
      }
    }
    return addedCount;
  }

  // Kiểm tra chapter có tồn tại không
  Future<bool> isChapterExists(String chapterId) async {
    return _chapterBox?.containsKey(chapterId) ?? false;
  }

  // Lấy tất cả chapters của một truyện
  List<Chapter> getChaptersByStoryId(String storyId) {
    final allChapters = _chapterBox?.values.toList() ?? [];
    return allChapters
        .where((chapter) => chapter.storyId == storyId)
        .toList()
      ..sort((a, b) {
        // Sắp xếp theo volume number, rồi chapter number
        if (a.volumeNumber != b.volumeNumber) {
          return a.volumeNumber.compareTo(b.volumeNumber);
        }
        return a.chapterNumber.compareTo(b.chapterNumber);
      });
  }

  // Lấy chapter theo ID
  Chapter? getChapterById(String id) {
    return _chapterBox?.get(id);
  }

  // Lấy chapter theo URL
  Chapter? getChapterByUrl(String url) {
    final chapters = _chapterBox?.values.toList() ?? [];
    try {
      return chapters.firstWhere((chapter) => chapter.url == url);
    } catch (e) {
      return null;
    }
  }

  // Cập nhật chapter
  Future<void> updateChapter(Chapter chapter) async {
    final updatedChapter = chapter.copyWith(updatedAt: DateTime.now());
    await _chapterBox?.put(chapter.id, updatedChapter);
  }

  // Cập nhật nội dung chapter
  Future<void> updateChapterContent(String chapterId, String content) async {
    final chapter = getChapterById(chapterId);
    if (chapter != null) {
      final updatedChapter = chapter.copyWith(
        content: content,
        wordCount: _countWords(content),
        updatedAt: DateTime.now(),
      );
      await updateChapter(updatedChapter);
    }
  }

  // Đánh dấu chapter đã đọc
  Future<void> markChapterAsRead(String chapterId) async {
    final chapter = getChapterById(chapterId);
    if (chapter != null) {
      final updatedChapter = chapter.copyWith(
        isRead: true,
        updatedAt: DateTime.now(),
      );
      await updateChapter(updatedChapter);
    }
  }

  // Đánh dấu chapter chưa đọc
  Future<void> markChapterAsUnread(String chapterId) async {
    final chapter = getChapterById(chapterId);
    if (chapter != null) {
      final updatedChapter = chapter.copyWith(
        isRead: false,
        updatedAt: DateTime.now(),
      );
      await updateChapter(updatedChapter);
    }
  }

  // Cập nhật nội dung đã dịch của chapter
  Future<void> updateChapterTranslation(
    String chapterId,
    String translatedTitle,
    String translatedContent
  ) async {
    final chapter = getChapterById(chapterId);
    if (chapter != null) {
      final updatedChapter = chapter.copyWith(
        translatedTitle: translatedTitle,
        translatedContent: translatedContent,
        isTranslated: true,
        translatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await updateChapter(updatedChapter);
    }
  }

  // Xóa bản dịch của chapter
  Future<void> removeChapterTranslation(String chapterId) async {
    final chapter = getChapterById(chapterId);
    if (chapter != null) {
      final updatedChapter = chapter.copyWith(
        translatedTitle: null,
        translatedContent: null,
        isTranslated: false,
        translatedAt: null,
        updatedAt: DateTime.now(),
      );
      await updateChapter(updatedChapter);
    }
  }

  // Xóa chapter
  Future<void> removeChapter(String id) async {
    await _chapterBox?.delete(id);
  }

  // Xóa tất cả chapters của một truyện
  Future<void> removeChaptersByStoryId(String storyId) async {
    final chapters = getChaptersByStoryId(storyId);
    for (final chapter in chapters) {
      await removeChapter(chapter.id);
    }
  }

  // Lấy chapters đã đọc của một truyện
  List<Chapter> getReadChaptersByStoryId(String storyId) {
    return getChaptersByStoryId(storyId)
        .where((chapter) => chapter.isRead)
        .toList();
  }

  // Lấy chapters chưa đọc của một truyện
  List<Chapter> getUnreadChaptersByStoryId(String storyId) {
    return getChaptersByStoryId(storyId)
        .where((chapter) => !chapter.isRead)
        .toList();
  }

  // Lấy chapter tiếp theo chưa đọc
  Chapter? getNextUnreadChapter(String storyId) {
    final unreadChapters = getUnreadChaptersByStoryId(storyId);
    return unreadChapters.isNotEmpty ? unreadChapters.first : null;
  }

  // Lấy thống kê chapters của một truyện
  Map<String, dynamic> getChapterStats(String storyId) {
    final chapters = getChaptersByStoryId(storyId);
    final readChapters = chapters.where((c) => c.isRead).length;
    final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);
    
    // Nhóm theo volume
    final volumeGroups = <int, List<Chapter>>{};
    for (final chapter in chapters) {
      volumeGroups.putIfAbsent(chapter.volumeNumber, () => []).add(chapter);
    }

    return {
      'total': chapters.length,
      'read': readChapters,
      'unread': chapters.length - readChapters,
      'totalWords': totalWords,
      'volumes': volumeGroups.length,
      'readingProgress': chapters.isNotEmpty ? readChapters / chapters.length : 0.0,
    };
  }

  // Lấy tất cả chapters có nội dung
  List<Chapter> getChaptersWithContent(String storyId) {
    return getChaptersByStoryId(storyId)
        .where((chapter) => chapter.hasContent)
        .toList();
  }

  // Lấy tất cả chapters chưa có nội dung
  List<Chapter> getChaptersWithoutContent(String storyId) {
    return getChaptersByStoryId(storyId)
        .where((chapter) => !chapter.hasContent)
        .toList();
  }

  // Tìm kiếm chapters theo title
  List<Chapter> searchChapters(String storyId, String query) {
    if (query.isEmpty) return getChaptersByStoryId(storyId);

    final lowercaseQuery = query.toLowerCase();
    return getChaptersByStoryId(storyId).where((chapter) {
      return chapter.title.toLowerCase().contains(lowercaseQuery) ||
             chapter.volumeTitle.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Helper method để đếm từ
  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  // Export chapters ra JSON
  Map<String, dynamic> exportChapters(String storyId) {
    final chapters = getChaptersByStoryId(storyId);
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'story_id': storyId,
      'version': '1.0',
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  // Import chapters từ JSON
  Future<int> importChapters(Map<String, dynamic> data) async {
    try {
      final chaptersData = data['chapters'] as List<dynamic>;
      int importedCount = 0;

      for (final chapterData in chaptersData) {
        try {
          final chapter = Chapter.fromJson(chapterData as Map<String, dynamic>);
          if (await addChapter(chapter)) {
            importedCount++;
          }
        } catch (e) {
          print('Error importing chapter: $e');
        }
      }

      return importedCount;
    } catch (e) {
      print('Error importing chapters: $e');
      return 0;
    }
  }
}
