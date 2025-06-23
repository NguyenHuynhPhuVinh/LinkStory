import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/story_model.dart';

class WebViewScraperService {
  static final WebViewScraperService _instance = WebViewScraperService._internal();
  factory WebViewScraperService() => _instance;
  WebViewScraperService._internal();

  // Scrape story từ URL sử dụng WebView
  Future<Story?> scrapeStory(String url) async {
    try {
      print('Starting WebView-based scraping from: $url');
      
      // Xác định website và gọi scraper tương ứng
      if (url.contains('docln.sbs') || url.contains('hako.vn')) {
        return await _scrapeHakoStoryWithWebView(url);
      } else if (url.contains('syosetu.com')) {
        return await _scrapeSyosetuStoryWithWebView(url);
      }

      return null;
    } catch (e) {
      print('Error in WebView scraping: $e');
      return null;
    }
  }

  // Scrape từ Hako/DocLN sử dụng WebView
  Future<Story?> _scrapeHakoStoryWithWebView(String url) async {
    try {
      final Completer<Story?> completer = Completer<Story?>();
      late WebViewController controller;

      // Tạo WebView controller
      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String finishedUrl) async {
              if (finishedUrl == url) {
                // Đợi một chút để JavaScript render xong
                await Future.delayed(const Duration(seconds: 3));

                try {
                  // Lấy HTML đã được render
                  final html = await controller.runJavaScriptReturningResult(
                    'document.documentElement.outerHTML'
                  );
                  
                  // Xử lý HTML string (loại bỏ quotes)
                  String htmlContent = html.toString();
                  if (htmlContent.startsWith('"') && htmlContent.endsWith('"')) {
                    htmlContent = htmlContent.substring(1, htmlContent.length - 1);
                  }

                  // Decode escaped characters
                  htmlContent = htmlContent
                      .replaceAll('\\"', '"')
                      .replaceAll('\\n', '\n')
                      .replaceAll('\\t', '\t')
                      .replaceAll('\\/', '/')
                      .replaceAll('\\u003C', '<')
                      .replaceAll('\\u003E', '>')
                      .replaceAll('\\u0026', '&')
                      .replaceAll('\\u0027', "'");

                  print('WebView HTML length: ${htmlContent.length}');
                  print('HTML contains "series-name": ${htmlContent.contains("series-name")}');

                  // Debug: In ra một phần HTML chứa series-name
                  final seriesNameIndex = htmlContent.indexOf('series-name');
                  if (seriesNameIndex != -1) {
                    final start = (seriesNameIndex - 100).clamp(0, htmlContent.length);
                    final end = (seriesNameIndex + 200).clamp(0, htmlContent.length);
                    final snippet = htmlContent.substring(start, end);
                    print('DEBUG: HTML snippet around series-name: $snippet');
                  }

                  // Parse HTML và trích xuất thông tin
                  final document = html_parser.parse(htmlContent);
                  final story = await _extractStoryFromDocument(document, url);
                  
                  completer.complete(story);
                } catch (e) {
                  print('Error extracting HTML from WebView: $e');
                  completer.complete(null);
                }
              }
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView error: ${error.description}');
              if (!completer.isCompleted) {
                completer.complete(null);
              }
            },
          ),
        );

      // Load URL
      await controller.loadRequest(Uri.parse(url));
      
      // Đợi kết quả với timeout
      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('WebView scraping timeout');
          return null;
        },
      );
      
    } catch (e) {
      print('Error in WebView scraping: $e');
      return null;
    }
  }

  // Trích xuất thông tin story từ document
  Future<Story?> _extractStoryFromDocument(dom.Document document, String url) async {
    try {
      print('Extracting story information from rendered HTML...');
      
      // Trích xuất thông tin từ HTML
      final title = _extractHakoTitle(document);
      print('Extracted title: "$title"');
      
      final author = _extractHakoAuthor(document);
      print('Extracted author: "$author"');
      
      final description = _extractHakoDescription(document);
      print('Extracted description length: ${description.length}');
      
      final coverImageUrl = _extractHakoCoverImage(document, url);
      print('Extracted cover image: "$coverImageUrl"');
      
      final genres = _extractHakoGenres(document);
      print('Extracted genres: $genres');
      
      final status = _extractHakoStatus(document);
      print('Extracted status: "$status"');
      
      final translator = _extractHakoTranslator(document);
      print('Extracted translator: "$translator"');

      if (title.isEmpty) {
        print('Title is empty, returning null');
        return null;
      }

      // Tạo ID unique từ URL
      final storyId = _generateStoryId(url);
      print('Generated story ID: $storyId');

      final story = Story(
        id: storyId,
        title: title,
        author: author,
        description: description,
        coverImageUrl: coverImageUrl,
        sourceUrl: url,
        sourceWebsite: url.contains('hako.vn') ? 'Hako Light Novel' : 'DocLN',
        genres: genres,
        status: status,
        translator: translator,
        originalLanguage: 'Nhật Bản',
        metadata: {
          'scraped_at': DateTime.now().toIso8601String(),
          'scraper_version': '3.0_webview',
        },
      );
      
      print('Story created successfully: ${story.title}');
      return story;
    } catch (e) {
      print('Error extracting story from document: $e');
      return null;
    }
  }

  // Scrape từ Syosetu (placeholder)
  Future<Story?> _scrapeSyosetuStoryWithWebView(String url) async {
    // TODO: Implement Syosetu WebView scraper
    return null;
  }

  // Trích xuất tiêu đề từ Hako/DocLN
  String _extractHakoTitle(dom.Document document) {
    print('DEBUG: Looking for title in WebView HTML...');

    // Debug: Tìm tất cả elements có class chứa "series"
    final allElements = document.querySelectorAll('*');
    for (final element in allElements) {
      final className = element.className;
      if (className.contains('series-name')) {
        print('DEBUG: Found element with series-name class: ${element.outerHtml.substring(0, 200)}...');
        break;
      }
    }

    // Tìm tiêu đề trong .series-name a
    final seriesNameLink = document.querySelector('.series-name a');
    print('DEBUG: .series-name a found: ${seriesNameLink != null}');
    if (seriesNameLink != null) {
      final title = seriesNameLink.text.trim();
      print('DEBUG: Title from .series-name a: "$title"');
      if (title.isNotEmpty) {
        return title;
      }
    }

    // Thử selector khác
    final seriesNameSpan = document.querySelector('span.series-name a');
    print('DEBUG: span.series-name a found: ${seriesNameSpan != null}');
    if (seriesNameSpan != null) {
      final title = seriesNameSpan.text.trim();
      print('DEBUG: Title from span.series-name a: "$title"');
      if (title.isNotEmpty) {
        return title;
      }
    }

    // Thử lấy từ title tag
    final titleElement = document.querySelector('title');
    print('DEBUG: title tag found: ${titleElement != null}');
    if (titleElement != null) {
      final titleText = titleElement.text.trim();
      print('DEBUG: Title tag content: "$titleText"');
      // Loại bỏ phần " - Cổng Light Novel - Đọc Light Novel" ở cuối
      final cleanTitle = titleText.replaceAll(
        RegExp(r' - Cổng Light Novel.*$'),
        '',
      );
      if (cleanTitle.isNotEmpty) {
        return cleanTitle;
      }
    }

    print('DEBUG: No title found');
    return '';
  }

  // Trích xuất tác giả từ Hako/DocLN
  String _extractHakoAuthor(dom.Document document) {
    // Tìm link có href chứa "/tac-gia/"
    final authorLink = document.querySelector('a[href*="/tac-gia/"]');
    if (authorLink != null) {
      return authorLink.text.trim();
    }
    return 'Không rõ';
  }

  // Trích xuất mô tả từ Hako/DocLN
  String _extractHakoDescription(dom.Document document) {
    // Tìm phần tóm tắt trong .summary-content
    final summaryContent = document.querySelector('.summary-content');
    if (summaryContent != null) {
      // Lấy tất cả text từ các thẻ p
      final paragraphs = summaryContent.querySelectorAll('p');
      final description = StringBuffer();
      
      for (final p in paragraphs) {
        final text = p.text.trim();
        if (text.isNotEmpty && text != '&nbsp;') {
          description.writeln(text);
        }
      }
      
      final result = description.toString().trim();
      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  // Trích xuất ảnh bìa từ Hako/DocLN
  String _extractHakoCoverImage(dom.Document document, String baseUrl) {
    // Tìm ảnh bìa trong .series-cover .content
    final contentDiv = document.querySelector('.series-cover .content');
    if (contentDiv != null) {
      final style = contentDiv.attributes['style'];
      if (style != null && style.contains('background-image: url(')) {
        // Trích xuất URL từ style
        final urlMatch = RegExp(r"url\('([^']+)'\)").firstMatch(style);
        if (urlMatch != null) {
          final imageUrl = urlMatch.group(1)!;
          if (imageUrl.startsWith('http')) {
            return imageUrl;
          } else if (imageUrl.startsWith('/')) {
            final uri = Uri.parse(baseUrl);
            return '${uri.scheme}://${uri.host}$imageUrl';
          }
        }
      }
    }

    return '';
  }

  // Trích xuất thể loại từ Hako/DocLN
  List<String> _extractHakoGenres(dom.Document document) {
    final genres = <String>[];

    // Tìm các thể loại trong .series-gernes
    final genreLinks = document.querySelectorAll('.series-gernes .series-gerne-item');
    for (final link in genreLinks) {
      final genre = link.text.trim();
      if (genre.isNotEmpty && !genres.contains(genre)) {
        genres.add(genre);
      }
    }

    return genres;
  }

  // Trích xuất trạng thái từ Hako/DocLN
  String _extractHakoStatus(dom.Document document) {
    // Tìm trạng thái trong .info-item có "Tình trạng:"
    final infoItems = document.querySelectorAll('.info-item');
    for (final item in infoItems) {
      final infoName = item.querySelector('.info-name');
      if (infoName != null && infoName.text.contains('Tình trạng:')) {
        final infoValue = item.querySelector('.info-value a');
        if (infoValue != null) {
          final status = infoValue.text.trim();
          if (status.isNotEmpty) {
            return status;
          }
        }
      }
    }

    return 'Đang tiến hành';
  }

  // Trích xuất người dịch từ Hako/DocLN
  String _extractHakoTranslator(dom.Document document) {
    // Tìm link nhóm dịch có href chứa "/nhom-dich/"
    final translatorLink = document.querySelector('a[href*="/nhom-dich/"]');
    if (translatorLink != null) {
      return translatorLink.text.trim();
    }

    return '';
  }

  // Tạo ID unique từ URL
  String _generateStoryId(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Lấy ID từ URL nếu có
    for (final segment in pathSegments) {
      if (RegExp(r'^\d+').hasMatch(segment)) {
        final match = RegExp(r'^(\d+)').firstMatch(segment);
        if (match != null) {
          return '${uri.host}_${match.group(1)}';
        }
      }
    }

    // Fallback: sử dụng hash của URL
    return '${uri.host}_${url.hashCode.abs()}';
  }

  // Kiểm tra xem URL có thể scrape được không
  bool canScrapeUrl(String url) {
    return url.contains('docln.sbs') ||
        url.contains('hako.vn') ||
        url.contains('syosetu.com');
  }

  // Lấy tên website từ URL
  String getWebsiteName(String url) {
    if (url.contains('docln.sbs')) return 'DocLN';
    if (url.contains('hako.vn')) return 'Hako Light Novel';
    if (url.contains('syosetu.com')) return 'Syosetu';
    return 'Unknown';
  }
}
