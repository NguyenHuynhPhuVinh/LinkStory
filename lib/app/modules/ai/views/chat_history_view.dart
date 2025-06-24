import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../controllers/ai_controller.dart';
import '../../../data/models/chat_conversation_model.dart';

class ChatHistoryView extends GetView<AiController> {
  const ChatHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search and filter
          _buildSearchAndFilter(),

          // History list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingView();
              }

              if (controller.conversations.isEmpty) {
                return _buildEmptyView();
              }

              if (controller.filteredConversations.isEmpty) {
                return _buildNoResultsView();
              }

              return _buildHistoryList();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.createNewConversation();
          Get.back(); // Quay lại màn hình chat chính
        },
        child: const Icon(Iconsax.message_add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() {
        if (controller.conversations.isEmpty) {
          return const Text('Lịch sử trò chuyện');
        }

        if (controller.searchQuery.value.isNotEmpty ||
            controller.selectedFilter.value != 'all') {
          return Text(
            'Lịch sử (${controller.filteredConversations.length}/${controller.conversations.length})',
          );
        }

        return Text('Lịch sử (${controller.conversations.length})');
      }),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Iconsax.refresh),
                  SizedBox(width: 8),
                  Text('Làm mới'),
                ],
              ),
            ),
            if (controller.conversations.isNotEmpty) ...[
              const PopupMenuDivider(),
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
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: controller.searchController,
            onChanged: controller.searchConversations,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm cuộc trò chuyện...',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: Obx(
                () => controller.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Iconsax.close_circle),
                        onPressed: controller.clearSearch,
                      )
                    : const SizedBox.shrink(),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(Get.context!).colorScheme.surface,
            ),
          ),

          SizedBox(height: 12.h),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả', Iconsax.message),
                SizedBox(width: 8.w),
                _buildFilterChip('recent', 'Gần đây', Iconsax.clock),
                SizedBox(width: 8.w),
                _buildFilterChip('favorites', 'Yêu thích', Iconsax.heart),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == value;
      return GFButton(
        onPressed: () => controller.setFilter(value),
        text: label,
        icon: Icon(
          icon,
          size: 16.sp,
          color: isSelected
              ? Colors.white
              : Theme.of(Get.context!).colorScheme.primary,
        ),
        type: isSelected ? GFButtonType.solid : GFButtonType.outline,
        color: Theme.of(Get.context!).colorScheme.primary,
        size: GFSize.SMALL,
        shape: GFButtonShape.pills,
      );
    });
  }

  Widget _buildLoadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.message, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'Chưa có cuộc trò chuyện nào',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bắt đầu cuộc trò chuyện đầu tiên với AI để xem lịch sử tại đây',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          GFButton(
            onPressed: () {
              controller.createNewConversation();
              Get.back();
            },
            text: 'Tạo cuộc trò chuyện mới',
            type: GFButtonType.outline,
            shape: GFButtonShape.pills,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.search_normal, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            'Không tìm thấy kết quả',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Obx(
            () => Text(
              'Không có cuộc trò chuyện nào phù hợp với "${controller.searchQuery.value}"',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 16.h),
          GFButton(
            onPressed: controller.clearSearch,
            text: 'Xóa bộ lọc',
            type: GFButtonType.outline,
            shape: GFButtonShape.pills,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return LiquidPullToRefresh(
      onRefresh: () async {
        controller.refreshConversations();
      },
      color: Theme.of(Get.context!).colorScheme.primary,
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: controller.filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = controller.filteredConversations[index];
          return _buildHistoryCard(conversation);
        },
      ),
    );
  }

  Widget _buildHistoryCard(ChatConversation conversation) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _continueConversation(conversation),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GFAvatar(
                backgroundColor: Theme.of(Get.context!).colorScheme.primary,
                radius: 24.r,
                child: Icon(
                  Iconsax.message,
                  color: Theme.of(Get.context!).colorScheme.onPrimary,
                  size: 20.sp,
                ),
              ),

              SizedBox(width: 16.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      conversation.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(Get.context!).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (conversation.lastMessagePreview != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        conversation.lastMessagePreview!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(
                            Get.context!,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    SizedBox(height: 8.h),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Iconsax.message,
                          size: 14.sp,
                          color: Theme.of(
                            Get.context!,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${conversation.messageCount} tin nhắn',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(
                              Get.context!,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Icon(
                          Iconsax.clock,
                          size: 14.sp,
                          color: Theme.of(
                            Get.context!,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatDate(conversation.updatedAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(
                              Get.context!,
                            ).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action menu
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleConversationAction(value, conversation),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'continue',
                    child: Row(
                      children: [
                        Icon(Iconsax.play),
                        SizedBox(width: 8),
                        Text('Tiếp tục trò chuyện'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Iconsax.edit),
                        SizedBox(width: 8),
                        Text('Đổi tên'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Xóa', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: Icon(
                  Iconsax.more,
                  size: 20.sp,
                  color: Theme.of(
                    Get.context!,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
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

  void _continueConversation(ChatConversation conversation) {
    controller.selectConversation(conversation.id);
    Get.back(); // Quay lại màn hình chat chính
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        controller.refreshConversations();
        break;
      case 'clear_all':
        _confirmClearAll();
        break;
    }
  }

  void _handleConversationAction(String action, ChatConversation conversation) {
    switch (action) {
      case 'continue':
        _continueConversation(conversation);
        break;
      case 'rename':
        _showRenameDialog(conversation);
        break;
      case 'delete':
        _confirmDelete(conversation);
        break;
    }
  }

  void _showRenameDialog(ChatConversation conversation) {
    final textController = TextEditingController(text: conversation.title);

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
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              final newTitle = textController.text.trim();
              if (newTitle.isNotEmpty) {
                controller.renameConversation(conversation.id, newTitle);
              }
              Get.back();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ChatConversation conversation) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc chắn muốn xóa cuộc trò chuyện "${conversation.title}"?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteConversation(conversation.id);
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
        content: const Text(
          'Bạn có chắc chắn muốn xóa tất cả cuộc trò chuyện?\n\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.clearAllConversations();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
  }
}
