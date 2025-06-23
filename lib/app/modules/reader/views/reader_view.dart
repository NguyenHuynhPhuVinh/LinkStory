import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:getwidget/getwidget.dart';

import '../controllers/reader_controller.dart';
import '../../../data/models/website_model.dart';

class ReaderView extends GetView<ReaderController> {
  const ReaderView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn nguồn truyện'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: () {
              Get.snackbar('Thông báo', 'Cài đặt nguồn sẽ được phát triển');
            },
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return _buildLoadingView();
        }

        final websites = controller.websites;

        if (websites.isEmpty) {
          return _buildEmptyView();
        }

        return LiquidPullToRefresh(
          onRefresh: controller.refreshWebsites,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: _buildWebsiteList(websites),
        );
      }),
    );
  }

  // Loading view với GFShimmer effect
  Widget _buildLoadingView() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(children: List.generate(6, (index) => _buildShimmerItem())),
    );
  }

  // GFShimmer item cho loading
  Widget _buildShimmerItem() {
    return GFShimmer(
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16.h,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8.h),
                  Container(width: 200.w, height: 12.h, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty view với GFCard
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
              Icon(Iconsax.global, size: 64.r, color: Colors.grey),
              SizedBox(height: 16.h),
              Text(
                'Không có nguồn truyện',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Hãy thêm nguồn truyện để bắt đầu đọc',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Danh sách websites
  Widget _buildWebsiteList(List<Website> websites) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: websites.length,
      itemBuilder: (context, index) {
        final website = websites[index];
        return _buildWebsiteItem(website);
      },
    );
  }

  // Item website với GFListTile
  Widget _buildWebsiteItem(Website website) {
    final theme = Theme.of(Get.context!);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: GFListTile(
        avatar: _buildWebsiteIcon(website),
        title: Text(
          website.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subTitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (website.description.isNotEmpty) ...[
              Text(
                website.description,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
            ],
            Text(
              website.url,
              style: TextStyle(
                fontSize: 11.sp,
                color: theme.colorScheme.primary.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        icon: Icon(
          Iconsax.arrow_right_3,
          size: 20.r,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        padding: EdgeInsets.all(16.w),
        margin: EdgeInsets.zero,
        color: theme.cardColor,
        shadow: BoxShadow(
          color: theme.brightness == Brightness.dark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.08),
          blurRadius: 8.r,
          offset: Offset(0, 2.h),
        ),
        radius: 12.r,
        onTap: () => controller.openWebsite(website),
      ),
    );
  }

  // Website icon với CachedNetworkImage và fallback
  Widget _buildWebsiteIcon(Website website) {
    final theme = Theme.of(Get.context!);

    return Container(
      width: 48.w,
      height: 48.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.r), // Nhỏ hơn 1px để tránh overflow
        child: CachedNetworkImage(
          imageUrl: website.iconUrl.isNotEmpty ? website.iconUrl : '',
          width: 48.w,
          height: 48.w,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          placeholder: (context, url) => Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Iconsax.global,
                  size: 24.r,
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Iconsax.global,
              size: 24.r,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
