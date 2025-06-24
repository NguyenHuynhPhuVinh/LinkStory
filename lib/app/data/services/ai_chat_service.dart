import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import 'package:get/get.dart';
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';

import '../models/story_model.dart';
import '../models/chapter_model.dart';
import 'ai_settings_service.dart';
import 'library_service.dart';
import 'chapter_service.dart';

class AiChatService {
  static const String _conversationsBoxName = 'chat_conversations';
  static const String _messagesBoxName = 'chat_messages';

  Box<ChatConversation>? _conversationsBox;
  Box<ChatMessage>? _messagesBox;
  GenerativeModel? _model;

  // AI Settings Service
  AiSettingsService? _aiSettingsService;

  // Story Services
  LibraryService? _libraryService;
  ChapterService? _chapterService;

  // Singleton pattern
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;
  AiChatService._internal();

  // Initialize service
  Future<void> init() async {
    try {
      // Initialize Firebase if not already done
      if (Firebase.apps.isEmpty) {
        throw Exception('Firebase chưa được khởi tạo');
      }

      // Get AI Settings Service from GetX
      try {
        _aiSettingsService = Get.find<AiSettingsService>();
      } catch (e) {
        // If not found, create and initialize a new instance
        _aiSettingsService = AiSettingsService();
        await _aiSettingsService!.init();
      }

      // Initialize story services
      _libraryService = LibraryService();
      await _libraryService!.init();

      _chapterService = ChapterService();
      await _chapterService!.init();

      // Initialize Hive boxes
      _conversationsBox = await Hive.openBox<ChatConversation>(
        _conversationsBoxName,
      );
      _messagesBox = await Hive.openBox<ChatMessage>(_messagesBoxName);

      // Initialize Firebase AI model with settings
      await _initializeAiModel();

      print('✅ AI Chat Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing AI Chat Service: $e');
      rethrow;
    }
  }

  // Initialize AI model with current settings
  Future<void> _initializeAiModel() async {
    final settings = _aiSettingsService!.getCurrentSettings();

    _model = FirebaseAI.googleAI().generativeModel(
      model: settings.modelName,
      generationConfig: GenerationConfig(
        temperature: settings.temperature,
        topP: settings.topP,
        topK: settings.topK,
        maxOutputTokens: settings.maxOutputTokens,
      ),
      safetySettings: _buildSafetySettings(settings.safetySettings),
      systemInstruction: Content.text(settings.systemPrompt),
      tools: [
        Tool.functionDeclarations(_getFunctionDeclarations()),
      ],
    );
  }

  // Build safety settings from string list
  List<SafetySetting> _buildSafetySettings(List<String> safetySettings) {
    final List<SafetySetting> settings = [];

    // Map safety setting strings to actual SafetySetting objects
    final categories = [
      HarmCategory.harassment,
      HarmCategory.hateSpeech,
      HarmCategory.sexuallyExplicit,
      HarmCategory.dangerousContent,
    ];

    for (int i = 0; i < categories.length && i < safetySettings.length; i++) {
      final threshold = _parseHarmBlockThreshold(safetySettings[i]);
      settings.add(SafetySetting(categories[i], threshold, null));
    }

    return settings;
  }

  // Parse harm block threshold from string
  HarmBlockThreshold _parseHarmBlockThreshold(String threshold) {
    switch (threshold) {
      case 'BLOCK_NONE':
        return HarmBlockThreshold.none;
      case 'BLOCK_LOW_AND_ABOVE':
        return HarmBlockThreshold.low;
      case 'BLOCK_MEDIUM_AND_ABOVE':
        return HarmBlockThreshold.medium;
      case 'BLOCK_HIGH_AND_ABOVE':
        return HarmBlockThreshold.high;
      default:
        return HarmBlockThreshold.medium;
    }
  }

  // Update AI model when settings change
  Future<void> updateAiModel() async {
    await _initializeAiModel();
    print('✅ AI model updated with new settings');
  }

  // Get AI Settings Service instance
  AiSettingsService get aiSettingsService => _aiSettingsService!;

