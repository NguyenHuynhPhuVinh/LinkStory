import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../controllers/ai_controller.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/chat_conversation_model.dart';

class AiView extends GetView<AiController> {
  const AiView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Conversation selector (nếu có nhiều conversations)
          _buildConversationSelector(),
          
          // Messages area
          Expanded(
            child: Obx(() {
              // Nếu chưa có conversation nào trong lịch sử, hiện welcome view
              if (controller.conversations.isEmpty) {
                return _buildWelcomeView();
              }

              // Nếu có conversations nhưng chưa chọn conversation nào, hiện conversation list
              if (controller.currentConversation.value == null) {
                return _buildConversationListView();
              }

              // Nếu đã chọn conversation nhưng chưa có messages, hiện empty conversation
              if (controller.messages.isEmpty && !controller.isStreaming.value) {
                return _buildEmptyConversationView();
              }

              // Hiện messages
              return _buildMessagesView();
            }),
          ),
          
          // Error message
          _buildErrorMessage(),
          
          // Input area
          _buildInputArea(),
        ],
      ),

    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() => Text(
        controller.currentConversation.value?.title ?? 'AI Trợ lý'
      )),
      centerTitle: true,
      actions: [
        // History button
        IconButton(
          onPressed: () async {
            await Get.toNamed('/ai/history');
            // Reload conversations when returning from history
            controller.loadConversations();
          },
          icon: const Icon(Iconsax.clock),
          tooltip: 'Lịch sử trò chuyện',
        ),
        // Menu button
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            if (controller.currentConversation.value != null) ...[
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Iconsax.edit),
                    SizedBox(width: 8),
                    Text('Đổi tên cuộc trò chuyện'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Iconsax.trash, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa cuộc trò chuyện', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem(
              value: 'new',
              child: Row(
                children: [
                  Icon(Iconsax.add),
                  SizedBox(width: 8),
                  Text('Cuộc trò chuyện mới'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear_all',
              child: Row(
                children: [
                  Icon(Iconsax.trash, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConversationSelector() {
    return Obx(() {
      if (controller.conversations.length <= 1) {
        return const SizedBox.shrink();
      }
      
      return Container(
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(Get.context!).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final conversation = controller.conversations[index];
            final isSelected = controller.currentConversation.value?.id == conversation.id;
            
            return Container(
              margin: EdgeInsets.only(right: 8.w),
              child: GFButton(
                onPressed: () => controller.selectConversation(conversation.id),
                text: conversation.title,
                type: isSelected ? GFButtonType.solid : GFButtonType.outline,
                shape: GFButtonShape.pills,
                size: GFSize.SMALL,
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildWelcomeView() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40.h),
            Icon(
              Iconsax.cpu,
              size: 64.sp,
              color: Theme.of(Get.context!).colorScheme.primary,
            ),
            SizedBox(height: 20.h),
            Text(
              'AI Trợ lý thông minh',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(Get.context!).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Hỏi tôi bất cứ điều gì về truyện, sách, hoặc bất kỳ chủ đề nào bạn quan tâm',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            GFButton(
              onPressed: () => controller.createNewConversation(),
              text: 'Bắt đầu trò chuyện',
              icon: Icon(Iconsax.message_add, size: 16.sp),
              type: GFButtonType.solid,
              shape: GFButtonShape.pills,
              size: GFSize.LARGE,
              fullWidthButton: true,
            ),
            SizedBox(height: 16.h),
            // Suggestions
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: [
                _buildSuggestionChip('Giới thiệu về truyện hay'),
                _buildSuggestionChip('Phân tích nhân vật'),
                _buildSuggestionChip('Tóm tắt nội dung'),
                _buildSuggestionChip('Gợi ý đọc tiếp'),
              ],
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GFButton(
      onPressed: () {
        controller.createNewConversation();
        // Delay để đảm bảo conversation được tạo
        Future.delayed(const Duration(milliseconds: 100), () {
          controller.messageController.text = text;
          controller.sendMessage();
        });
      },
      text: text,
      type: GFButtonType.outline,
      shape: GFButtonShape.pills,
      size: GFSize.SMALL,
    );
  }

  Widget _buildConversationListView() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),

            // Header
            Row(
              children: [
                Icon(
                  Iconsax.message,
                  size: 24.sp,
                  color: Theme.of(Get.context!).colorScheme.primary,
                ),
                SizedBox(width: 12.w),
                Text(
                  'Cuộc trò chuyện gần đây',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // New conversation button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.createNewConversation(),
                icon: Icon(Iconsax.message_add, size: 18.sp),
                label: const Text('Tạo cuộc trò chuyện mới'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // Conversations list
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.conversations.length,
              itemBuilder: (context, index) {
                final conversation = controller.conversations[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(Get.context!).colorScheme.primary,
                      child: Icon(
                        Iconsax.message,
                        color: Theme.of(Get.context!).colorScheme.onPrimary,
                        size: 18.sp,
                      ),
                    ),
                    title: Text(
                      conversation.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: conversation.lastMessagePreview != null
                        ? Text(
                            conversation.lastMessagePreview!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            '${conversation.messageCount} tin nhắn • ${_formatDate(conversation.updatedAt)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                            ),
                          ),
                    trailing: Icon(
                      Iconsax.arrow_right_3,
                      size: 16.sp,
                      color: Colors.grey,
                    ),
                    onTap: () => controller.selectConversation(conversation.id),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyConversationView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.message,
              size: 48.sp,
              color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.3),
            ),
            SizedBox(height: 12.h),
            Text(
              'Bắt đầu cuộc trò chuyện',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'Nhập tin nhắn bên dưới để bắt đầu',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesView() {
    return LiquidPullToRefresh(
      onRefresh: () async {
        if (controller.currentConversation.value != null) {
          controller.loadMessages(controller.currentConversation.value!.id);
        }
      },
      color: Theme.of(Get.context!).colorScheme.primary,
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      child: ListView.builder(
        controller: controller.scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: _getMessageCount(),
        itemBuilder: (context, index) {
          if (index < controller.messages.length) {
            return _buildMessageCard(controller.messages[index]);
          } else {
            // Streaming message
            return _buildStreamingMessage();
          }
        },
      ),
    );
  }

  int _getMessageCount() {
    int count = controller.messages.length;
    if (controller.isStreaming.value && controller.streamingMessage.value.isNotEmpty) {
      count += 1;
    }
    return count;
  }

  Widget _buildMessageCard(ChatMessage message) {
    final isUser = message.role == ChatMessageRole.user;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            GFAvatar(
              backgroundColor: Theme.of(Get.context!).colorScheme.primary,
              radius: 20.r,
              child: Icon(
                Iconsax.cpu,
                color: Theme.of(Get.context!).colorScheme.onPrimary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 12.w),
          ],
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(message),
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                color: isUser
                    ? Theme.of(Get.context!).colorScheme.primary
                    : Theme.of(Get.context!).colorScheme.surfaceVariant,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isMarkdown && !isUser)
                        MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                              fontSize: 14.sp,
                            ),
                            h1: TextStyle(
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: TextStyle(
                              color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            code: TextStyle(
                              backgroundColor: Theme.of(Get.context!).colorScheme.surface,
                              fontSize: 12.sp,
                            ),
                          ),
                        )
                      else
                        Text(
                          message.content,
                          style: TextStyle(
                            color: isUser
                                ? Theme.of(Get.context!).colorScheme.onPrimary
                                : Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            fontSize: 14.sp,
                          ),
                        ),
                      
                      SizedBox(height: 8.h),
                      
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              color: (isUser
                                      ? Theme.of(Get.context!).colorScheme.onPrimary
                                      : Theme.of(Get.context!).colorScheme.onSurfaceVariant)
                                  .withOpacity(0.7),
                              fontSize: 10.sp,
                            ),
                          ),
                          if (message.status == ChatMessageStatus.failed) ...[
                            SizedBox(width: 4.w),
                            Icon(
                              Iconsax.warning_2,
                              size: 12.sp,
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          if (isUser) ...[
            SizedBox(width: 12.w),
            GFAvatar(
              backgroundColor: Theme.of(Get.context!).colorScheme.secondary,
              radius: 20.r,
              child: Icon(
                Iconsax.user,
                color: Theme.of(Get.context!).colorScheme.onSecondary,
                size: 18.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStreamingMessage() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GFAvatar(
            backgroundColor: Theme.of(Get.context!).colorScheme.primary,
            radius: 20.r,
            child: Icon(
              Iconsax.cpu,
              color: Theme.of(Get.context!).colorScheme.onPrimary,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 12.w),

          Flexible(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              color: Theme.of(Get.context!).colorScheme.surfaceVariant,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() {
                      if (controller.streamingMessage.value.isEmpty) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(Get.context!).colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'AI đang suy nghĩ...',
                              style: TextStyle(
                                color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                                fontSize: 14.sp,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      }

                      return MarkdownBody(
                        data: controller.streamingMessage.value,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            fontSize: 14.sp,
                          ),
                          h1: TextStyle(
                            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          h2: TextStyle(
                            color: Theme.of(Get.context!).colorScheme.onSurfaceVariant,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          code: TextStyle(
                            backgroundColor: Theme.of(Get.context!).colorScheme.surface,
                            fontSize: 12.sp,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(12.w),
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.warning_2,
              color: Theme.of(Get.context!).colorScheme.onErrorContainer,
              size: 16.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  color: Theme.of(Get.context!).colorScheme.onErrorContainer,
                  fontSize: 14.sp,
                ),
              ),
            ),
            IconButton(
              onPressed: controller.clearError,
              icon: Icon(
                Iconsax.close_circle,
                color: Theme.of(Get.context!).colorScheme.onErrorContainer,
                size: 16.sp,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(Get.context!).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller.messageController,
                maxLines: null,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  filled: true,
                  fillColor: Theme.of(Get.context!).colorScheme.surface,
                ),
                onSubmitted: (_) => controller.sendMessage(),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(() => FloatingActionButton(
              mini: true,
              onPressed: controller.isStreaming.value
                  ? null
                  : controller.sendMessage,
              child: controller.isStreaming.value
                  ? SizedBox(
                      width: 16.w,
                      height: 16.h,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Iconsax.send_1),
            )),
          ],
        ),
      ),
    );
  }



  // Helper methods
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}p';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new':
        controller.createNewConversation();
        break;
      case 'rename':
        _showRenameDialog();
        break;
      case 'delete':
        _confirmDeleteConversation();
        break;
      case 'clear_all':
        _confirmClearAll();
        break;
    }
  }

  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: Get.context!,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.copy),
              title: const Text('Sao chép'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                Get.snackbar(
                  'Đã sao chép',
                  'Nội dung tin nhắn đã được sao chép',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            if (message.role == ChatMessageRole.user)
              ListTile(
                leading: const Icon(Iconsax.trash, color: Colors.red),
                title: const Text('Xóa tin nhắn', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  controller.deleteMessage(message.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() {
    final textController = TextEditingController(
      text: controller.currentConversation.value?.title,
    );

    Get.dialog(
      AlertDialog(
        title: const Text('Đổi tên cuộc trò chuyện'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Nhập tên mới...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final newTitle = textController.text.trim();
              if (newTitle.isNotEmpty && controller.currentConversation.value != null) {
                final updatedConversation = controller.currentConversation.value!.copyWith(
                  title: newTitle,
                  updatedAt: DateTime.now(),
                );
                controller.currentConversation.value = updatedConversation;
                controller.aiChatService.updateConversation(updatedConversation);
                controller.loadConversations();
              }
              Get.back();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversation() {
    if (controller.currentConversation.value == null) return;

    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện "${controller.currentConversation.value!.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteConversation(controller.currentConversation.value!.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa tất cả'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả cuộc trò chuyện?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.aiChatService.clearAllData();
              controller.loadConversations();
              Get.snackbar(
                'Thành công',
                'Đã xóa tất cả cuộc trò chuyện',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}
