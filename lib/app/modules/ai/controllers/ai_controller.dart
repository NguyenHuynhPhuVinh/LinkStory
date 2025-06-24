import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/services/ai_chat_service.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/chat_conversation_model.dart';

class AiController extends GetxController {
  // Services
  late final AiChatService _aiChatService;

  // Getter để truy cập service từ view
  AiChatService get aiChatService => _aiChatService;

  // Observable variables
  final conversations = <ChatConversation>[].obs;
  final currentConversation = Rxn<ChatConversation>();
  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final isStreaming = false.obs;
  final streamingMessage = ''.obs;
  final errorMessage = ''.obs;

  // Text controllers
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  // Stream subscription
  StreamSubscription<String>? _streamSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  @override
  void onReady() {
    super.onReady();
    loadConversations();
  }

  @override
  void onClose() {
    messageController.dispose();
    scrollController.dispose();
    _streamSubscription?.cancel();
    super.onClose();
  }

  // Initialize AI Chat Service
  Future<void> _initializeService() async {
    try {
      _aiChatService = AiChatService();
      await _aiChatService.init();
      print('✅ AI Chat Service initialized in controller');
    } catch (e) {
      print('❌ Error initializing AI Chat Service: $e');
      errorMessage.value = 'Không thể khởi tạo dịch vụ AI Chat: $e';
    }
  }

  // Load all conversations
  void loadConversations() {
    try {
      conversations.value = _aiChatService.getAllConversations();
      print('✅ Loaded ${conversations.length} conversations');
    } catch (e) {
      print('❌ Error loading conversations: $e');
      errorMessage.value = 'Không thể tải danh sách cuộc trò chuyện: $e';
    }
  }

  // Create new conversation
  Future<void> createNewConversation({
    String? title,
    String? systemPrompt,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final conversation = await _aiChatService.createConversation(
        title: title ?? 'Cuộc trò chuyện mới',
        systemPrompt: systemPrompt,
      );

      conversations.insert(0, conversation);
      selectConversation(conversation.id);

      print('✅ Created new conversation: ${conversation.id}');
    } catch (e) {
      print('❌ Error creating conversation: $e');
      errorMessage.value = 'Không thể tạo cuộc trò chuyện mới: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Select conversation
  void selectConversation(String conversationId) {
    try {
      final conversation = _aiChatService.getConversation(conversationId);
      if (conversation != null) {
        currentConversation.value = conversation;
        loadMessages(conversationId);
        print('✅ Selected conversation: $conversationId');
      }
    } catch (e) {
      print('❌ Error selecting conversation: $e');
      errorMessage.value = 'Không thể chọn cuộc trò chuyện: $e';
    }
  }

  // Load messages for current conversation
  void loadMessages(String conversationId) {
    try {
      messages.value = _aiChatService.getConversationMessages(conversationId);
      _scrollToBottom();
      print('✅ Loaded ${messages.length} messages for conversation: $conversationId');
    } catch (e) {
      print('❌ Error loading messages: $e');
      errorMessage.value = 'Không thể tải tin nhắn: $e';
    }
  }

  // Send message
  Future<void> sendMessage() async {
    final content = messageController.text.trim();
    if (content.isEmpty || currentConversation.value == null) return;

    try {
      isStreaming.value = true;
      streamingMessage.value = '';
      errorMessage.value = '';

      // Clear input
      messageController.clear();

      // Add user message to UI immediately
      final userMessage = ChatMessage.user(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: currentConversation.value!.id,
        content: content,
      );
      messages.add(userMessage);
      _scrollToBottom();

      // Stream AI response
      _streamSubscription = _aiChatService.sendMessageStream(
        conversationId: currentConversation.value!.id,
        content: content,
      ).listen(
        (chunk) {
          streamingMessage.value += chunk;
        },
        onDone: () {
          // Reload messages to get the complete conversation
          loadMessages(currentConversation.value!.id);
          loadConversations(); // Update conversation list
          streamingMessage.value = '';
          isStreaming.value = false;
        },
        onError: (error) {
          print('❌ Error streaming message: $error');
          errorMessage.value = 'Lỗi khi gửi tin nhắn: $error';
          streamingMessage.value = '';
          isStreaming.value = false;
        },
      );

    } catch (e) {
      print('❌ Error sending message: $e');
      errorMessage.value = 'Không thể gửi tin nhắn: $e';
      isStreaming.value = false;
      streamingMessage.value = '';
    }
  }

  // Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _aiChatService.deleteConversation(conversationId);
      conversations.removeWhere((c) => c.id == conversationId);

      if (currentConversation.value?.id == conversationId) {
        currentConversation.value = null;
        messages.clear();
      }

      Get.snackbar(
        'Thành công',
        'Đã xóa cuộc trò chuyện',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ Deleted conversation: $conversationId');
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      errorMessage.value = 'Không thể xóa cuộc trò chuyện: $e';
    }
  }

  // Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _aiChatService.deleteMessage(messageId);
      messages.removeWhere((m) => m.id == messageId);

      Get.snackbar(
        'Thành công',
        'Đã xóa tin nhắn',
        snackPosition: SnackPosition.BOTTOM,
      );

      print('✅ Deleted message: $messageId');
    } catch (e) {
      print('❌ Error deleting message: $e');
      errorMessage.value = 'Không thể xóa tin nhắn: $e';
    }
  }

  // Copy message content
  void copyMessage(String content) {
    // TODO: Implement clipboard copy
    Get.snackbar(
      'Đã sao chép',
      'Nội dung tin nhắn đã được sao chép',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Scroll to bottom
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Refresh conversations
  Future<void> refreshConversations() async {
    loadConversations();
  }

  // Clear error message
  void clearError() {
    errorMessage.value = '';
  }
}
