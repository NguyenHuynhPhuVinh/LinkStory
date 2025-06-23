import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/website_model.dart';

class WebViewController extends GetxController {
  late webview_flutter.WebViewController webViewController;

  // States
  bool isLoading = true;
  bool canGoBack = false;
  bool canGoForward = false;
  String currentUrl = '';
  String pageTitle = '';
  double loadingProgress = 0.0;
  bool isSecure = false;

  // Website info
  late Website website;

  // Menu states
  bool showMenu = false;
  bool showTranslateMenu = false;

  @override
  void onInit() {
    super.onInit();

    // Get website from arguments
    website = Get.arguments as Website;
    currentUrl = website.url;
    pageTitle = website.name;

    // Initialize WebView controller immediately
    _initializeWebView();
  }

  void _initializeWebView() {
    webViewController = webview_flutter.WebViewController()
      ..setJavaScriptMode(webview_flutter.JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        webview_flutter.NavigationDelegate(
          onProgress: (int progress) {
            loadingProgress = progress / 100.0;
            update();
          },
          onPageStarted: (String url) {
            isLoading = true;
            currentUrl = url;
            _updateSecurityStatus(url);
            _updateNavigationButtons();
            update();
          },
          onPageFinished: (String url) {
            isLoading = false;
            _updateNavigationButtons();
            _getPageTitle();
            update();
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            Get.snackbar(
              'Lỗi tải trang',
              'Không thể tải trang: ${error.description}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red.withOpacity(0.8),
              colorText: Colors.white,
            );
          },
          onNavigationRequest: (webview_flutter.NavigationRequest request) {
            // Allow all navigation
            return webview_flutter.NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(website.url));
  }

  void _updateSecurityStatus(String url) {
    isSecure = url.startsWith('https://');
  }

  Future<void> _updateNavigationButtons() async {
    canGoBack = await webViewController.canGoBack();
    canGoForward = await webViewController.canGoForward();
    update();
  }

  Future<void> _getPageTitle() async {
    try {
      final title = await webViewController.getTitle();
      if (title != null && title.isNotEmpty) {
        pageTitle = title;
        update();
      }
    } catch (e) {
      // Ignore title errors
    }
  }

  // Navigation methods
  Future<void> goBack() async {
    if (await webViewController.canGoBack()) {
      await webViewController.goBack();
    }
  }

  Future<void> goForward() async {
    if (await webViewController.canGoForward()) {
      await webViewController.goForward();
    }
  }

  Future<void> reload() async {
    await webViewController.reload();
  }

  void goHome() {
    webViewController.loadRequest(Uri.parse(website.url));
  }

  // Share functionality
  Future<void> shareCurrentPage() async {
    try {
      await Share.share(
        '$pageTitle\n$currentUrl',
        subject: pageTitle,
      );
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể chia sẻ trang: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Open in external browser
  Future<void> openInBrowser() async {
    try {
      final uri = Uri.parse(currentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể mở trình duyệt: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Translation functionality
  void translatePage() {
    final translateUrl = 'https://translate.google.com/translate?sl=auto&tl=vi&u=${Uri.encodeComponent(currentUrl)}';
    webViewController.loadRequest(Uri.parse(translateUrl));
  }

  void translateToLanguage(String languageCode) {
    final translateUrl = 'https://translate.google.com/translate?sl=auto&tl=$languageCode&u=${Uri.encodeComponent(currentUrl)}';
    webViewController.loadRequest(Uri.parse(translateUrl));
    showTranslateMenu = false;
    update();
  }

  // Menu controls
  void toggleMenu() {
    showMenu = !showMenu;
    update();
  }

  void hideMenu() {
    showMenu = false;
    update();
  }

  void toggleTranslateMenu() {
    showTranslateMenu = !showTranslateMenu;
    update();
  }

  // Search functionality
  void searchOnPage(String query) {
    // This would require JavaScript injection for find-in-page
    // For now, we'll show a simple message
    Get.snackbar(
      'Tìm kiếm',
      'Tính năng tìm kiếm trong trang đang được phát triển',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // Zoom functionality
  Future<void> zoomIn() async {
    try {
      await webViewController.runJavaScript('''
        document.body.style.zoom = (parseFloat(document.body.style.zoom || 1) + 0.1).toString();
      ''');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể phóng to: $e');
    }
  }

  Future<void> zoomOut() async {
    try {
      await webViewController.runJavaScript('''
        var currentZoom = parseFloat(document.body.style.zoom || 1);
        if (currentZoom > 0.5) {
          document.body.style.zoom = (currentZoom - 0.1).toString();
        }
      ''');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể thu nhỏ: $e');
    }
  }

  Future<void> resetZoom() async {
    try {
      await webViewController.runJavaScript('''
        document.body.style.zoom = '1';
      ''');
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể reset zoom: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
