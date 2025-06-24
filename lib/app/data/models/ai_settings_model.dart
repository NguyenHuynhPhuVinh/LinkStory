import 'package:hive/hive.dart';

part 'ai_settings_model.g.dart';

@HiveType(typeId: 15)
class AiSettings extends HiveObject {
  @HiveField(0)
  String modelName;

  @HiveField(1)
  String systemPrompt;

  @HiveField(2)
  double temperature;

  @HiveField(3)
  double topP;

  @HiveField(4)
  int topK;

  @HiveField(5)
  int maxOutputTokens;

  @HiveField(6)
  List<String> safetySettings;

  @HiveField(7)
  bool enableStreaming;

  @HiveField(8)
  bool enableMarkdown;

  @HiveField(9)
  String language;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  AiSettings({
    required this.modelName,
    required this.systemPrompt,
    required this.temperature,
    required this.topP,
    required this.topK,
    required this.maxOutputTokens,
    required this.safetySettings,
    required this.enableStreaming,
    required this.enableMarkdown,
    required this.language,
    required this.createdAt,
    required this.updatedAt,
  });

  // Default settings
  factory AiSettings.defaultSettings() {
    return AiSettings(
      modelName: 'gemini-2.0-flash-exp',
      systemPrompt: _getDefaultSystemPrompt(),
      temperature: 0.7,
      topP: 0.9,
      topK: 40,
      maxOutputTokens: 8192,
      safetySettings: [
        'BLOCK_MEDIUM_AND_ABOVE', // Harassment
        'BLOCK_MEDIUM_AND_ABOVE', // Hate Speech
        'BLOCK_MEDIUM_AND_ABOVE', // Sexually Explicit
        'BLOCK_MEDIUM_AND_ABOVE', // Dangerous Content
      ],
      enableStreaming: true,
      enableMarkdown: true,
      language: 'vi',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static String _getDefaultSystemPrompt() {
    return '''Bạn là một AI trợ lý thông minh và hữu ích, chuyên về văn học và truyện tranh. Bạn có những đặc điểm sau:

🎯 **Chuyên môn:**
- Hiểu biết sâu về văn học Việt Nam và thế giới
- Am hiểu truyện tranh, manga, manhwa, manhua
- Phân tích nhân vật, cốt truyện, chủ đề
- Gợi ý sách và truyện phù hợp

💬 **Phong cách giao tiếp:**
- Thân thiện, nhiệt tình và dễ hiểu
- Sử dụng tiếng Việt tự nhiên
- Giải thích rõ ràng, có ví dụ cụ thể
- Tôn trọng sở thích cá nhân của người dùng

📚 **Hỗ trợ:**
- Tóm tắt nội dung truyện/sách
- Phân tích nhân vật và cốt truyện
- Gợi ý đọc tiếp dựa trên sở thích
- Giải đáp thắc mắc về văn học
- Thảo luận về chủ đề, ý nghĩa tác phẩm

🎨 **Định dạng trả lời:**
- Sử dụng markdown để format đẹp
- Chia nhỏ thông tin dễ đọc
- Dùng emoji phù hợp
- Tạo danh sách có thứ tự khi cần

Hãy luôn nhiệt tình hỗ trợ và tạo ra những cuộc trò chuyện thú vị về thế giới văn học!''';
  }

  // Copy with method
  AiSettings copyWith({
    String? modelName,
    String? systemPrompt,
    double? temperature,
    double? topP,
    int? topK,
    int? maxOutputTokens,
    List<String>? safetySettings,
    bool? enableStreaming,
    bool? enableMarkdown,
    String? language,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiSettings(
      modelName: modelName ?? this.modelName,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      safetySettings: safetySettings ?? List<String>.from(this.safetySettings),
      enableStreaming: enableStreaming ?? this.enableStreaming,
      enableMarkdown: enableMarkdown ?? this.enableMarkdown,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'modelName': modelName,
      'systemPrompt': systemPrompt,
      'temperature': temperature,
      'topP': topP,
      'topK': topK,
      'maxOutputTokens': maxOutputTokens,
      'safetySettings': safetySettings,
      'enableStreaming': enableStreaming,
      'enableMarkdown': enableMarkdown,
      'language': language,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // From JSON
  factory AiSettings.fromJson(Map<String, dynamic> json) {
    return AiSettings(
      modelName: json['modelName'] ?? 'gemini-2.0-flash-exp',
      systemPrompt: json['systemPrompt'] ?? _getDefaultSystemPrompt(),
      temperature: (json['temperature'] ?? 0.7).toDouble(),
      topP: (json['topP'] ?? 0.9).toDouble(),
      topK: json['topK'] ?? 40,
      maxOutputTokens: json['maxOutputTokens'] ?? 8192,
      safetySettings: List<String>.from(json['safetySettings'] ?? [
        'BLOCK_MEDIUM_AND_ABOVE',
        'BLOCK_MEDIUM_AND_ABOVE',
        'BLOCK_MEDIUM_AND_ABOVE',
        'BLOCK_MEDIUM_AND_ABOVE',
      ]),
      enableStreaming: json['enableStreaming'] ?? true,
      enableMarkdown: json['enableMarkdown'] ?? true,
      language: json['language'] ?? 'vi',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'AiSettings(modelName: $modelName, temperature: $temperature, topP: $topP, topK: $topK, maxOutputTokens: $maxOutputTokens)';
  }
}

// Available AI models
class AiModels {
  static const List<Map<String, String>> availableModels = [
    {
      'id': 'gemini-2.0-flash-exp',
      'name': 'Gemini 2.0 Flash (Experimental)',
      'description': 'Mô hình mới nhất, nhanh và thông minh',
    },
    {
      'id': 'gemini-1.5-pro',
      'name': 'Gemini 1.5 Pro',
      'description': 'Mô hình chuyên nghiệp, phù hợp cho tác vụ phức tạp',
    },
    {
      'id': 'gemini-1.5-flash',
      'name': 'Gemini 1.5 Flash',
      'description': 'Mô hình nhanh, phù hợp cho tác vụ đơn giản',
    },
  ];

  static String getModelName(String id) {
    final model = availableModels.firstWhere(
      (model) => model['id'] == id,
      orElse: () => availableModels.first,
    );
    return model['name'] ?? id;
  }

  static String getModelDescription(String id) {
    final model = availableModels.firstWhere(
      (model) => model['id'] == id,
      orElse: () => availableModels.first,
    );
    return model['description'] ?? '';
  }
}

// Safety settings options
class SafetySettings {
  static const List<Map<String, String>> options = [
    {
      'id': 'BLOCK_NONE',
      'name': 'Không chặn',
      'description': 'Cho phép tất cả nội dung',
    },
    {
      'id': 'BLOCK_ONLY_HIGH',
      'name': 'Chặn mức cao',
      'description': 'Chỉ chặn nội dung có độ nguy hiểm cao',
    },
    {
      'id': 'BLOCK_MEDIUM_AND_ABOVE',
      'name': 'Chặn mức trung bình trở lên',
      'description': 'Chặn nội dung có độ nguy hiểm từ trung bình trở lên',
    },
    {
      'id': 'BLOCK_LOW_AND_ABOVE',
      'name': 'Chặn mức thấp trở lên',
      'description': 'Chặn hầu hết nội dung có thể gây hại',
    },
  ];

  static String getName(String id) {
    final option = options.firstWhere(
      (option) => option['id'] == id,
      orElse: () => options[2], // Default to BLOCK_MEDIUM_AND_ABOVE
    );
    return option['name'] ?? id;
  }

  static String getDescription(String id) {
    final option = options.firstWhere(
      (option) => option['id'] == id,
      orElse: () => options[2],
    );
    return option['description'] ?? '';
  }
}

// Safety categories
class SafetyCategories {
  static const List<Map<String, String>> categories = [
    {
      'id': 'harassment',
      'name': 'Quấy rối',
      'description': 'Nội dung quấy rối, bắt nạt',
    },
    {
      'id': 'hate_speech',
      'name': 'Ngôn từ thù địch',
      'description': 'Nội dung kích động thù địch',
    },
    {
      'id': 'sexually_explicit',
      'name': 'Nội dung tình dục',
      'description': 'Nội dung khiêu dâm, tình dục',
    },
    {
      'id': 'dangerous_content',
      'name': 'Nội dung nguy hiểm',
      'description': 'Nội dung có thể gây tổn hại',
    },
  ];
}
