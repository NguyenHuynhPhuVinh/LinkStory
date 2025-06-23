import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/website_model.dart';

class WebViewView extends StatefulWidget {
  const WebViewView({Key? key}) : super(key: key);

  @override
  State<WebViewView> createState() => _WebViewViewState();
}

class _WebViewViewState extends State<WebViewView> {
  late webview_flutter.WebViewController webViewController;
  late Website website;

  bool isLoading = true;
  bool canGoBack = false;
  bool canGoForward = false;
  String currentUrl = '';
  String pageTitle = '';
  double loadingProgress = 0.0;
  bool isSecure = false;
  bool showMenu = false;
  bool showTranslateMenu = false;

  @override
  void initState() {
    super.initState();
    website = Get.arguments as Website;
    currentUrl = website.url;
    pageTitle = website.name;
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = webview_flutter.WebViewController()
      ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      )
      ..enableZoom(true)
      ..setNavigationDelegate(
        webview_flutter.NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              loadingProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
              currentUrl = url;
              isSecure = url.startsWith('https://');
            });
            _updateNavigationButtons();
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
            _updateNavigationButtons();
            _getPageTitle();
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            // Chỉ hiển thị lỗi cho main frame và các lỗi nghiêm trọng
            if ((error.isForMainFrame ?? false) &&
                _isCriticalError(error.errorCode)) {
              Get.snackbar(
                'Lỗi tải trang',
                'Không thể tải trang: ${error.description}',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red.withOpacity(0.8),
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            }
            // Bỏ qua lỗi của các tài nguyên phụ như quảng cáo, analytics, etc.
          },
          onNavigationRequest: (webview_flutter.NavigationRequest request) {
            return webview_flutter.NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(website.url));
  }

  Future<void> _updateNavigationButtons() async {
    final back = await webViewController.canGoBack();
    final forward = await webViewController.canGoForward();
    setState(() {
      canGoBack = back;
      canGoForward = forward;
    });
  }

  Future<void> _getPageTitle() async {
    try {
      final title = await webViewController.getTitle();
      if (title != null && title.isNotEmpty) {
        setState(() {
          pageTitle = title;
        });
      }
    } catch (e) {
      // Ignore title errors
    }
  }

  // Kiểm tra xem có phải lỗi nghiêm trọng không
  bool _isCriticalError(int? errorCode) {
    if (errorCode == null) return false;

    // Các mã lỗi nghiêm trọng cần hiển thị
    const criticalErrors = [
      -2, // ERROR_HOST_LOOKUP - Không tìm thấy host
      -6, // ERROR_CONNECT - Không thể kết nối
      -8, // ERROR_TIMEOUT - Timeout
      -14, // ERROR_FAILED_SSL_HANDSHAKE - Lỗi SSL
    ];

    return criticalErrors.contains(errorCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          webview_flutter.WebViewWidget(controller: webViewController),
          if (isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3.h,
                child: LinearProgressIndicator(
                  value: loadingProgress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          // Hiển thị loading overlay khi trang đang tải lần đầu
          if (isLoading && loadingProgress < 0.3)
            Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Đang tải ${website.name}...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showMenu) _buildMenuOverlay(),
          if (showTranslateMenu) _buildTranslateMenu(),
        ],
      ),
      bottomNavigationBar: _buildBottomToolbar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        onPressed: () => Get.back(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pageTitle,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              Icon(
                isSecure ? Iconsax.lock : Iconsax.unlock,
                size: 12.r,
                color: isSecure ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  currentUrl,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Iconsax.refresh),
          onPressed: () => webViewController.reload(),
        ),
        IconButton(
          icon: const Icon(Iconsax.more),
          onPressed: () => setState(() => showMenu = !showMenu),
        ),
      ],
    );
  }

  Widget _buildBottomToolbar() {
    final theme = Theme.of(context);

    return Container(
      height: 60.h,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Iconsax.arrow_left_2,
                color: canGoBack
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              onPressed: canGoBack ? () => webViewController.goBack() : null,
            ),
            IconButton(
              icon: Icon(
                Iconsax.arrow_right_3,
                color: canGoForward
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              onPressed: canGoForward
                  ? () => webViewController.goForward()
                  : null,
            ),
            IconButton(
              icon: const Icon(Iconsax.home_2),
              onPressed: () =>
                  webViewController.loadRequest(Uri.parse(website.url)),
            ),
            IconButton(
              icon: const Icon(Iconsax.share),
              onPressed: _shareCurrentPage,
            ),
            IconButton(
              icon: const Icon(Iconsax.language_square),
              onPressed: () =>
                  setState(() => showTranslateMenu = !showTranslateMenu),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOverlay() {
    return GestureDetector(
      onTap: () => setState(() => showMenu = false),
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
                      setState(() => showMenu = false);
                      _shareCurrentPage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Iconsax.global),
                    title: const Text('Mở trong trình duyệt'),
                    onTap: () {
                      setState(() => showMenu = false);
                      _openInBrowser();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Iconsax.language_square),
                    title: const Text('Dịch trang'),
                    onTap: () {
                      setState(() => showMenu = false);
                      _translatePage();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Iconsax.copy),
                    title: const Text('Sao chép URL'),
                    onTap: () {
                      setState(() => showMenu = false);
                      Clipboard.setData(ClipboardData(text: currentUrl));
                      Get.snackbar('Đã sao chép', 'URL đã được sao chép');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

    return GestureDetector(
      onTap: () => setState(() => showTranslateMenu = false),
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
                        onTap: () => _translateToLanguage(lang['code']!),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () =>
                          setState(() => showTranslateMenu = false),
                      child: const Text('Hủy'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareCurrentPage() async {
    try {
      await Share.share('$pageTitle\n$currentUrl', subject: pageTitle);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể chia sẻ trang: $e');
    }
  }

  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(currentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể mở trình duyệt: $e');
    }
  }

  void _translatePage() {
    final translateUrl =
        'https://translate.google.com/translate?sl=auto&tl=vi&u=${Uri.encodeComponent(currentUrl)}';
    webViewController.loadRequest(Uri.parse(translateUrl));
  }

  void _translateToLanguage(String languageCode) {
    final translateUrl =
        'https://translate.google.com/translate?sl=auto&tl=$languageCode&u=${Uri.encodeComponent(currentUrl)}';
    webViewController.loadRequest(Uri.parse(translateUrl));
    setState(() => showTranslateMenu = false);
  }
}
