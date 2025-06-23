import 'package:hive/hive.dart';

part 'story_model.g.dart';

@HiveType(typeId: 1)
class Story extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String author;

  @HiveField(3)
  String description;

  @HiveField(4)
  String coverImageUrl;

  @HiveField(5)
  String sourceUrl;

  @HiveField(6)
  String sourceWebsite;

  @HiveField(7)
  List<String> genres;

  @HiveField(8)
  String status; // Đang tiến hành, Hoàn thành, Tạm dừng

  @HiveField(9)
  int totalChapters;

  @HiveField(10)
  int readChapters;

  @HiveField(11)
  DateTime createdAt;

  @HiveField(12)
  DateTime updatedAt;

  @HiveField(13)
  DateTime? lastReadAt;

  @HiveField(14)
  bool isFavorite;

  @HiveField(15)
  double rating; // 0.0 - 5.0

  @HiveField(16)
  String translator; // Người dịch

  @HiveField(17)
  String originalLanguage; // Ngôn ngữ gốc

  @HiveField(18)
  Map<String, dynamic> metadata; // Thông tin bổ sung

  Story({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.coverImageUrl,
    required this.sourceUrl,
    required this.sourceWebsite,
    this.genres = const [],
    this.status = 'Đang tiến hành',
    this.totalChapters = 0,
    this.readChapters = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastReadAt,
    this.isFavorite = false,
    this.rating = 0.0,
    this.translator = '',
    this.originalLanguage = '',
    this.metadata = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method
  Story copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverImageUrl,
    String? sourceUrl,
    String? sourceWebsite,
    List<String>? genres,
    String? status,
    int? totalChapters,
    int? readChapters,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastReadAt,
    bool? isFavorite,
    double? rating,
    String? translator,
    String? originalLanguage,
    Map<String, dynamic>? metadata,
  }) {
    return Story(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      sourceWebsite: sourceWebsite ?? this.sourceWebsite,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      totalChapters: totalChapters ?? this.totalChapters,
      readChapters: readChapters ?? this.readChapters,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      translator: translator ?? this.translator,
      originalLanguage: originalLanguage ?? this.originalLanguage,
      metadata: metadata ?? this.metadata,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'sourceUrl': sourceUrl,
      'sourceWebsite': sourceWebsite,
      'genres': genres,
      'status': status,
      'totalChapters': totalChapters,
      'readChapters': readChapters,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastReadAt': lastReadAt?.toIso8601String(),
      'isFavorite': isFavorite,
      'rating': rating,
      'translator': translator,
      'originalLanguage': originalLanguage,
      'metadata': metadata,
    };
  }

  // From JSON
  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      description: json['description'],
      coverImageUrl: json['coverImageUrl'],
      sourceUrl: json['sourceUrl'],
      sourceWebsite: json['sourceWebsite'],
      genres: List<String>.from(json['genres'] ?? []),
      status: json['status'] ?? 'Đang tiến hành',
      totalChapters: json['totalChapters'] ?? 0,
      readChapters: json['readChapters'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      lastReadAt: json['lastReadAt'] != null ? DateTime.parse(json['lastReadAt']) : null,
      isFavorite: json['isFavorite'] ?? false,
      rating: (json['rating'] ?? 0.0).toDouble(),
      translator: json['translator'] ?? '',
      originalLanguage: json['originalLanguage'] ?? '',
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  @override
  String toString() {
    return 'Story(id: $id, title: $title, author: $author, sourceWebsite: $sourceWebsite)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Story && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper methods
  double get readingProgress {
    if (totalChapters == 0) return 0.0;
    return readChapters / totalChapters;
  }

  bool get isCompleted => readChapters >= totalChapters && totalChapters > 0;

  String get readingProgressText {
    if (totalChapters == 0) return 'Chưa có chương';
    return '$readChapters/$totalChapters chương';
  }
}
