import 'dart:async';
import '../models/story_model.dart';
import 'scrapers/hako_scraper.dart';
import 'scrapers/syosetu_scraper.dart';

class WebViewScraperService {
  static final WebViewScraperService _instance =
      WebViewScraperService._internal();
  factory WebViewScraperService() => _instance;
  WebViewScraperService._internal();

  final HakoScraper _hakoScraper = HakoScraper();
  final SyosetuScraper _syosetuScraper = SyosetuScraper();

  // Scrape story từ URL sử dụng WebView
  Future<Story?> scrapeStory(String url) async {
    try {
      print('Starting WebView-based scraping from: $url');

      // Xác định website và gọi scraper tương ứng
      if (url.contains('docln.sbs') || url.contains('hako.vn')) {
        return await _hakoScraper.scrapeStoryWithWebView(url);
      } else if (url.contains('syosetu.com') || url.contains('ncode.syosetu.com')) {
        return await _syosetuScraper.scrapeStoryWithWebView(url);
      }

      return null;
    } catch (e) {
      print('Error in WebView scraping: $e');
      return null;
    }
  }

  // Scrape story với chapters từ URL sử dụng WebView
  Future<Map<String, dynamic>?> scrapeStoryWithChapters(
    String url, {
    bool scrapeContent = false,
  }) async {
    try {
      print('Starting WebView-based scraping with chapters from: $url');

      // Xác định website và gọi scraper tương ứng
      if (url.contains('docln.sbs') || url.contains('hako.vn')) {
        return await _hakoScraper.scrapeStoryWithChaptersWebView(
          url,
          scrapeContent: scrapeContent,
        );
      } else if (url.contains('syosetu.com') || url.contains('ncode.syosetu.com')) {
        return await _syosetuScraper.scrapeStoryWithChaptersWebView(
          url,
          scrapeContent: scrapeContent,
        );
      }

      return null;
    } catch (e) {
      print('Error in WebView scraping with chapters: $e');
      return null;
    }
  }

  // Kiểm tra xem URL có thể scrape được không
  bool canScrapeUrl(String url) {
    return _hakoScraper.canScrapeUrl(url) || _syosetuScraper.canScrapeUrl(url);
  }

  // Public method để scrape nội dung một chương
  Future<String> scrapeChapterContent(String chapterUrl) async {
    if (chapterUrl.contains('docln.sbs') || chapterUrl.contains('hako.vn')) {
      return await _hakoScraper.scrapeChapterContent(chapterUrl);
    } else if (chapterUrl.contains('syosetu.com') || chapterUrl.contains('ncode.syosetu.com')) {
      return await _syosetuScraper.scrapeChapterContent(chapterUrl);
    }
    return '';
  }

  // Lấy tên website từ URL
  String getWebsiteName(String url) {
    if (_hakoScraper.canScrapeUrl(url)) {
      return _hakoScraper.getWebsiteName(url);
    } else if (_syosetuScraper.canScrapeUrl(url)) {
      return _syosetuScraper.getWebsiteName(url);
    }
    return 'Unknown';
  }
}