  // Get function declarations for AI model
  List<FunctionDeclaration> _getFunctionDeclarations() {
    return [
      // Lấy danh sách truyện
      FunctionDeclaration(
        'getStoryList',
        'Lấy danh sách tất cả truyện trong thư viện của người dùng',
        parameters: {
          'limit': Schema.integer(
            description: 'Số lượng truyện tối đa muốn lấy (mặc định: 20)',
          ),
          'sortBy': Schema.string(
            description: 'Sắp xếp theo: "title" (tên), "author" (tác giả), "updatedAt" (cập nhật), "rating" (đánh giá), "readChapters" (chương đã đọc)',
          ),
          'filterBy': Schema.string(
            description: 'Lọc theo: "all" (tất cả), "favorites" (yêu thích), "reading" (đang đọc), "completed" (hoàn thành)',
          ),
        },
      ),

      // Lấy thông tin chi tiết truyện
      FunctionDeclaration(
        'getStoryDetails',
        'Lấy thông tin chi tiết của một truyện cụ thể',
        parameters: {
          'storyId': Schema.string(
            description: 'ID của truyện cần lấy thông tin chi tiết',
          ),
        },
      ),

      // Tìm kiếm truyện
      FunctionDeclaration(
        'searchStories',
        'Tìm kiếm truyện theo từ khóa trong tên, tác giả, mô tả hoặc thể loại',
        parameters: {
          'query': Schema.string(
            description: 'Từ khóa tìm kiếm',
          ),
          'searchIn': Schema.string(
            description: 'Tìm kiếm trong: "all" (tất cả), "title" (tên), "author" (tác giả), "description" (mô tả), "genres" (thể loại)',
          ),
        },
      ),

      // Lấy danh sách chương của truyện
      FunctionDeclaration(
        'getChapterList',
        'Lấy danh sách chương của một truyện cụ thể',
        parameters: {
          'storyId': Schema.string(
            description: 'ID của truyện cần lấy danh sách chương',
          ),
          'limit': Schema.integer(
            description: 'Số lượng chương tối đa muốn lấy (mặc định: 50)',
          ),
        },
      ),

      // Lấy nội dung chương
      FunctionDeclaration(
        'getChapterContent',
        'Lấy nội dung chi tiết của một chương cụ thể',
        parameters: {
          'chapterId': Schema.string(
            description: 'ID của chương cần lấy nội dung',
          ),
        },
      ),
    ];
  }

  // Xử lý function calls
  Future<Map<String, dynamic>> _handleFunctionCall(FunctionCall functionCall) async {
    print('🔧 Handling function call: ${functionCall.name} with args: ${functionCall.args}');

    try {
      Map<String, dynamic> result;
      switch (functionCall.name) {
        case 'getStoryList':
          result = await _getStoryList(functionCall.args);
          break;
        case 'getStoryDetails':
          result = await _getStoryDetails(functionCall.args);
          break;
        case 'searchStories':
          result = await _searchStories(functionCall.args);
          break;
        case 'getChapterList':
          result = await _getChapterList(functionCall.args);
          break;
        case 'getChapterContent':
          result = await _getChapterContent(functionCall.args);
          break;
        default:
          result = {'success': false, 'error': 'Hàm không được hỗ trợ: ${functionCall.name}'};
      }

      print('🔧 Function call result: $result');
      return result;
    } catch (e) {
      print('❌ Error in function call ${functionCall.name}: $e');
      return {'success': false, 'error': 'Lỗi khi thực thi hàm ${functionCall.name}: $e'};
    }
  }

