import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/reading_history_model.dart';

class HistoryItemWidget extends StatelessWidget {
  final ReadingHistory history;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onNavigateToStory;

  const HistoryItemWidget({
    Key? key,
    required this.history,
    this.onTap,
    this.onDelete,
    this.onNavigateToStory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image
                _buildCoverImage(context),

                SizedBox(width: 12.w),

                // History info
                Expanded(
                  child: _buildHistoryInfo(context),
                ),

                // Action button
                _buildActionButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    return Container(
      width: 60.w,
      height: 80.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: CachedNetworkImage(
          imageUrl: history.storyCoverUrl,
          width: 60.w,
          height: 80.h,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 60.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Iconsax.book,
              size: 24.sp,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 60.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Iconsax.book,
              size: 24.sp,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Story title
        Text(
          history.storyTitle,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 4.h),
        
        // Author
        Text(
          history.storyAuthor,
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 4.h),
        
        // Chapter info or action
        Text(
          history.displaySubtitle,
          style: TextStyle(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 8.h),
        
        // Time and action info
        Row(
          children: [
            Icon(
              _getActionIcon(history.action),
              size: 14.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(width: 4.w),
            Text(
              history.actionDisplayText,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '• ${_getRelativeTime(history.readAt)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        
        // Additional info for reading sessions
        if (history.action == ReadingAction.read && history.readingDuration > 0) ...[
          SizedBox(height: 4.h),
          Row(
            children: [
              if (history.readingDuration > 0) ...[
                Icon(
                  Iconsax.clock,
                  size: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                SizedBox(width: 4.w),
                Text(
                  _formatDuration(history.readingDuration),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
              if (history.wordsRead > 0) ...[
                SizedBox(width: 8.w),
                Icon(
                  Iconsax.document_text,
                  size: 12.sp,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                SizedBox(width: 4.w),
                Text(
                  '${history.wordsRead} từ',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Iconsax.more,
        size: 20.sp,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
      ),
      onSelected: (value) => _handleAction(value),
      itemBuilder: (context) => [
        if (history.isChapterRead) ...[
          const PopupMenuItem(
            value: 'continue',
            child: Row(
              children: [
                Icon(Iconsax.play),
                SizedBox(width: 8),
                Text('Tiếp tục đọc'),
              ],
            ),
          ),
        ],
        const PopupMenuItem(
          value: 'story',
          child: Row(
            children: [
              Icon(Iconsax.book),
              SizedBox(width: 8),
              Text('Xem truyện'),
            ],
          ),
        ),
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
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'continue':
        onTap?.call();
        break;
      case 'story':
        onNavigateToStory?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  IconData _getActionIcon(ReadingAction action) {
    switch (action) {
      case ReadingAction.read:
        return Iconsax.book_1;
      case ReadingAction.addToLibrary:
        return Iconsax.add_circle;
      case ReadingAction.removeFromLibrary:
        return Iconsax.minus;
      case ReadingAction.favorite:
        return Iconsax.heart5;
      case ReadingAction.unfavorite:
        return Iconsax.heart;
      case ReadingAction.rate:
        return Iconsax.star1;
      case ReadingAction.share:
        return Iconsax.share;
      case ReadingAction.translate:
        return Iconsax.translate;
      case ReadingAction.download:
        return Iconsax.document_download;
      case ReadingAction.view:
        return Iconsax.eye;
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} ngày trước';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
