import 'package:hive/hive.dart';

part 'reading_history_model.g.dart';

@HiveType(typeId: 3)
class ReadingHistory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String storyId; // ID của truyện

  @HiveField(2)
  String storyTitle; // Tên truyện (để hiển thị nhanh)

  @HiveField(3)
  String storyAuthor; // Tác giả (để hiển thị nhanh)

  @HiveField(4)
  String storyCoverUrl; // Ảnh bìa (để hiển thị nhanh)

  @HiveField(5)
  String? chapterId; // ID chương đã đọc (null nếu chỉ xem thông tin truyện)

  @HiveField(6)
  String? chapterTitle; // Tên chương đã đọc

  @HiveField(7)
  int? chapterNumber; // Số thứ tự chương

  @HiveField(8)
  DateTime readAt; // Thời gian đọc

  @HiveField(9)
  int readingDuration; // Thời gian đọc (giây)

  @HiveField(10)
  double scrollProgress; // Tiến độ cuộn trong chương (0.0 - 1.0)

  @HiveField(11)
  ReadingAction action; // Hành động: đọc, thêm vào thư viện, đánh giá, etc.

  @HiveField(12)
  String sourceWebsite; // Website nguồn

  @HiveField(13)
  Map<String, dynamic> metadata; // Thông tin bổ sung

  // Reading session info
  @HiveField(14)
  String sessionId; // ID phiên đọc (để group các action trong 1 session)

  @HiveField(15)
  DateTime sessionStartAt; // Thời gian bắt đầu phiên đọc

  @HiveField(16)
  DateTime? sessionEndAt; // Thời gian kết thúc phiên đọc

  @HiveField(17)
  int wordsRead; // Số từ đã đọc trong session này

  @HiveField(18)
  double readingSpeed; // Tốc độ đọc (từ/phút)

  // Device & Context info
  @HiveField(19)
  String deviceType; // mobile, tablet, desktop

  @HiveField(20)
  bool isOffline; // Đọc offline hay online

  @HiveField(21)
  String? translationLanguage; // Ngôn ngữ dịch nếu có

  ReadingHistory({
    required this.id,
    required this.storyId,
    required this.storyTitle,
    required this.storyAuthor,
    required this.storyCoverUrl,
    this.chapterId,
    this.chapterTitle,
    this.chapterNumber,
    DateTime? readAt,
    this.readingDuration = 0,
    this.scrollProgress = 0.0,
    this.action = ReadingAction.read,
    required this.sourceWebsite,
    this.metadata = const {},
    required this.sessionId,
    DateTime? sessionStartAt,
    this.sessionEndAt,
    this.wordsRead = 0,
    this.readingSpeed = 0.0,
    this.deviceType = 'mobile',
    this.isOffline = false,
    this.translationLanguage,
  })  : readAt = readAt ?? DateTime.now(),
        sessionStartAt = sessionStartAt ?? DateTime.now();

  // Copy with method
  ReadingHistory copyWith({
    String? id,
    String? storyId,
    String? storyTitle,
    String? storyAuthor,
    String? storyCoverUrl,
    String? chapterId,
    String? chapterTitle,
    int? chapterNumber,
    DateTime? readAt,
    int? readingDuration,
    double? scrollProgress,
    ReadingAction? action,
    String? sourceWebsite,
    Map<String, dynamic>? metadata,
    String? sessionId,
    DateTime? sessionStartAt,
    DateTime? sessionEndAt,
    int? wordsRead,
    double? readingSpeed,
    String? deviceType,
    bool? isOffline,
    String? translationLanguage,
  }) {
    return ReadingHistory(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      storyTitle: storyTitle ?? this.storyTitle,
      storyAuthor: storyAuthor ?? this.storyAuthor,
      storyCoverUrl: storyCoverUrl ?? this.storyCoverUrl,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      readAt: readAt ?? this.readAt,
      readingDuration: readingDuration ?? this.readingDuration,
      scrollProgress: scrollProgress ?? this.scrollProgress,
      action: action ?? this.action,
      sourceWebsite: sourceWebsite ?? this.sourceWebsite,
      metadata: metadata ?? this.metadata,
      sessionId: sessionId ?? this.sessionId,
      sessionStartAt: sessionStartAt ?? this.sessionStartAt,
      sessionEndAt: sessionEndAt ?? this.sessionEndAt,
      wordsRead: wordsRead ?? this.wordsRead,
      readingSpeed: readingSpeed ?? this.readingSpeed,
      deviceType: deviceType ?? this.deviceType,
      isOffline: isOffline ?? this.isOffline,
      translationLanguage: translationLanguage ?? this.translationLanguage,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'storyTitle': storyTitle,
      'storyAuthor': storyAuthor,
      'storyCoverUrl': storyCoverUrl,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'chapterNumber': chapterNumber,
      'readAt': readAt.toIso8601String(),
      'readingDuration': readingDuration,
      'scrollProgress': scrollProgress,
      'action': action.name,
      'sourceWebsite': sourceWebsite,
      'metadata': metadata,
      'sessionId': sessionId,
      'sessionStartAt': sessionStartAt.toIso8601String(),
      'sessionEndAt': sessionEndAt?.toIso8601String(),
      'wordsRead': wordsRead,
      'readingSpeed': readingSpeed,
      'deviceType': deviceType,
      'isOffline': isOffline,
      'translationLanguage': translationLanguage,
    };
  }

  // From JSON
  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    return ReadingHistory(
      id: json['id'],
      storyId: json['storyId'],
      storyTitle: json['storyTitle'],
      storyAuthor: json['storyAuthor'],
      storyCoverUrl: json['storyCoverUrl'],
      chapterId: json['chapterId'],
      chapterTitle: json['chapterTitle'],
      chapterNumber: json['chapterNumber'],
      readAt: DateTime.parse(json['readAt']),
      readingDuration: json['readingDuration'] ?? 0,
      scrollProgress: (json['scrollProgress'] ?? 0.0).toDouble(),
      action: ReadingAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => ReadingAction.read,
      ),
      sourceWebsite: json['sourceWebsite'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      sessionId: json['sessionId'],
      sessionStartAt: DateTime.parse(json['sessionStartAt']),
      sessionEndAt: json['sessionEndAt'] != null 
          ? DateTime.parse(json['sessionEndAt']) 
          : null,
      wordsRead: json['wordsRead'] ?? 0,
      readingSpeed: (json['readingSpeed'] ?? 0.0).toDouble(),
      deviceType: json['deviceType'] ?? 'mobile',
      isOffline: json['isOffline'] ?? false,
      translationLanguage: json['translationLanguage'],
    );
  }

  // Helper getters
  String get displayTitle => chapterTitle ?? storyTitle;
  
  String get displaySubtitle {
    if (chapterTitle != null && chapterNumber != null) {
      return 'Chương $chapterNumber: $chapterTitle';
    } else if (chapterTitle != null) {
      return chapterTitle!;
    } else {
      return storyAuthor;
    }
  }

  String get actionDisplayText {
    switch (action) {
      case ReadingAction.read:
        return 'Đã đọc';
      case ReadingAction.addToLibrary:
        return 'Thêm vào thư viện';
      case ReadingAction.removeFromLibrary:
        return 'Xóa khỏi thư viện';
      case ReadingAction.favorite:
        return 'Yêu thích';
      case ReadingAction.unfavorite:
        return 'Bỏ yêu thích';
      case ReadingAction.rate:
        return 'Đánh giá';
      case ReadingAction.share:
        return 'Chia sẻ';
      case ReadingAction.translate:
        return 'Dịch';
      case ReadingAction.download:
        return 'Tải xuống';
      case ReadingAction.view:
        return 'Xem thông tin';
    }
  }

  Duration get readingDurationFormatted => Duration(seconds: readingDuration);

  bool get isChapterRead => chapterId != null;
  
  bool get isRecentSession {
    final now = DateTime.now();
    return now.difference(readAt).inHours < 24;
  }

  @override
  String toString() {
    return 'ReadingHistory(id: $id, storyTitle: $storyTitle, action: $action, readAt: $readAt)';
  }
}

@HiveType(typeId: 4)
enum ReadingAction {
  @HiveField(0)
  read,           // Đọc chương

  @HiveField(1)
  addToLibrary,   // Thêm vào thư viện

  @HiveField(2)
  removeFromLibrary, // Xóa khỏi thư viện

  @HiveField(3)
  favorite,       // Đánh dấu yêu thích

  @HiveField(4)
  unfavorite,     // Bỏ yêu thích

  @HiveField(5)
  rate,           // Đánh giá truyện

  @HiveField(6)
  share,          // Chia sẻ

  @HiveField(7)
  translate,      // Dịch nội dung

  @HiveField(8)
  download,       // Tải xuống

  @HiveField(9)
  view,           // Xem thông tin truyện
}
