import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getwidget/getwidget.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../controllers/library_controller.dart';
import '../../../data/models/story_model.dart';
import '../../../modules/home/controllers/home_controller.dart';

class LibraryView extends GetView<LibraryController> {
  const LibraryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingView();
              }

              if (controller.stories.isEmpty) {
                return _buildEmptyView();
              }

              if (controller.filteredStories.isEmpty) {
                return _buildNoResultsView();
              }

              return _buildStoryList();
            }),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() => Text(
        controller.stories.isEmpty
          ? 'Thư viện'
          : 'Thư viện (${controller.filteredStories.length})'
      )),
      centerTitle: true,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.more),
          onSelected: (value) {
            switch (value) {
              case 'sort':
                _showSortDialog();
                break;
              case 'stats':
                _showStatsDialog();
                break;
              case 'refresh':
                controller.refreshLibrary();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'sort',
              child: Row(
                children: [
                  Icon(Iconsax.sort),
                  SizedBox(width: 8),
                  Text('Sắp xếp'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Iconsax.chart),
                  SizedBox(width: 8),
                  Text('Thống kê'),
                ],
              ),
            ),
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
            onChanged: controller.searchStories,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm truyện...',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: controller.clearSearch,
                  )
                : const SizedBox.shrink()),
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
                _buildFilterChip('all', 'Tất cả', Iconsax.book),
                SizedBox(width: 8.w),
                _buildFilterChip('favorites', 'Yêu thích', Iconsax.heart),
                SizedBox(width: 8.w),
                _buildFilterChip('reading', 'Đang đọc', Iconsax.book_1),
                SizedBox(width: 8.w),
                _buildFilterChip('completed', 'Hoàn thành', Iconsax.tick_circle),
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
          color: isSelected ? Colors.white : Theme.of(Get.context!).colorScheme.primary,
        ),
        type: isSelected ? GFButtonType.solid : GFButtonType.outline,
        color: Theme.of(Get.context!).colorScheme.primary,
        size: GFSize.SMALL,
        shape: GFButtonShape.pills,
      );
    });
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải thư viện...'),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.book,
            size: 64.sp,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'Thư viện trống',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Hãy thêm truyện từ trang Reader',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 24.h),
          GFButton(
            onPressed: () {
              // Navigate to reader tab
              Get.find<HomeController>().changeTabIndex(1);
            },
            text: 'Đi đến Reader',
            icon: Icon(Iconsax.book_1, size: 18.sp),
            type: GFButtonType.solid,
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
          Icon(
            Iconsax.search_normal,
            size: 64.sp,
            color: Colors.grey,
          ),
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
          Obx(() => Text(
            'Không có truyện nào phù hợp với "${controller.searchQuery.value}"',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          )),
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

  Widget _buildStoryList() {
    return LiquidPullToRefresh(
      onRefresh: controller.refreshLibrary,
      color: Theme.of(Get.context!).colorScheme.primary,
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: controller.filteredStories.length,
        itemBuilder: (context, index) {
          final story = controller.filteredStories[index];
          return _buildStoryCard(story);
        },
      ),
    );
  }

  Widget _buildStoryCard(Story story) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _showStoryDetails(story),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              _buildCoverImage(story),

              SizedBox(width: 12.w),

              // Story info
              Expanded(
                child: _buildStoryInfo(story),
              ),

              // Action buttons
              _buildActionButtons(story),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(Story story) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        width: 60.w,
        height: 80.h,
        child: story.coverImageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: story.coverImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: Icon(
                  Iconsax.image,
                  color: Colors.grey[600],
                  size: 24.sp,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: Icon(
                  Iconsax.book,
                  color: Colors.grey[600],
                  size: 24.sp,
                ),
              ),
            )
          : Container(
              color: Colors.grey[300],
              child: Icon(
                Iconsax.book,
                color: Colors.grey[600],
                size: 24.sp,
              ),
            ),
      ),
    );
  }

  Widget _buildStoryInfo(Story story) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          story.title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: 4.h),

        // Author
        Text(
          story.author,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        SizedBox(height: 4.h),

        // Source website
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            story.sourceWebsite,
            style: TextStyle(
              fontSize: 10.sp,
              color: Theme.of(Get.context!).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        SizedBox(height: 6.h),

        // Progress and rating
        Row(
          children: [
            // Reading progress
            if (story.totalChapters > 0) ...[
              Icon(
                Iconsax.book_1,
                size: 12.sp,
                color: Colors.grey[600],
              ),
              SizedBox(width: 4.w),
              Text(
                '${story.readChapters}/${story.totalChapters}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 12.w),
            ],

            // Rating
            if (story.rating > 0) ...[
              Icon(
                Iconsax.star1,
                size: 12.sp,
                color: Colors.amber,
              ),
              SizedBox(width: 4.w),
              Text(
                story.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),

        SizedBox(height: 4.h),

        // Status and last read
        Row(
          children: [
            // Status
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: _getStatusColor(story.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: Text(
                story.status,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: _getStatusColor(story.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(width: 8.w),

            // Last read
            if (story.lastReadAt != null) ...[
              Icon(
                Iconsax.clock,
                size: 10.sp,
                color: Colors.grey[500],
              ),
              SizedBox(width: 2.w),
              Text(
                _formatDate(story.lastReadAt!),
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(Story story) {
    return Column(
      children: [
        // Favorite button
        IconButton(
          onPressed: () => controller.toggleFavorite(story),
          icon: Icon(
            story.isFavorite ? Iconsax.heart5 : Iconsax.heart,
            color: story.isFavorite ? Colors.red : Colors.grey,
            size: 20.sp,
          ),
        ),

        // More options
        PopupMenuButton<String>(
          icon: Icon(
            Iconsax.more,
            size: 20.sp,
            color: Colors.grey,
          ),
          onSelected: (value) {
            switch (value) {
              case 'read':
                _openStory(story);
                break;
              case 'details':
                _showStoryDetails(story);
                break;
              case 'remove':
                _confirmRemoveStory(story);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'read',
              child: Row(
                children: [
                  Icon(Iconsax.book_1),
                  SizedBox(width: 8),
                  Text('Đọc truyện'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Iconsax.info_circle),
                  SizedBox(width: 8),
                  Text('Chi tiết'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Row(
                children: [
                  Icon(Iconsax.trash, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xóa', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Hoàn thành':
        return Colors.green;
      case 'Đang tiến hành':
        return Colors.blue;
      case 'Tạm dừng':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Vừa xong';
    }
  }

  // Action methods
  void _openStory(Story story) {
    // Navigate to WebView to read the story
    Get.toNamed('/webview', arguments: {
      'website': {
        'name': story.sourceWebsite,
        'url': story.sourceUrl,
        'icon': '',
        'description': story.title,
      }
    });
  }

  void _showStoryDetails(Story story) {
    Get.bottomSheet(
      Container(
        height: Get.height * 0.8, // Giới hạn chiều cao
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    story.title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Iconsax.close_circle),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story info
                    _buildDetailRow('Tác giả', story.author),
                    _buildDetailRow('Nguồn', story.sourceWebsite),
                    _buildDetailRow('Trạng thái', story.status),
                    if (story.translator.isNotEmpty)
                      _buildDetailRow('Người dịch', story.translator),
                    if (story.genres.isNotEmpty)
                      _buildDetailRow('Thể loại', story.genres.join(', ')),
                    if (story.rating > 0)
                      _buildDetailRow('Đánh giá', '${story.rating}/5.0'),

                    SizedBox(height: 16.h),

                    // Description
                    if (story.description.isNotEmpty) ...[
                      Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        story.description,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons - Fixed at bottom
            Row(
              children: [
                Expanded(
                  child: GFButton(
                    onPressed: () {
                      Get.back();
                      _openStory(story);
                    },
                    text: 'Đọc truyện',
                    icon: Icon(Iconsax.book_1, size: 18.sp),
                    type: GFButtonType.solid,
                    shape: GFButtonShape.pills,
                  ),
                ),
                SizedBox(width: 12.w),
                GFButton(
                  onPressed: () {
                    Get.back();
                    controller.toggleFavorite(story);
                  },
                  text: story.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                  icon: Icon(
                    story.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                    size: 18.sp,
                  ),
                  type: GFButtonType.outline,
                  shape: GFButtonShape.pills,
                  color: story.isFavorite ? Colors.red : Theme.of(Get.context!).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveStory(Story story) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa truyện "${story.title}" khỏi thư viện?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.removeStory(story);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Sắp xếp theo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption('recent', 'Mới nhất', Iconsax.clock),
            _buildSortOption('title', 'Tên truyện', Iconsax.text),
            _buildSortOption('author', 'Tác giả', Iconsax.user),
            _buildSortOption('rating', 'Đánh giá', Iconsax.star),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    return Obx(() => RadioListTile<String>(
      value: value,
      groupValue: controller.selectedSort.value,
      onChanged: (newValue) {
        if (newValue != null) {
          controller.setSort(newValue);
          Get.back();
        }
      },
      title: Row(
        children: [
          Icon(icon, size: 20.sp),
          SizedBox(width: 12.w),
          Text(label),
        ],
      ),
    ));
  }

  void _showStatsDialog() {
    final stats = controller.getLibraryStats();

    Get.dialog(
      AlertDialog(
        title: const Text('Thống kê thư viện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Tổng số truyện', '${stats['total']}'),
            _buildStatRow('Yêu thích', '${stats['favorites']}'),
            _buildStatRow('Đang đọc', '${stats['reading']}'),
            _buildStatRow('Hoàn thành', '${stats['completed']}'),

            if (stats['genres'] != null && (stats['genres'] as Map).isNotEmpty) ...[
              SizedBox(height: 16.h),
              Text(
                'Thể loại phổ biến:',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              ...(stats['genres'] as Map<String, int>)
                  .entries
                  .take(5)
                  .map((entry) => _buildStatRow(entry.key, '${entry.value}')),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
