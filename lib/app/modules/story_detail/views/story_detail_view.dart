import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:getwidget/getwidget.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../controllers/story_detail_controller.dart';
import '../../../data/models/chapter_model.dart';

class StoryDetailView extends GetView<StoryDetailController> {
  const StoryDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final story = controller.story.value;
        if (story == null) {
          return const Center(child: Text('Không tìm thấy truyện'));
        }

        return CustomScrollView(
          slivers: [
            _buildSliverAppBar(story),
            SliverToBoxAdapter(
              child: _buildStoryInfo(story),
            ),
            _buildChapterSection(),
            _buildChapterList(),
          ],
        );
      }),
    );
  }

  Widget _buildSliverAppBar(story) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            story.coverImageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: story.coverImageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(
                        Iconsax.book,
                        size: 64.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Icon(
                      Iconsax.book,
                      size: 64.sp,
                      color: Colors.grey[600],
                    ),
                  ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),

            // Story title at bottom
            Positioned(
              bottom: 16.h,
              left: 16.w,
              right: 16.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          story.displayTitle,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (story.isTranslated) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Text(
                            'Đã dịch',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    story.displayAuthor,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Obx(() => IconButton(
          icon: Icon(
            controller.story.value?.isFavorite == true
                ? Iconsax.heart5
                : Iconsax.heart,
            color: controller.story.value?.isFavorite == true
                ? Colors.red
                : Colors.white,
          ),
          onPressed: controller.toggleFavorite,
        )),
        IconButton(
          icon: const Icon(Iconsax.more, color: Colors.white),
          onPressed: () => _showMoreOptions(),
        ),
      ],
    );
  }

  Widget _buildStoryInfo(story) {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons
          Row(
            children: [
              Expanded(
                child: GFButton(
                  onPressed: controller.continueReading,
                  text: 'Tiếp tục đọc',
                  icon: Icon(Iconsax.book_1, size: 18.sp),
                  type: GFButtonType.solid,
                  shape: GFButtonShape.pills,
                  size: GFSize.LARGE,
                ),
              ),
              SizedBox(width: 12.w),
              Obx(() => GFButton(
                onPressed: controller.toggleFavorite,
                text: controller.story.value?.isFavorite == true ? 'Bỏ yêu thích' : 'Yêu thích',
                icon: Icon(
                  controller.story.value?.isFavorite == true ? Iconsax.heart5 : Iconsax.heart,
                  size: 18.sp,
                ),
                type: GFButtonType.outline,
                shape: GFButtonShape.pills,
                color: controller.story.value?.isFavorite == true ? Colors.red : Theme.of(Get.context!).colorScheme.primary,
              )),
            ],
          ),

          SizedBox(height: 20.h),

          // Story details
          _buildDetailRow('Tác giả', story.displayAuthor),
          _buildDetailRow('Nguồn', story.sourceWebsite),
          _buildDetailRow('Trạng thái', story.status),
          if (story.translator.isNotEmpty)
            _buildDetailRow('Người dịch', story.translator),
          if (story.displayGenres.isNotEmpty)
            _buildDetailRow('Thể loại', story.displayGenres.join(', ')),
          if (story.rating > 0)
            _buildDetailRow('Đánh giá', '${story.rating}/5.0'),

          // Reading progress
          Obx(() {
            final stats = controller.getChapterStats();
            return _buildDetailRow(
              'Tiến độ',
              '${stats['read']}/${stats['total']} chương (${(stats['readingProgress'] * 100).toStringAsFixed(1)}%)'
            );
          }),

          SizedBox(height: 16.h),

          // Description
          if (story.displayDescription.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Mô tả:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (story.isTranslated) ...[
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Text(
                      'Đã dịch',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              story.displayDescription,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 20.h),
          ],
        ],
      ),
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

  Widget _buildChapterSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chapter header
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Danh sách chương',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Obx(() => Text(
                  '${controller.filteredChapters.length} chương',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                )),
                IconButton(
                  icon: Icon(
                    controller.showSearch.value ? Iconsax.close_circle : Iconsax.search_normal,
                    size: 20.sp,
                  ),
                  onPressed: controller.toggleSearch,
                ),
              ],
            ),

            // Search bar
            Obx(() => controller.showSearch.value
                ? Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    child: TextField(
                      controller: controller.searchController,
                      onChanged: controller.searchChapters,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm chương...',
                        prefixIcon: const Icon(Iconsax.search_normal),
                        suffixIcon: controller.searchQuery.value.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Iconsax.close_circle),
                                onPressed: controller.clearSearch,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(Get.context!).colorScheme.surface,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'Tất cả', Iconsax.book),
                  SizedBox(width: 8.w),
                  _buildFilterChip('unread', 'Chưa đọc', Iconsax.book_1),
                  SizedBox(width: 8.w),
                  _buildFilterChip('read', 'Đã đọc', Iconsax.tick_circle),
                ],
              ),
            ),

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      if (controller.filteredChapters.isEmpty) {
        return SliverToBoxAdapter(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                controller.searchQuery.value.isNotEmpty
                    ? 'Không tìm thấy chương nào'
                    : 'Chưa có chương nào',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final chapter = controller.filteredChapters[index];
            return _buildChapterItem(chapter);
          },
          childCount: controller.filteredChapters.length,
        ),
      );
    });
  }

  Widget _buildChapterItem(Chapter chapter) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: InkWell(
        onTap: () => controller.openChapter(chapter),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              // Chapter number
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: chapter.isRead
                      ? Colors.green.withOpacity(0.1)
                      : Theme.of(Get.context!).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '${chapter.chapterNumber}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: chapter.isRead
                          ? Colors.green
                          : Theme.of(Get.context!).colorScheme.primary,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 12.w),

              // Chapter info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volume title (if different from previous)
                    if (chapter.volumeTitle.isNotEmpty) ...[
                      Text(
                        chapter.volumeTitle,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],

                    // Chapter title
                    Text(
                      chapter.title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: chapter.isRead ? Colors.grey[600] : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 4.h),

                    // Chapter metadata
                    Row(
                      children: [
                        // Published date
                        Icon(
                          Iconsax.calendar,
                          size: 12.sp,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          _formatDate(chapter.publishedAt),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[500],
                          ),
                        ),

                        SizedBox(width: 12.w),

                        // Word count (if available)
                        if (chapter.wordCount > 0) ...[
                          Icon(
                            Iconsax.document_text,
                            size: 12.sp,
                            color: Colors.grey[500],
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${chapter.wordCount} từ',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],

                        // Has images indicator
                        if (chapter.hasImages) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Iconsax.image,
                            size: 12.sp,
                            color: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Read status and actions
              Column(
                children: [
                  // Read status icon
                  Icon(
                    chapter.isRead ? Iconsax.tick_circle : Iconsax.clock,
                    color: chapter.isRead ? Colors.green : Colors.grey,
                    size: 20.sp,
                  ),

                  SizedBox(height: 8.h),

                  // More options
                  PopupMenuButton<String>(
                    icon: Icon(
                      Iconsax.more,
                      size: 16.sp,
                      color: Colors.grey,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'mark_read':
                          controller.markChapterAsRead(chapter);
                          break;
                        case 'mark_unread':
                          controller.markChapterAsUnread(chapter);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!chapter.isRead)
                        const PopupMenuItem(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Iconsax.tick_circle),
                              SizedBox(width: 8),
                              Text('Đánh dấu đã đọc'),
                            ],
                          ),
                        ),
                      if (chapter.isRead)
                        const PopupMenuItem(
                          value: 'mark_unread',
                          child: Row(
                            children: [
                              Icon(Iconsax.clock),
                              SizedBox(width: 8),
                              Text('Đánh dấu chưa đọc'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} năm trước';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} tháng trước';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  void _showMoreOptions() {
    final story = controller.story.value;
    if (story == null) return;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Translate option for Syosetu stories
            if (story.canBeTranslated)
              Obx(() => ListTile(
                leading: controller.isTranslating.value
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    : const Icon(Iconsax.translate, color: Colors.blue),
                title: Text(controller.isTranslating.value ? 'Đang dịch...' : 'Dịch sang tiếng Việt'),
                subtitle: const Text('Dịch thông tin truyện bằng AI'),
                enabled: !controller.isTranslating.value,
                onTap: controller.isTranslating.value ? null : () {
                  Get.back();
                  controller.translateStory();
                },
              )),
            ListTile(
              leading: const Icon(Iconsax.refresh),
              title: const Text('Làm mới'),
              onTap: () {
                Get.back();
                controller.refresh();
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.share),
              title: const Text('Chia sẻ'),
              onTap: () {
                Get.back();
                // TODO: Implement share functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}