import 'dart:async';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../models/story_model.dart';
import '../../models/chapter_model.dart';

class HakoScraper {
  static final HakoScraper _instance = HakoScraper._internal();
  factory HakoScraper() => _instance;
  HakoScraper._internal();

  // Scrape story từ Hako/DocLN sử dụng WebView
  Future<Story?> scrapeStoryWithWebView(String url) async {
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

  // Scrape từ Hako/DocLN với chapters sử dụng WebView
  Future<Map<String, dynamic>?> scrapeStoryWithChaptersWebView(String url, {bool scrapeContent = false}) async {
    try {
      final Completer<Map<String, dynamic>?> completer = Completer<Map<String, dynamic>?>();
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

                  print('HTML content length: ${htmlContent.length}');

                  // Parse HTML và trích xuất thông tin
                  final document = html_parser.parse(htmlContent);
                  final result = await _extractStoryWithChaptersFromDocument(document, url, scrapeContent: scrapeContent);

                  completer.complete(result);
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
      print('Error in WebView scraping with chapters: $e');
      return null;
    }
  }

  // Trích xuất thông tin story từ document
  Future<Story?> _extractStoryFromDocument(dom.Document document, String url) async {
    try {
      print('Extracting story information from rendered HTML...');
      
      // Trích xuất thông tin từ HTML
      final title = _extractTitle(document);
      print('Extracted title: "$title"');
      
      final author = _extractAuthor(document);
      print('Extracted author: "$author"');
      
      final description = _extractDescription(document);
      print('Extracted description length: ${description.length}');
      
      final coverImageUrl = _extractCoverImage(document, url);
      print('Extracted cover image: "$coverImageUrl"');
      
      final genres = _extractGenres(document);
      print('Extracted genres: $genres');
      
      final status = _extractStatus(document);
      print('Extracted status: "$status"');
      
      final translator = _extractTranslator(document);
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
          'scraper_version': '3.0_webview_hako',
        },
      );
      
      print('Story created successfully: ${story.title}');
      return story;
    } catch (e) {
      print('Error extracting story from document: $e');
      return null;
    }
  }

  // Trích xuất thông tin story với chapters từ document
  Future<Map<String, dynamic>?> _extractStoryWithChaptersFromDocument(dom.Document document, String url, {bool scrapeContent = false}) async {
    try {
      print('Extracting story with chapters from rendered HTML...');

      // Trích xuất thông tin story cơ bản
      final story = await _extractStoryFromDocument(document, url);
      if (story == null) {
        print('Failed to extract story information');
        return null;
      }

      // Trích xuất danh sách chapters
      final chapters = await _extractChaptersFromDocument(document, story.id, url);
      print('Extracted ${chapters.length} chapters');

      // Cập nhật totalChapters cho story
      final updatedStory = story.copyWith(totalChapters: chapters.length);

      // Scrape nội dung chapters nếu được yêu cầu
      if (scrapeContent && chapters.isNotEmpty) {
        print('Starting to scrape chapter contents...');
        await _scrapeChapterContents(chapters);
      }

      return {
        'story': updatedStory,
        'chapters': chapters,
        'scraped_content': scrapeContent,
      };
    } catch (e) {
      print('Error extracting story with chapters: $e');
      return null;
    }
  }

  // Kiểm tra xem URL có phải Hako/DocLN không
  bool canScrapeUrl(String url) {
    return url.contains('docln.sbs') || url.contains('hako.vn');
  }

  // Lấy tên website từ URL
  String getWebsiteName(String url) {
    if (url.contains('docln.sbs')) return 'DocLN';
    if (url.contains('hako.vn')) return 'Hako Light Novel';
    return 'Unknown';
  }

  // Trích xuất danh sách chapters từ document
  Future<List<Chapter>> _extractChaptersFromDocument(dom.Document document, String storyId, String baseUrl) async {
    final chapters = <Chapter>[];

    try {
      // Tìm tất cả volume sections
      final volumeSections = document.querySelectorAll('section.volume-list');
      print('Found ${volumeSections.length} volume sections');

      int globalChapterNumber = 1;

      for (int volumeIndex = 0; volumeIndex < volumeSections.length; volumeIndex++) {
        final volumeSection = volumeSections[volumeIndex];

        // Trích xuất tên volume
        final volumeTitleElement = volumeSection.querySelector('.sect-title');
        final volumeTitle = volumeTitleElement?.text.trim() ?? 'Tập ${volumeIndex + 1}';
        final volumeNumber = volumeIndex + 1;

        print('Processing volume: $volumeTitle');

        // Tìm tất cả chapters trong volume này
        final chapterElements = volumeSection.querySelectorAll('.list-chapters li');
        print('Found ${chapterElements.length} chapters in $volumeTitle');

        for (final chapterElement in chapterElements) {
          try {
            final chapterLink = chapterElement.querySelector('a');
            if (chapterLink == null) continue;

            final chapterTitle = chapterLink.attributes['title'] ?? chapterLink.text.trim();
            final chapterUrl = chapterLink.attributes['href'] ?? '';

            if (chapterTitle.isEmpty || chapterUrl.isEmpty) continue;

            // Tạo URL đầy đủ
            final fullChapterUrl = chapterUrl.startsWith('http')
                ? chapterUrl
                : '${Uri.parse(baseUrl).origin}$chapterUrl';

            // Trích xuất thời gian publish
            final timeElement = chapterElement.querySelector('.chapter-time');
            final timeText = timeElement?.text.trim() ?? '';
            final publishedAt = _parseDate(timeText);

            // Kiểm tra có ảnh minh họa không
            final hasImages = chapterElement.querySelector('.fas.fa-image') != null;

            // Tạo chapter ID từ URL
            final chapterId = _generateChapterId(fullChapterUrl);

            final chapter = Chapter(
              id: chapterId,
              storyId: storyId,
              title: chapterTitle,
              url: fullChapterUrl,
              chapterNumber: globalChapterNumber,
              volumeTitle: volumeTitle,
              volumeNumber: volumeNumber,
              publishedAt: publishedAt,
              hasImages: hasImages,
              metadata: {
                'scraped_at': DateTime.now().toIso8601String(),
                'scraper_version': '3.0_webview_hako',
                'volume_index': volumeIndex,
              },
            );

            chapters.add(chapter);
            globalChapterNumber++;

            print('Added chapter: $chapterTitle');
          } catch (e) {
            print('Error processing chapter: $e');
          }
        }
      }

      print('Successfully extracted ${chapters.length} chapters');
      return chapters;
    } catch (e) {
      print('Error extracting chapters: $e');
      return chapters;
    }
  }

  // Trích xuất tiêu đề từ Hako/DocLN
  String _extractTitle(dom.Document document) {
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
  String _extractAuthor(dom.Document document) {
    // Tìm link có href chứa "/tac-gia/"
    final authorLink = document.querySelector('a[href*="/tac-gia/"]');
    if (authorLink != null) {
      return authorLink.text.trim();
    }
    return 'Không rõ';
  }

  // Trích xuất mô tả từ Hako/DocLN
  String _extractDescription(dom.Document document) {
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
  String _extractCoverImage(dom.Document document, String baseUrl) {
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
  List<String> _extractGenres(dom.Document document) {
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
  String _extractStatus(dom.Document document) {
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
  String _extractTranslator(dom.Document document) {
    // Tìm link nhóm dịch có href chứa "/nhom-dich/"
    final translatorLink = document.querySelector('a[href*="/nhom-dich/"]');
    if (translatorLink != null) {
      return translatorLink.text.trim();
    }

    return '';
  }

  // Scrape nội dung của các chapters
  Future<void> _scrapeChapterContents(List<Chapter> chapters) async {
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      print('Scraping content for chapter ${i + 1}/${chapters.length}: ${chapter.title}');

      try {
        final content = await scrapeChapterContent(chapter.url);
        if (content.isNotEmpty) {
          chapters[i] = chapter.copyWith(
            content: content,
            wordCount: _countWords(content),
          );
          print('Successfully scraped content for: ${chapter.title}');
        } else {
          print('No content found for: ${chapter.title}');
        }
      } catch (e) {
        print('Error scraping content for ${chapter.title}: $e');
      }

      // Delay để tránh spam requests
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Scrape nội dung của một chapter
  Future<String> scrapeChapterContent(String chapterUrl) async {
    try {
      final Completer<String> completer = Completer<String>();
      late WebViewController controller;

      controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String finishedUrl) async {
              if (finishedUrl == chapterUrl && !completer.isCompleted) {
                await Future.delayed(const Duration(seconds: 2));

                try {
                  final html = await controller.runJavaScriptReturningResult(
                    'document.documentElement.outerHTML'
                  );

                  String htmlContent = html.toString();
                  if (htmlContent.startsWith('"') && htmlContent.endsWith('"')) {
                    htmlContent = htmlContent.substring(1, htmlContent.length - 1);
                  }

                  htmlContent = htmlContent
                      .replaceAll('\\"', '"')
                      .replaceAll('\\n', '\n')
                      .replaceAll('\\t', '\t')
                      .replaceAll('\\/', '/')
                      .replaceAll('\\u003C', '<')
                      .replaceAll('\\u003E', '>')
                      .replaceAll('\\u0026', '&')
                      .replaceAll('\\u0027', "'");

                  final document = html_parser.parse(htmlContent);
                  final content = _extractChapterContentFromDocument(document);

                  if (!completer.isCompleted) {
                    completer.complete(content);
                  }
                } catch (e) {
                  print('Error extracting chapter content: $e');
                  if (!completer.isCompleted) {
                    completer.complete('');
                  }
                }
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (!completer.isCompleted) {
                completer.complete('');
              }
            },
          ),
        );

      await controller.loadRequest(Uri.parse(chapterUrl));

      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          if (!completer.isCompleted) {
            completer.complete('');
          }
          return '';
        },
      );
    } catch (e) {
      print('Error scraping chapter content: $e');
      return '';
    }
  }

  // Trích xuất nội dung chapter từ document
  String _extractChapterContentFromDocument(dom.Document document) {
    // Tìm content container
    final contentElement = document.querySelector('#chapter-content') ??
                          document.querySelector('.chapter-content') ??
                          document.querySelector('.long-text');

    if (contentElement == null) {
      print('Chapter content element not found');
      return '';
    }

    // Lấy tất cả paragraphs
    final paragraphs = contentElement.querySelectorAll('p');
    final contentLines = <String>[];

    for (final paragraph in paragraphs) {
      final text = paragraph.text.trim();
      if (text.isNotEmpty) {
        contentLines.add(text);
      }
    }

    return contentLines.join('\n\n');
  }

  // Utility methods
  DateTime _parseDate(String dateText) {
    try {
      // Xử lý các format date khác nhau
      if (dateText.contains('/')) {
        final parts = dateText.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }

      // Fallback
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

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

  String _generateChapterId(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Tìm segment chứa chapter ID
    for (final segment in pathSegments) {
      if (segment.startsWith('c') && RegExp(r'^c\d+').hasMatch(segment)) {
        return '${uri.host}_$segment';
      }
    }

    // Fallback: sử dụng hash của URL
    return '${uri.host}_chapter_${url.hashCode.abs()}';
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}
