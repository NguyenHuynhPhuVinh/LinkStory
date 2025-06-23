import 'package:hive/hive.dart';

part 'website_model.g.dart';

@HiveType(typeId: 0)
class Website extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String url;

  @HiveField(3)
  String iconUrl;

  @HiveField(4)
  String description;

  @HiveField(5)
  bool isActive;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  Website({
    required this.id,
    required this.name,
    required this.url,
    required this.iconUrl,
    this.description = '',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copy with method
  Website copyWith({
    String? id,
    String? name,
    String? url,
    String? iconUrl,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Website(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      iconUrl: iconUrl ?? this.iconUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'iconUrl': iconUrl,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // From JSON
  factory Website.fromJson(Map<String, dynamic> json) {
    return Website(
      id: json['id'],
      name: json['name'],
      url: json['url'],
      iconUrl: json['iconUrl'],
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  @override
  String toString() {
    return 'Website(id: $id, name: $name, url: $url, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Website && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