  // Lấy danh sách truyện
  Future<Map<String, dynamic>> _getStoryList(Map<String, dynamic> args) async {
    try {
      final int limit = args['limit'] ?? 20;
      final String sortBy = args['sortBy'] ?? 'updatedAt';
      final String filterBy = args['filterBy'] ?? 'all';

      List<Story> stories = _libraryService!.getAllStories();

      // Lọc truyện
      switch (filterBy) {
        case 'favorites':
          stories = stories.where((s) => s.isFavorite).toList();
          break;
        case 'reading':
          stories = stories.where((s) => s.readChapters > 0 && s.readChapters < s.totalChapters).toList();
          break;
        case 'completed':
          stories = stories.where((s) => s.readChapters >= s.totalChapters && s.totalChapters > 0).toList();
          break;
        case 'all':
        default:
          // Không lọc
          break;
      }

      // Sắp xếp truyện
      switch (sortBy) {
        case 'title':
          stories.sort((a, b) => (a.translatedTitle ?? a.title).compareTo(b.translatedTitle ?? b.title));
          break;
        case 'author':
          stories.sort((a, b) => (a.translatedAuthor ?? a.author).compareTo(b.translatedAuthor ?? b.author));
          break;
        case 'rating':
          stories.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'readChapters':
          stories.sort((a, b) => b.readChapters.compareTo(a.readChapters));
          break;
        case 'updatedAt':
        default:
          stories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
      }

      // Giới hạn số lượng
      if (stories.length > limit) {
        stories = stories.take(limit).toList();
      }

      // Chuyển đổi sang format đơn giản cho AI
      final storyList = stories.map((story) => {
        'id': story.id,
        'title': story.translatedTitle ?? story.title,
        'originalTitle': story.title,
        'author': story.translatedAuthor ?? story.author,
        'originalAuthor': story.author,
        'description': story.translatedDescription ?? story.description,
        'genres': story.translatedGenres ?? story.genres,
        'status': story.status,
        'totalChapters': story.totalChapters,
        'readChapters': story.readChapters,
        'rating': story.rating,
        'isFavorite': story.isFavorite,
        'lastReadAt': story.lastReadAt?.toIso8601String(),
        'updatedAt': story.updatedAt.toIso8601String(),
        'isTranslated': story.isTranslated,
      }).toList();

      return {
        'success': true,
        'data': {
          'stories': storyList,
          'total': storyList.length,
          'filter': filterBy,
          'sortBy': sortBy,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi khi lấy danh sách truyện: $e'
      };
    }
  }

  // Lấy thông tin chi tiết truyện
  Future<Map<String, dynamic>> _getStoryDetails(Map<String, dynamic> args) async {
    try {
      final String storyId = args['storyId'];
      final Story? story = _libraryService!.getStoryById(storyId);

      if (story == null) {
        return {
          'success': false,
          'error': 'Không tìm thấy truyện với ID: $storyId'
        };
      }

      // Lấy thống kê chương
      final chapters = _chapterService!.getChaptersByStoryId(storyId);
      final readChapters = chapters.where((c) => c.isRead).length;
      final totalWords = chapters.fold<int>(0, (sum, c) => sum + c.wordCount);

      return {
        'success': true,
        'data': {
          'id': story.id,
          'title': story.translatedTitle ?? story.title,
          'originalTitle': story.title,
          'author': story.translatedAuthor ?? story.author,
          'originalAuthor': story.author,
          'description': story.translatedDescription ?? story.description,
          'originalDescription': story.description,
          'genres': story.translatedGenres ?? story.genres,
          'originalGenres': story.genres,
          'status': story.status,
          'totalChapters': story.totalChapters,
          'readChapters': readChapters,
          'rating': story.rating,
          'isFavorite': story.isFavorite,
          'translator': story.translator,
          'originalLanguage': story.originalLanguage,
          'sourceWebsite': story.sourceWebsite,
          'sourceUrl': story.sourceUrl,
          'coverImageUrl': story.coverImageUrl,
          'createdAt': story.createdAt.toIso8601String(),
          'updatedAt': story.updatedAt.toIso8601String(),
          'lastReadAt': story.lastReadAt?.toIso8601String(),
          'isTranslated': story.isTranslated,
          'translatedAt': story.translatedAt?.toIso8601String(),
          'statistics': {
            'chaptersInDatabase': chapters.length,
            'readChapters': readChapters,
            'totalWords': totalWords,
            'averageWordsPerChapter': chapters.isNotEmpty ? (totalWords / chapters.length).round() : 0,
          },
          'metadata': story.metadata,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi khi lấy thông tin truyện: $e'
      };
    }
  }

  // Tìm kiếm truyện
  Future<Map<String, dynamic>> _searchStories(Map<String, dynamic> args) async {
    try {
      final String query = args['query'].toString().toLowerCase();
      final String searchIn = args['searchIn'] ?? 'all';

      if (query.isEmpty) {
        return {
          'success': false,
          'error': 'Từ khóa tìm kiếm không được để trống'
        };
      }

      final List<Story> allStories = _libraryService!.getAllStories();
      final List<Story> matchedStories = [];

      for (final story in allStories) {
        bool matches = false;

        switch (searchIn) {
          case 'title':
            matches = (story.translatedTitle ?? story.title).toLowerCase().contains(query) ||
                     story.title.toLowerCase().contains(query);
            break;
          case 'author':
            matches = (story.translatedAuthor ?? story.author).toLowerCase().contains(query) ||
                     story.author.toLowerCase().contains(query);
            break;
          case 'description':
            matches = (story.translatedDescription ?? story.description).toLowerCase().contains(query) ||
                     story.description.toLowerCase().contains(query);
            break;
          case 'genres':
            final allGenres = [...(story.translatedGenres ?? []), ...story.genres];
            matches = allGenres.any((genre) => genre.toLowerCase().contains(query));
            break;
          case 'all':
          default:
            matches = (story.translatedTitle ?? story.title).toLowerCase().contains(query) ||
                     story.title.toLowerCase().contains(query) ||
                     (story.translatedAuthor ?? story.author).toLowerCase().contains(query) ||
                     story.author.toLowerCase().contains(query) ||
                     (story.translatedDescription ?? story.description).toLowerCase().contains(query) ||
                     story.description.toLowerCase().contains(query) ||
                     [...(story.translatedGenres ?? []), ...story.genres].any((genre) => genre.toLowerCase().contains(query));
            break;
        }

        if (matches) {
          matchedStories.add(story);
        }
      }

      // Sắp xếp theo độ liên quan (có thể cải thiện thuật toán sau)
      matchedStories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final searchResults = matchedStories.map((story) => {
        'id': story.id,
        'title': story.translatedTitle ?? story.title,
        'originalTitle': story.title,
        'author': story.translatedAuthor ?? story.author,
        'originalAuthor': story.author,
        'description': story.translatedDescription ?? story.description,
        'genres': story.translatedGenres ?? story.genres,
        'status': story.status,
        'totalChapters': story.totalChapters,
        'readChapters': story.readChapters,
        'rating': story.rating,
        'isFavorite': story.isFavorite,
        'isTranslated': story.isTranslated,
      }).toList();

      return {
        'success': true,
        'data': {
          'results': searchResults,
          'total': searchResults.length,
          'query': query,
          'searchIn': searchIn,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi khi tìm kiếm truyện: $e'
      };
    }
  }

  // Lấy danh sách chương
  Future<Map<String, dynamic>> _getChapterList(Map<String, dynamic> args) async {
    try {
      final String storyId = args['storyId'];
      final int limit = args['limit'] ?? 50;

      final Story? story = _libraryService!.getStoryById(storyId);
      if (story == null) {
        return {
          'success': false,
          'error': 'Không tìm thấy truyện với ID: $storyId'
        };
      }

      List<Chapter> chapters = _chapterService!.getChaptersByStoryId(storyId);

      // Giới hạn số lượng
      if (chapters.length > limit) {
        chapters = chapters.take(limit).toList();
      }

      final chapterList = chapters.map((chapter) => {
        'id': chapter.id,
        'title': chapter.translatedTitle ?? chapter.title,
        'originalTitle': chapter.title,
        'chapterNumber': chapter.chapterNumber,
        'volumeNumber': chapter.volumeNumber,
        'volumeTitle': chapter.volumeTitle,
        'url': chapter.url,
        'publishedAt': chapter.publishedAt.toIso8601String(),
        'isRead': chapter.isRead,
        'wordCount': chapter.wordCount,
        'hasImages': chapter.hasImages,
        'hasContent': chapter.content.isNotEmpty,
        'isTranslated': chapter.isTranslated,
        'translatedAt': chapter.translatedAt?.toIso8601String(),
      }).toList();

      return {
        'success': true,
        'data': {
          'storyId': storyId,
          'storyTitle': story.translatedTitle ?? story.title,
          'chapters': chapterList,
          'total': chapterList.length,
          'totalInDatabase': chapters.length,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi khi lấy danh sách chương: $e'
      };
    }
  }

  // Lấy nội dung chương
  Future<Map<String, dynamic>> _getChapterContent(Map<String, dynamic> args) async {
    try {
      final String chapterId = args['chapterId'];
      final Chapter? chapter = _chapterService!.getChapterById(chapterId);

      if (chapter == null) {
        return {
          'success': false,
          'error': 'Không tìm thấy chương với ID: $chapterId'
        };
      }

      final Story? story = _libraryService!.getStoryById(chapter.storyId);

      return {
        'success': true,
        'data': {
          'id': chapter.id,
          'storyId': chapter.storyId,
          'storyTitle': story?.translatedTitle ?? story?.title ?? 'Không rõ',
          'title': chapter.translatedTitle ?? chapter.title,
          'originalTitle': chapter.title,
          'chapterNumber': chapter.chapterNumber,
          'volumeNumber': chapter.volumeNumber,
          'volumeTitle': chapter.volumeTitle,
          'content': chapter.translatedContent ?? chapter.content,
          'originalContent': chapter.content,
          'url': chapter.url,
          'publishedAt': chapter.publishedAt.toIso8601String(),
          'isRead': chapter.isRead,
          'wordCount': chapter.wordCount,
          'hasImages': chapter.hasImages,
          'isTranslated': chapter.isTranslated,
          'translatedAt': chapter.translatedAt?.toIso8601String(),
          'metadata': chapter.metadata,
        }
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi khi lấy nội dung chương: $e'
      };
    }
  }

  // Tạo conversation mới
  Future<ChatConversation> createConversation({
    String? title,
    String? systemPrompt,
    Map<String, dynamic> metadata = const {},
  }) async {
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();

    // Use system prompt from settings if not provided
    final settings = _aiSettingsService!.getCurrentSettings();
    final effectiveSystemPrompt = systemPrompt ?? settings.systemPrompt;

    final conversation = ChatConversation.create(
      id: conversationId,
      title: title,
      systemPrompt: effectiveSystemPrompt,
      metadata: metadata,
    );

    await _conversationsBox?.put(conversationId, conversation);
    return conversation;
  }

  // Lấy tất cả conversations
  List<ChatConversation> getAllConversations() {
    final conversations = _conversationsBox?.values.toList() ?? [];
    conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return conversations;
  }

  // Lấy conversation theo ID
  ChatConversation? getConversation(String conversationId) {
    return _conversationsBox?.get(conversationId);
  }

  // Lấy messages của một conversation
  List<ChatMessage> getConversationMessages(String conversationId) {
    final conversation = getConversation(conversationId);
    if (conversation == null) return [];

    final messages = <ChatMessage>[];
    for (final messageId in conversation.messageIds) {
      final message = _messagesBox?.get(messageId);
      if (message != null) {
        messages.add(message);
      }
    }

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }

  // Gửi message và nhận response
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    Map<String, dynamic> metadata = const {},
  }) async {
    if (_model == null) {
      throw Exception('AI model chưa được khởi tạo');
    }

    final conversation = getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Không tìm thấy conversation');
    }

    // Tạo user message
    final userMessageId =
        '${conversationId}_${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = ChatMessage.user(
      id: userMessageId,
      conversationId: conversationId,
      content: content,
      metadata: metadata,
    );

    // Lưu user message
    await _messagesBox?.put(userMessageId, userMessage);

    // Cập nhật conversation
    final updatedConversation = conversation.copyWith(
      messageIds: List<String>.from(conversation.messageIds)..add(userMessageId),
      messageCount: conversation.messageCount + 1,
      updatedAt: DateTime.now(),
    );

    if (updatedConversation.title == 'Cuộc trò chuyện mới' && content.isNotEmpty) {
      updatedConversation.title = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
    }

    updatedConversation.lastMessagePreview = content.length > 100
        ? '${content.substring(0, 100)}...'
        : content;

    await _conversationsBox?.put(conversationId, updatedConversation);

    try {
      // Lấy lịch sử chat để tạo context
      final chatHistory = _buildChatHistory(conversationId);

      // Tạo chat session
      final chat = _model!.startChat(history: chatHistory);

      // Gửi message và nhận response
      var response = await chat.sendMessage(Content.text(content));

      // Xử lý function calls nếu có
      final functionCalls = response.functionCalls.toList();
      if (functionCalls.isNotEmpty) {
        // Xử lý từng function call
        for (final functionCall in functionCalls) {
          final functionResult = await _handleFunctionCall(functionCall);

          // Gửi kết quả function call trở lại model
          response = await chat.sendMessage(
            Content.functionResponse(functionCall.name, functionResult),
          );
        }
      }

      final responseText = response.text ?? '';

      // Tạo AI response message
      final settings = _aiSettingsService!.getCurrentSettings();
      final aiMessageId =
          '${conversationId}_${DateTime.now().millisecondsSinceEpoch + 1}';
      final aiMessage = ChatMessage.assistant(
        id: aiMessageId,
        conversationId: conversationId,
        content: responseText,
        isMarkdown: settings.enableMarkdown,
        status: ChatMessageStatus.sent,
      );

      // Lưu AI message
      await _messagesBox?.put(aiMessageId, aiMessage);

      // Cập nhật conversation với AI message
      final finalConversation = updatedConversation.copyWith(
        messageIds: List<String>.from(updatedConversation.messageIds)..add(aiMessageId),
        messageCount: updatedConversation.messageCount + 1,
        updatedAt: DateTime.now(),
        lastMessagePreview: responseText.length > 100
            ? '${responseText.substring(0, 100)}...'
            : responseText,
      );

      await _conversationsBox?.put(conversationId, finalConversation);

      return aiMessage;
    } catch (e) {
      // Tạo error message
      final errorMessageId =
          '${conversationId}_${DateTime.now().millisecondsSinceEpoch + 1}';
      final errorMessage = ChatMessage.assistant(
        id: errorMessageId,
        conversationId: conversationId,
        content: 'Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu của bạn.',
        status: ChatMessageStatus.failed,
        metadata: {'error': e.toString()},
      );

      await _messagesBox?.put(errorMessageId, errorMessage);
      conversation.addMessageId(errorMessageId);

      throw Exception('Lỗi khi gửi message: $e');
    }
  }

