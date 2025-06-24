import 'package:hive/hive.dart';
import 'chat_message_model.dart';

part 'chat_conversation_model.g.dart';

@HiveType(typeId: 13)
class ChatConversation extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime updatedAt;

  @HiveField(4)
  List<String> messageIds;

  @HiveField(5)
  Map<String, dynamic> metadata;

  @HiveField(6)
  String? systemPrompt;

  @HiveField(7)
  bool isPinned;

  @HiveField(8)
  String? lastMessagePreview;

  @HiveField(9)
  int messageCount;

  @HiveField(10)
  ConversationStatus status;

  ChatConversation({
    required this.id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.messageIds = const [],
    this.metadata = const {},
    this.systemPrompt,
    this.isPinned = false,
    this.lastMessagePreview,
    this.messageCount = 0,
    this.status = ConversationStatus.active,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor để tạo conversation mới
  factory ChatConversation.create({
    required String id,
    String? title,
    String? systemPrompt,
    Map<String, dynamic> metadata = const {},
  }) {
    return ChatConversation(
      id: id,
      title: title ?? 'Cuộc trò chuyện mới',
      systemPrompt: systemPrompt,
      metadata: metadata,
    );
  }

  // Copy with method
  ChatConversation copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? messageIds,
    Map<String, dynamic>? metadata,
    String? systemPrompt,
    bool? isPinned,
    String? lastMessagePreview,
    int? messageCount,
    ConversationStatus? status,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageIds: messageIds ?? this.messageIds,
      metadata: metadata ?? this.metadata,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isPinned: isPinned ?? this.isPinned,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      messageCount: messageCount ?? this.messageCount,
      status: status ?? this.status,
    );
  }

  // Thêm message ID vào conversation
  void addMessageId(String messageId) {
    if (!messageIds.contains(messageId)) {
      messageIds = List<String>.from(messageIds)..add(messageId);
      messageCount = messageIds.length;
      updatedAt = DateTime.now();
      save();
    }
  }

  // Xóa message ID khỏi conversation
  void removeMessageId(String messageId) {
    final newList = List<String>.from(messageIds);
    if (newList.remove(messageId)) {
      messageIds = newList;
      messageCount = messageIds.length;
      updatedAt = DateTime.now();
      save();
    }
  }

  // Cập nhật preview của message cuối
  void updateLastMessagePreview(String preview) {
    lastMessagePreview = preview.length > 100 
        ? '${preview.substring(0, 100)}...' 
        : preview;
    updatedAt = DateTime.now();
    save();
  }

  // Cập nhật title từ message đầu tiên
  void updateTitleFromFirstMessage(String firstMessage) {
    if (title == 'Cuộc trò chuyện mới' && firstMessage.isNotEmpty) {
      title = firstMessage.length > 50 
          ? '${firstMessage.substring(0, 50)}...' 
          : firstMessage;
      updatedAt = DateTime.now();
      save();
    }
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messageIds': messageIds,
      'metadata': metadata,
      'systemPrompt': systemPrompt,
      'isPinned': isPinned,
      'lastMessagePreview': lastMessagePreview,
      'messageCount': messageCount,
      'status': status.name,
    };
  }

  // Create from JSON
  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messageIds: List<String>.from(json['messageIds'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      systemPrompt: json['systemPrompt'],
      isPinned: json['isPinned'] ?? false,
      lastMessagePreview: json['lastMessagePreview'],
      messageCount: json['messageCount'] ?? 0,
      status: ConversationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConversationStatus.active,
      ),
    );
  }

  @override
  String toString() {
    return 'ChatConversation(id: $id, title: $title, messageCount: $messageCount)';
  }
}

@HiveType(typeId: 14)
enum ConversationStatus {
  @HiveField(0)
  active,
  @HiveField(1)
  archived,
  @HiveField(2)
  deleted,
}
