import 'package:hive/hive.dart';

part 'chapter_model.g.dart';

@HiveType(typeId: 2)
class Chapter extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String storyId; // ID của truyện chứa chương này

  @HiveField(2)
  String title;

  @HiveField(3)
  String url;

  @HiveField(4)
  String content;

  @HiveField(5)
  int chapterNumber;

  @HiveField(6)
  String volumeTitle; // Tên tập (VD: "Tập 01")

  @HiveField(7)
  int volumeNumber;

  @HiveField(8)
  DateTime publishedAt;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  DateTime updatedAt;

  @HiveField(11)
  bool isRead;

  @HiveField(12)
  int wordCount;

  @HiveField(13)
  bool hasImages; // Có chứa ảnh minh họa không

  @HiveField(14)
  Map<String, dynamic> metadata; // Thông tin bổ sung

  Chapter({
    required this.id,
    required this.storyId,
    required this.title,
    required this.url,
    this.content = '',
    this.chapterNumber = 0,
    this.volumeTitle = '',
    this.volumeNumber = 0,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isRead = false,
    this.wordCount = 0,
    this.hasImages = false,
    this.metadata = const {},
  })  : publishedAt = publishedAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method
  Chapter copyWith({
    String? id,
    String? storyId,
    String? title,
    String? url,
    String? content,
    int? chapterNumber,
    String? volumeTitle,
    int? volumeNumber,
    DateTime? publishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    int? wordCount,
    bool? hasImages,
    Map<String, dynamic>? metadata,
  }) {
    return Chapter(
      id: id ?? this.id,
      storyId: storyId ?? this.storyId,
      title: title ?? this.title,
      url: url ?? this.url,
      content: content ?? this.content,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      volumeTitle: volumeTitle ?? this.volumeTitle,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      publishedAt: publishedAt ?? this.publishedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      wordCount: wordCount ?? this.wordCount,
      hasImages: hasImages ?? this.hasImages,
      metadata: metadata ?? this.metadata,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'storyId': storyId,
      'title': title,
      'url': url,
      'content': content,
      'chapterNumber': chapterNumber,
      'volumeTitle': volumeTitle,
      'volumeNumber': volumeNumber,
      'publishedAt': publishedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isRead': isRead,
      'wordCount': wordCount,
      'hasImages': hasImages,
      'metadata': metadata,
    };
  }

  // From JSON
  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['id'],
      storyId: json['storyId'],
      title: json['title'],
      url: json['url'],
      content: json['content'] ?? '',
      chapterNumber: json['chapterNumber'] ?? 0,
      volumeTitle: json['volumeTitle'] ?? '',
      volumeNumber: json['volumeNumber'] ?? 0,
      publishedAt: DateTime.parse(json['publishedAt']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isRead: json['isRead'] ?? false,
      wordCount: json['wordCount'] ?? 0,
      hasImages: json['hasImages'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'Chapter(id: $id, title: $title, chapterNumber: $chapterNumber, volumeTitle: $volumeTitle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chapter && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  String get displayTitle {
    if (volumeTitle.isNotEmpty && title.isNotEmpty) {
      return '$volumeTitle - $title';
    } else if (title.isNotEmpty) {
      return title;
    } else {
      return 'Chương $chapterNumber';
    }
  }

  String get shortTitle {
    if (title.length > 50) {
      return '${title.substring(0, 47)}...';
    }
    return title;
  }

  bool get hasContent => content.isNotEmpty;

  String get readingTimeEstimate {
    if (wordCount == 0) return 'Chưa xác định';
    final minutes = (wordCount / 200).ceil(); // Giả sử đọc 200 từ/phút
    if (minutes < 1) return '< 1 phút';
    return '$minutes phút';
  }
}