  // Stream message response
  Stream<String> sendMessageStream({
    required String conversationId,
    required String content,
    Map<String, dynamic> metadata = const {},
  }) async* {
    if (_model == null) {
      throw Exception('AI model chưa được khởi tạo');
    }

    final conversation = getConversation(conversationId);
    if (conversation == null) {
      throw Exception('Không tìm thấy conversation');
    }

    // Tạo user message
    final userMessageId =
        '${conversationId}_${DateTime.now().millisecondsSinceEpoch}';
    final userMessage = ChatMessage.user(
      id: userMessageId,
      conversationId: conversationId,
      content: content,
      metadata: metadata,
    );

    // Lưu user message
    await _messagesBox?.put(userMessageId, userMessage);

    // Cập nhật conversation với user message
    final updatedConversation = conversation.copyWith(
      messageIds: List<String>.from(conversation.messageIds)..add(userMessageId),
      messageCount: conversation.messageCount + 1,
      updatedAt: DateTime.now(),
    );

    if (updatedConversation.title == 'Cuộc trò chuyện mới' && content.isNotEmpty) {
      updatedConversation.title = content.length > 50
          ? '${content.substring(0, 50)}...'
          : content;
    }

    await _conversationsBox?.put(conversationId, updatedConversation);

    try {
      // Lấy lịch sử chat để tạo context
      final chatHistory = _buildChatHistory(conversationId);

      // Tạo chat session
      final chat = _model!.startChat(history: chatHistory);

      // Gửi message đầu tiên để kiểm tra function calls
      var response = await chat.sendMessage(Content.text(content));

      // Xử lý function calls nếu có
      final functionCalls = response.functionCalls.toList();
      if (functionCalls.isNotEmpty) {
        print('🔧 Found ${functionCalls.length} function calls');

        // Thông báo đang xử lý function calls
        yield '🔍 Đang tìm kiếm thông tin...\n\n';

        // Xử lý từng function call
        for (final functionCall in functionCalls) {
          print('🔧 Processing function call: ${functionCall.name}');
          final functionResult = await _handleFunctionCall(functionCall);

          // Gửi kết quả function call trở lại model
          response = await chat.sendMessage(
            Content.functionResponse(functionCall.name, functionResult),
          );

          print('🔧 Response after function call: ${response.text}');
        }

        // Sau khi xử lý tất cả function calls, lấy response cuối cùng
        final finalResponseText = response.text ?? '';
        print('🔧 Final response text: "$finalResponseText"');

        if (finalResponseText.isNotEmpty) {
          yield finalResponseText;
        } else {
          // Nếu không có response text, có thể AI cần thêm function calls
          final additionalFunctionCalls = response.functionCalls.toList();
          if (additionalFunctionCalls.isNotEmpty) {
            print('🔧 Found additional function calls, processing...');
            // Xử lý thêm function calls nếu có
            for (final functionCall in additionalFunctionCalls) {
              final functionResult = await _handleFunctionCall(functionCall);
              response = await chat.sendMessage(
                Content.functionResponse(functionCall.name, functionResult),
              );
            }
            final additionalResponseText = response.text ?? '';
            if (additionalResponseText.isNotEmpty) {
              yield additionalResponseText;
            } else {
              yield 'Đã tìm kiếm thông tin thành công. Vui lòng hỏi tôi về thông tin bạn cần biết.';
            }
          } else {
            yield 'Đã tìm kiếm thông tin thành công. Vui lòng hỏi tôi về thông tin bạn cần biết.';
          }
        }

        // Lưu complete AI message
        final settings = _aiSettingsService!.getCurrentSettings();
        final aiMessageId =
            '${conversationId}_${DateTime.now().millisecondsSinceEpoch + 1}';
        final actualResponseText = response.text ?? 'Đã tìm kiếm thông tin thành công. Vui lòng hỏi tôi về thông tin bạn cần biết.';
        final fullContent = '🔍 Đang tìm kiếm thông tin...\n\n' + actualResponseText;
        final aiMessage = ChatMessage.assistant(
          id: aiMessageId,
          conversationId: conversationId,
          content: fullContent,
          isMarkdown: settings.enableMarkdown,
          status: ChatMessageStatus.sent,
        );

        await _messagesBox?.put(aiMessageId, aiMessage);

        // Cập nhật conversation với AI message
        final finalConversation = updatedConversation.copyWith(
          messageIds: List<String>.from(updatedConversation.messageIds)..add(aiMessageId),
          messageCount: updatedConversation.messageCount + 1,
          updatedAt: DateTime.now(),
          lastMessagePreview: actualResponseText.length > 100
              ? '${actualResponseText.substring(0, 100)}...'
              : actualResponseText,
        );

        await _conversationsBox?.put(conversationId, finalConversation);
      } else {
        // Không có function calls, stream response bình thường
        final responseStream = chat.sendMessageStream(Content.text(content));

        String fullResponse = '';
        final aiMessageId =
            '${conversationId}_${DateTime.now().millisecondsSinceEpoch + 1}';

        await for (final chunk in responseStream) {
          final chunkText = chunk.text ?? '';
          fullResponse += chunkText;
          yield chunkText;
        }

        // Lưu complete AI message
        final settings = _aiSettingsService!.getCurrentSettings();
        final aiMessage = ChatMessage.assistant(
          id: aiMessageId,
          conversationId: conversationId,
          content: fullResponse,
          isMarkdown: settings.enableMarkdown,
          status: ChatMessageStatus.sent,
        );

        await _messagesBox?.put(aiMessageId, aiMessage);

        // Cập nhật conversation với AI message
        final finalConversation = updatedConversation.copyWith(
          messageIds: List<String>.from(updatedConversation.messageIds)..add(aiMessageId),
          messageCount: updatedConversation.messageCount + 1,
          updatedAt: DateTime.now(),
          lastMessagePreview: fullResponse.length > 100
              ? '${fullResponse.substring(0, 100)}...'
              : fullResponse,
        );

        await _conversationsBox?.put(conversationId, finalConversation);
      }
    } catch (e) {
      yield 'Xin lỗi, đã có lỗi xảy ra khi xử lý yêu cầu của bạn.';
      throw Exception('Lỗi khi stream message: $e');
    }
  }

