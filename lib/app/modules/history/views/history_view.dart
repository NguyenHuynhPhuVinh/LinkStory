import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getwidget/getwidget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

import '../controllers/history_controller.dart';
import '../../../data/services/theme_service.dart';
import '../../../data/models/reading_history_model.dart';
import '../../home/controllers/home_controller.dart';
import '../widgets/history_item_widget.dart';

class HistoryView extends GetView<HistoryController> {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    // Auto-refresh when view is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshHistory();
    });

    return Obx(() => Scaffold(
      key: ValueKey(ThemeService.to.rebuildTrigger.value),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return _buildLoadingView();
              }

              if (controller.allHistory.isEmpty) {
                return _buildEmptyView();
              }

              if (controller.filteredHistory.isEmpty) {
                return _buildNoResultsView();
              }

              return _buildHistoryList();
            }),
          ),
        ],
      ),
    ));
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Obx(() => Text(
        controller.allHistory.isEmpty
          ? 'Lịch sử đọc'
          : 'Lịch sử (${controller.filteredHistory.length})',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
        ),
      )),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      foregroundColor: Theme.of(Get.context!).colorScheme.onSurface,
      actions: [
        // Sort button
        Obx(() => IconButton(
          icon: Icon(
            controller.currentSort.value == HistorySortBy.dateDesc
              ? Iconsax.sort
              : Iconsax.sort,
          ),
          onPressed: () => _showSortDialog(),
          tooltip: 'Sắp xếp',
        )),

        // More options
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.more),
          onSelected: (value) => _handleMenuAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Iconsax.export),
                  SizedBox(width: 8),
                  Text('Xuất dữ liệu'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
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

  Widget _buildSearchAndFilter() {
    return Container(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Search bar - đồng nhất với LibraryView
          TextField(
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm lịch sử...',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
                ? IconButton(
                    icon: const Icon(Iconsax.close_circle),
                    onPressed: controller.clearFilters,
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

          // Filter chips - đồng nhất với LibraryView
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(HistoryFilter.all, 'Tất cả', Iconsax.clock),
                SizedBox(width: 8.w),
                _buildFilterChip(HistoryFilter.read, 'Đã đọc', Iconsax.book_1),
                SizedBox(width: 8.w),
                _buildFilterChip(HistoryFilter.library, 'Thư viện', Iconsax.book),
                SizedBox(width: 8.w),
                _buildFilterChip(HistoryFilter.favorite, 'Yêu thích', Iconsax.heart),
                SizedBox(width: 8.w),
                _buildFilterChip(HistoryFilter.translate, 'Dịch thuật', Iconsax.translate),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(HistoryFilter filter, String label, IconData icon) {
    return Obx(() {
      final isSelected = controller.currentFilter.value == filter;
      return GFButton(
        onPressed: () => controller.setFilter(filter),
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

  Widget _buildHistoryList() {
    return LiquidPullToRefresh(
      onRefresh: controller.refreshHistory,
      color: Theme.of(Get.context!).colorScheme.primary,
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: controller.filteredHistory.length,
        itemBuilder: (context, index) {
          final history = controller.filteredHistory[index];
          return HistoryItemWidget(
            history: history,
            onTap: () => controller.continueReading(history),
          );
        },
      ),
    );
  }





  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        controller.exportHistory();
      case 'clear':
        controller.clearAllHistory();
    }
  }

  void _showSortDialog() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Theme.of(Get.context!).scaffoldBackgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sắp xếp theo',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            Obx(() => Column(
              children: [
                _buildSortOption(HistorySortBy.dateDesc, 'Mới nhất', Iconsax.arrow_down_1),
                _buildSortOption(HistorySortBy.dateAsc, 'Cũ nhất', Iconsax.arrow_up_2),
                _buildSortOption(HistorySortBy.storyTitle, 'Tên truyện', Iconsax.text),
                _buildSortOption(HistorySortBy.readingTime, 'Thời gian đọc', Iconsax.clock),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(HistorySortBy sortBy, String title, IconData icon) {
    final isSelected = controller.currentSort.value == sortBy;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(Get.context!).colorScheme.primary : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(Get.context!).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected ? Icon(
        Iconsax.tick_circle,
        color: Theme.of(Get.context!).colorScheme.primary,
      ) : null,
      onTap: () {
        controller.setSort(sortBy);
        Get.back();
      },
    );
  }





  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải lịch sử...'),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: GFCard(
          boxFit: BoxFit.cover,
          color: Theme.of(Get.context!).cardColor,
          elevation: 4,
          padding: EdgeInsets.all(24.w),
          margin: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.clock,
                size: 64.r,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                'Chưa có lịch sử đọc',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Hãy bắt đầu đọc truyện để xem lịch sử tại đây',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
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
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: GFCard(
          boxFit: BoxFit.cover,
          color: Theme.of(Get.context!).cardColor,
          elevation: 4,
          padding: EdgeInsets.all(24.w),
          margin: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.search_normal,
                size: 64.r,
                color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
              ),
              SizedBox(height: 16.h),
              Text(
                'Không tìm thấy kết quả',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              GFButton(
                onPressed: controller.clearFilters,
                text: 'Xóa bộ lọc',
                icon: Icon(Iconsax.refresh, size: 18.sp),
                type: GFButtonType.outline,
                shape: GFButtonShape.pills,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
