import 'package:hive/hive.dart';

part 'chat_message_model.g.dart';

@HiveType(typeId: 10)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String conversationId;

  @HiveField(2)
  String content;

  @HiveField(3)
  ChatMessageRole role;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  ChatMessageStatus status;

  @HiveField(6)
  Map<String, dynamic> metadata;

  @HiveField(7)
  bool isMarkdown;

  @HiveField(8)
  List<String> attachments;

  @HiveField(9)
  String? errorMessage;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.status = ChatMessageStatus.sent,
    this.metadata = const {},
    this.isMarkdown = false,
    this.attachments = const [],
    this.errorMessage,
  }) : timestamp = timestamp ?? DateTime.now();

  // Factory constructor để tạo user message
  factory ChatMessage.user({
    required String id,
    required String conversationId,
    required String content,
    Map<String, dynamic> metadata = const {},
    List<String> attachments = const [],
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      role: ChatMessageRole.user,
      metadata: metadata,
      attachments: attachments,
    );
  }

  // Factory constructor để tạo AI message
  factory ChatMessage.assistant({
    required String id,
    required String conversationId,
    required String content,
    bool isMarkdown = true,
    Map<String, dynamic> metadata = const {},
    ChatMessageStatus status = ChatMessageStatus.sent,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      role: ChatMessageRole.assistant,
      isMarkdown: isMarkdown,
      metadata: metadata,
      status: status,
    );
  }

  // Factory constructor để tạo system message
  factory ChatMessage.system({
    required String id,
    required String conversationId,
    required String content,
    Map<String, dynamic> metadata = const {},
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      content: content,
      role: ChatMessageRole.system,
      metadata: metadata,
    );
  }

  // Copy with method
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? content,
    ChatMessageRole? role,
    DateTime? timestamp,
    ChatMessageStatus? status,
    Map<String, dynamic>? metadata,
    bool? isMarkdown,
    List<String>? attachments,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      isMarkdown: isMarkdown ?? this.isMarkdown,
      attachments: attachments ?? this.attachments,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'metadata': metadata,
      'isMarkdown': isMarkdown,
      'attachments': attachments,
      'errorMessage': errorMessage,
    };
  }

  // Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      conversationId: json['conversationId'],
      content: json['content'],
      role: ChatMessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => ChatMessageRole.user,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      status: ChatMessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ChatMessageStatus.sent,
      ),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isMarkdown: json['isMarkdown'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
      errorMessage: json['errorMessage'],
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, role: $role, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content})';
  }
}

@HiveType(typeId: 11)
enum ChatMessageRole {
  @HiveField(0)
  user,
  @HiveField(1)
  assistant,
  @HiveField(2)
  system,
}

@HiveType(typeId: 12)
enum ChatMessageStatus {
  @HiveField(0)
  sending,
  @HiveField(1)
  sent,
  @HiveField(2)
  delivered,
  @HiveField(3)
  failed,
  @HiveField(4)
  streaming,
}
