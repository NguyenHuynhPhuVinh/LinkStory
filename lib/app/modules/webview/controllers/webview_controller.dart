import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart' as webview_flutter;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/website_model.dart';
import '../../../data/services/webview_scraper_service.dart';
import '../../../data/services/library_service.dart';
import '../../../data/services/chapter_service.dart';
import '../../../data/models/chapter_model.dart';

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

  // Library states
  bool showAddToLibraryButton = false;
  bool isAddingToLibrary = false;
  bool isInLibrary = false;

  // Services
  final WebViewScraperService _webViewScraperService = WebViewScraperService();
  final LibraryService _libraryService = LibraryService();
  final ChapterService _chapterService = ChapterService();

  @override
  void onInit() {
    super.onInit();

    // Get website from arguments
    website = Get.arguments as Website;
    currentUrl = website.url;
    pageTitle = website.name;

    // Initialize services and WebView
    _initializeServices();
    _initializeWebView();
  }

  Future<void> _initializeServices() async {
    await _libraryService.init();
    _checkIfCanScrape(currentUrl);
    await _checkIfInLibrary(currentUrl);
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
            _checkIfCanScrape(url);
            _checkIfInLibrary(url);
            update();
          },
          onPageFinished: (String url) {
            isLoading = false;
            _updateNavigationButtons();
            _getPageTitle();
            update();
          },
          onWebResourceError: (webview_flutter.WebResourceError error) {
            // Log lỗi để debug nhưng không hiển thị popup
            print(
              'WebResourceError: ${error.errorType} - ${error.description} - ${error.url}',
            );

            // Không hiển thị bất kỳ popup lỗi nào để tránh làm phiền người dùng
            // Các lỗi CORS, quảng cáo, tracking là bình thường với các website
            // Chỉ log để developer có thể debug nếu cần
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
      await Share.share('$pageTitle\n$currentUrl', subject: pageTitle);
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
    final translateUrl =
        'https://translate.google.com/translate?sl=auto&tl=vi&u=${Uri.encodeComponent(currentUrl)}';
    webViewController.loadRequest(Uri.parse(translateUrl));
  }

  void translateToLanguage(String languageCode) {
    final translateUrl =
        'https://translate.google.com/translate?sl=auto&tl=$languageCode&u=${Uri.encodeComponent(currentUrl)}';
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

  // Kiểm tra xem URL có thể scrape được không
  void _checkIfCanScrape(String url) {
    showAddToLibraryButton = _webViewScraperService.canScrapeUrl(url);
    update();
  }

  // Kiểm tra xem truyện đã có trong thư viện chưa
  Future<void> _checkIfInLibrary(String url) async {
    isInLibrary = await _libraryService.isUrlExists(url);
    update();
  }

  // Thêm truyện vào thư viện (luôn với danh sách chương)
  Future<void> addToLibrary() async {
    if (isAddingToLibrary || isInLibrary) return;

    try {
      isAddingToLibrary = true;
      update();

      Get.snackbar(
        'Đang xử lý',
        'Đang scrape thông tin truyện và danh sách chương...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );

      // Khởi tạo chapter service
      await _chapterService.init();

      final result = await _webViewScraperService.scrapeStoryWithChapters(
        currentUrl,
        scrapeContent: false, // Không tải nội dung từng chương
      );

      if (result != null) {
        final story = result['story'];
        final chapters = (result['chapters'] as List).cast<Chapter>();

        if (story != null) {
          // Thêm story vào library
          final storySuccess = await _libraryService.addStory(story);

          if (storySuccess) {
            // Thêm chapters vào database
            final chapterCount = await _chapterService.addChapters(chapters);

            isInLibrary = true;

            Get.snackbar(
              'Thành công',
              'Đã thêm "${story.title}" với $chapterCount chương vào thư viện',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.green.withOpacity(0.8),
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
          } else {
            Get.snackbar(
              'Thông báo',
              'Truyện đã có trong thư viện',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange.withOpacity(0.8),
              colorText: Colors.white,
            );
          }
        }
      } else {
        Get.snackbar(
          'Lỗi',
          'Không thể scrape thông tin truyện từ trang này. Vui lòng thử lại sau.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Có lỗi xảy ra: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    } finally {
      isAddingToLibrary = false;
      update();
    }
  }

  // Xem truyện trong thư viện
  void viewInLibrary() {
    Get.toNamed('/library');
    Get.snackbar(
      'Thông báo',
      'Chuyển đến thư viện để xem truyện',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  void onClose() {
    super.onClose();
  }
}
