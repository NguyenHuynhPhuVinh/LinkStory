import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/webview_controller.dart' as controllers;

class WebViewView extends GetView<controllers.WebViewController> {
  const WebViewView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          GetBuilder<controllers.WebViewController>(
            builder: (controller) => webview_flutter.WebViewWidget(
              controller: controller.webViewController,
            ),
          ),
          _buildProgressIndicator(),
          _buildMenuOverlay(),
          _buildTranslateMenu(),
        ],
      ),
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(Get.context!).scaffoldBackgroundColor,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        onPressed: () => Get.back(),
      ),
      title: GetBuilder<controllers.WebViewController>(
        builder: (controller) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              controller.pageTitle,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Icon(
                  controller.isSecure ? Iconsax.lock : Iconsax.unlock,
                  size: 12.r,
                  color: controller.isSecure ? Colors.green : Colors.orange,
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    controller.currentUrl,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(Get.context!).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: controller.reload,
        ),
        IconButton(
          icon: const Icon(Iconsax.more),
          onPressed: controller.toggleMenu,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return GetBuilder<controllers.WebViewController>(
      builder: (controller) => controller.isLoading
          ? Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3.h,
                child: LinearProgressIndicator(
                  value: controller.loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(Get.context!).colorScheme.primary,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildBottomToolbar() {
    return GetBuilder<controllers.WebViewController>(
      builder: (controller) {
        final theme = Theme.of(Get.context!);

        return Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 0.5),
            ),
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.arrow_left_2,
                    color: controller.canGoBack
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onPressed: controller.canGoBack ? controller.goBack : null,
                ),
                IconButton(
                  icon: Icon(
                    Iconsax.arrow_right_3,
                    color: controller.canGoForward
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  onPressed: controller.canGoForward
                      ? controller.goForward
                      : null,
                ),
                IconButton(
                  icon: const Icon(Iconsax.home_2),
                  onPressed: () => controller.webViewController.loadRequest(
                    Uri.parse(controller.website.url),
                  ),
                ),
                IconButton(
                  icon: const Icon(Iconsax.share),
                  onPressed: controller.shareCurrentPage,
                ),
                _buildAddToLibraryButton(controller, theme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddToLibraryButton(
    controllers.WebViewController controller,
    ThemeData theme,
  ) {
    if (!controller.showAddToLibraryButton) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: controller.isAddingToLibrary
          ? SizedBox(
              width: 16.w,
              height: 16.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
              ),
            )
          : Icon(
              controller.isInLibrary ? Iconsax.book : Iconsax.add,
              color: controller.isInLibrary
                  ? Colors.green
                  : theme.colorScheme.primary,
            ),
      onPressed: controller.isAddingToLibrary
          ? null
          : (controller.isInLibrary
                ? controller.viewInLibrary
                : controller.addToLibrary),
      tooltip: controller.isAddingToLibrary
          ? 'Đang scrape truyện và chương...'
          : (controller.isInLibrary
                ? 'Xem trong thư viện'
                : 'Thêm truyện + chương vào thư viện'),
    );
  }

  Widget _buildMenuOverlay() {
    return GetBuilder<controllers.WebViewController>(
      builder: (controller) => controller.showMenu
          ? GestureDetector(
              onTap: controller.hideMenu,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(top: 60.h, right: 16.w),
                    child: Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Iconsax.share),
                            title: const Text('Chia sẻ'),
                            onTap: () {
                              controller.hideMenu();
                              controller.shareCurrentPage();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Iconsax.global),
                            title: const Text('Mở trong trình duyệt'),
                            onTap: () {
                              controller.hideMenu();
                              controller.openInBrowser();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Iconsax.language_square),
                            title: const Text('Dịch trang'),
                            onTap: () {
                              controller.hideMenu();
                              controller.translatePage();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Iconsax.copy),
                            title: const Text('Sao chép URL'),
                            onTap: () {
                              controller.hideMenu();
                              Clipboard.setData(
                                ClipboardData(text: controller.currentUrl),
                              );
                              Get.snackbar(
                                'Đã sao chép',
                                'URL đã được sao chép',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTranslateMenu() {
    final languages = [
      {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
      {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
      {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
      {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
    ];

    return GetBuilder<controllers.WebViewController>(
      builder: (controller) => controller.showTranslateMenu
          ? GestureDetector(
              onTap: controller.toggleTranslateMenu,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(32.w),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Dịch trang sang',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ...languages.map(
                              (lang) => ListTile(
                                leading: Text(
                                  lang['flag']!,
                                  style: TextStyle(fontSize: 24.sp),
                                ),
                                title: Text(lang['name']!),
                                onTap: () => controller.translateToLanguage(
                                  lang['code']!,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            ElevatedButton(
                              onPressed: controller.toggleTranslateMenu,
                              child: const Text('Hủy'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