  // Xây dựng chat history cho context
  List<Content> _buildChatHistory(String conversationId) {
    final messages = getConversationMessages(conversationId);
    final history = <Content>[];

    for (final message in messages) {
      if (message.role == ChatMessageRole.user) {
        history.add(Content.text(message.content));
      } else if (message.role == ChatMessageRole.assistant &&
          message.status == ChatMessageStatus.sent) {
        history.add(Content.model([TextPart(message.content)]));
      }
    }

    return history;
  }

  // Xóa conversation
  Future<void> deleteConversation(String conversationId) async {
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      // Xóa tất cả messages
      for (final messageId in conversation.messageIds) {
        await _messagesBox?.delete(messageId);
      }

      // Xóa conversation
      await _conversationsBox?.delete(conversationId);
    }
  }

  // Xóa message
  Future<void> deleteMessage(String messageId) async {
    final message = _messagesBox?.get(messageId);
    if (message != null) {
      final conversation = getConversation(message.conversationId);
      if (conversation != null) {
        conversation.removeMessageId(messageId);
      }
      await _messagesBox?.delete(messageId);
    }
  }

  // Cập nhật conversation
  Future<void> updateConversation(ChatConversation conversation) async {
    await _conversationsBox?.put(conversation.id, conversation);
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _conversationsBox?.clear();
    await _messagesBox?.clear();
  }

  // Close service
  Future<void> close() async {
    await _conversationsBox?.close();
    await _messagesBox?.close();
    // Don't close _aiSettingsService as it might be shared with other services
  }
}
