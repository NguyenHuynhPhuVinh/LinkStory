import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive/hive.dart';
import '../models/chat_message_model.dart';
import '../models/chat_conversation_model.dart';

class AiChatService {
  static const String _conversationsBoxName = 'chat_conversations';
  static const String _messagesBoxName = 'chat_messages';

  Box<ChatConversation>? _conversationsBox;
  Box<ChatMessage>? _messagesBox;
  GenerativeModel? _model;

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

      // Initialize Hive boxes
      _conversationsBox = await Hive.openBox<ChatConversation>(
        _conversationsBoxName,
      );
      _messagesBox = await Hive.openBox<ChatMessage>(_messagesBoxName);

      // Initialize Firebase AI model
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(
            HarmCategory.harassment,
            HarmBlockThreshold.medium,
            null,
          ),
          SafetySetting(
            HarmCategory.hateSpeech,
            HarmBlockThreshold.medium,
            null,
          ),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
            null,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
            null,
          ),
        ],
      );

      print('✅ AI Chat Service initialized successfully');
    } catch (e) {
      print('❌ Error initializing AI Chat Service: $e');
      rethrow;
    }
  }

  // Tạo conversation mới
  Future<ChatConversation> createConversation({
    String? title,
    String? systemPrompt,
    Map<String, dynamic> metadata = const {},
  }) async {
    final conversationId = DateTime.now().millisecondsSinceEpoch.toString();

    final conversation = ChatConversation.create(
      id: conversationId,
      title: title,
      systemPrompt: systemPrompt,
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
      final response = await chat.sendMessage(Content.text(content));
      final responseText = response.text ?? '';

      // Tạo AI response message
      final aiMessageId =
          '${conversationId}_${DateTime.now().millisecondsSinceEpoch + 1}';
      final aiMessage = ChatMessage.assistant(
        id: aiMessageId,
        conversationId: conversationId,
        content: responseText,
        isMarkdown: true,
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

      // Stream response
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
      final aiMessage = ChatMessage.assistant(
        id: aiMessageId,
        conversationId: conversationId,
        content: fullResponse,
        isMarkdown: true,
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
}
