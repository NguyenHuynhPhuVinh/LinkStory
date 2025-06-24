import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../../models/story_model.dart';
import '../../models/chapter_model.dart';

class SyosetuScraper {
  static final SyosetuScraper _instance = SyosetuScraper._internal();
  factory SyosetuScraper() => _instance;
  SyosetuScraper._internal();

  // Scrape story từ Syosetu sử dụng Dio (nhanh và ổn định)
  Future<Story?> scrapeStoryWithWebView(String url) async {
    try {
      print('🚀 Starting Syosetu story scraping with Dio for: $url');

      final dio = _createDioInstance();
      final response = await dio.get(url);

      if (response.statusCode != 200) {
        print('❌ HTTP ${response.statusCode} for: $url');
        return null;
      }

      final document = html_parser.parse(response.data);
      final story = await _extractStoryFromDocument(document, url);

      if (story != null) {
        print('✅ Successfully scraped Syosetu story: ${story.title}');
      } else {
        print('❌ Failed to extract story information');
      }

      return story;
    } catch (e, stackTrace) {
      print('❌ Error in Syosetu Dio story scraping: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Scrape từ Syosetu với chapters (sử dụng Dio - nhanh và ổn định)
  Future<Map<String, dynamic>?> scrapeStoryWithChaptersWebView(String url, {bool scrapeContent = false}) async {
    // Chuyển sang sử dụng Dio thay vì WebView
    return await scrapeStoryWithChaptersDio(url, scrapeContent: scrapeContent);
  }



  // Trích xuất thông tin story từ document
  Future<Story?> _extractStoryFromDocument(dom.Document document, String url) async {
    try {
      print('Extracting Syosetu story information from rendered HTML...');
      print('Document title: ${document.querySelector('title')?.text ?? "No title"}');
      
      // Trích xuất thông tin từ HTML
      final title = _extractTitle(document);
      print('Extracted title: "$title"');
      
      final author = _extractAuthor(document);
      print('Extracted author: "$author"');
      
      final description = _extractDescription(document);
      print('Extracted description length: ${description.length}');
      
      // Syosetu thường không có ảnh bìa
      final coverImageUrl = '';
      
      // Syosetu không có thể loại rõ ràng như Hako
      final genres = <String>['Light Novel'];
      
      // Syosetu không có trạng thái rõ ràng
      final status = 'Đang tiến hành';

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
        sourceWebsite: 'Syosetu',
        genres: genres,
        status: status,
        translator: '', // Syosetu là tiếng Nhật gốc
        originalLanguage: 'Nhật Bản',
        metadata: {
          'scraped_at': DateTime.now().toIso8601String(),
          'scraper_version': '3.0_webview_syosetu',
        },
      );
      
      print('Syosetu story created successfully: ${story.title}');
      return story;
    } catch (e, stackTrace) {
      print('Error extracting Syosetu story from document: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Trích xuất thông tin story với chapters từ document
  Future<Map<String, dynamic>?> _extractStoryWithChaptersFromDocument(dom.Document document, String url, {bool scrapeContent = false}) async {
    try {
      print('Extracting Syosetu story with chapters from rendered HTML...');

      // Trích xuất thông tin story cơ bản
      final story = await _extractStoryFromDocument(document, url);
      if (story == null) {
        print('Failed to extract Syosetu story information');
        return null;
      }

      // Trích xuất danh sách chapters
      final chapters = await _extractChaptersFromDocument(document, story.id, url);
      print('Extracted ${chapters.length} Syosetu chapters');

      // Cập nhật totalChapters cho story
      final updatedStory = story.copyWith(totalChapters: chapters.length);

      // Scrape nội dung chapters nếu được yêu cầu
      if (scrapeContent && chapters.isNotEmpty) {
        print('Starting to scrape Syosetu chapter contents...');
        await _scrapeChapterContents(chapters);
      }

      return {
        'story': updatedStory,
        'chapters': chapters,
        'scraped_content': scrapeContent,
      };
    } catch (e, stackTrace) {
      print('Error extracting Syosetu story with chapters: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  // Kiểm tra xem URL có phải Syosetu không
  bool canScrapeUrl(String url) {
    return url.contains('syosetu.com') || url.contains('ncode.syosetu.com');
  }

  // Lấy tên website từ URL
  String getWebsiteName(String url) {
    if (url.contains('syosetu.com') || url.contains('ncode.syosetu.com')) return 'Syosetu';
    return 'Unknown';
  }

  // Trích xuất danh sách chapters từ document với hỗ trợ phân trang
  Future<List<Chapter>> _extractChaptersFromDocument(dom.Document document, String storyId, String baseUrl) async {
    final chapters = <Chapter>[];

    try {
      // Trích xuất chapters từ trang hiện tại
      await _extractChaptersFromCurrentPage(document, chapters, storyId, baseUrl);

      // Kiểm tra có phân trang không
      final nextPageUrl = _getNextPageUrl(document, baseUrl);
      if (nextPageUrl != null) {
        print('🔄 FOUND PAGINATION! This story has multiple pages');
        print('📖 Chapters from page 1: ${chapters.length}');
        print('🚀 Starting to scrape additional pages to get ALL chapters...');
        await _scrapeAdditionalPages(nextPageUrl, chapters, storyId, baseUrl);
        print('✅ PAGINATION COMPLETE! Total chapters: ${chapters.length}');
      } else {
        print('📄 Single page story, no pagination needed');
      }

      print('Successfully extracted ${chapters.length} total Syosetu chapters');
      return chapters;
    } catch (e) {
      print('Error extracting Syosetu chapters: $e');
      return chapters;
    }
  }

  // Trích xuất chapters từ trang hiện tại
  Future<void> _extractChaptersFromCurrentPage(dom.Document document, List<Chapter> chapters, String storyId, String baseUrl) async {
    // Tìm tất cả chapter links trong .p-eplist
    final chapterElements = document.querySelectorAll('.p-eplist .p-eplist__sublist');
    print('Found ${chapterElements.length} Syosetu chapters on current page');

    for (final chapterElement in chapterElements) {
      try {
        final chapterLink = chapterElement.querySelector('a.p-eplist__subtitle');
        if (chapterLink == null) continue;

        final chapterTitle = chapterLink.text.trim();
        final chapterUrl = chapterLink.attributes['href'] ?? '';

        if (chapterTitle.isEmpty || chapterUrl.isEmpty) continue;

        // Tạo URL đầy đủ
        final fullChapterUrl = chapterUrl.startsWith('http')
            ? chapterUrl
            : '${Uri.parse(baseUrl).origin}$chapterUrl';

        // Trích xuất thời gian publish từ .p-eplist__update
        final updateElement = chapterElement.querySelector('.p-eplist__update');
        final updateText = updateElement?.text.trim() ?? '';
        final publishedAt = _parseDate(updateText);

        // Tạo chapter ID từ URL
        final chapterId = _generateChapterId(fullChapterUrl);

        final chapter = Chapter(
          id: chapterId,
          storyId: storyId,
          title: chapterTitle,
          url: fullChapterUrl,
          chapterNumber: chapters.length + 1, // Đánh số liên tục
          volumeTitle: '', // Syosetu không có volume
          volumeNumber: 0,
          publishedAt: publishedAt,
          hasImages: false, // Syosetu ít khi có ảnh
          metadata: {
            'scraped_at': DateTime.now().toIso8601String(),
            'scraper_version': '3.0_webview_syosetu_pagination',
            'update_info': updateText,
          },
        );

        chapters.add(chapter);
        print('Added Syosetu chapter: $chapterTitle');
      } catch (e) {
        print('Error processing Syosetu chapter: $e');
      }
    }
  }

  // Lấy URL trang tiếp theo
  String? _getNextPageUrl(dom.Document document, String baseUrl) {
    final nextLink = document.querySelector('.c-pager__item--next[href]');
    if (nextLink != null) {
      final href = nextLink.attributes['href'];
      if (href != null && href.isNotEmpty) {
        final nextUrl = href.startsWith('http')
            ? href
            : '${Uri.parse(baseUrl).origin}$href';
        print('Found next page URL: $nextUrl');
        return nextUrl;
      }
    }
    return null;
  }

  // Scrape các trang bổ sung (chỉ dùng Dio)
  Future<void> _scrapeAdditionalPages(String nextPageUrl, List<Chapter> chapters, String storyId, String baseUrl) async {
    // Chuyển sang dùng Dio ngay từ đầu
    print('🚀 Starting Dio-based pagination scraping from page 2...');
    await _scrapePaginationWithDio(baseUrl, chapters, storyId, 2);
  }

  // Scrape pagination sử dụng Dio (nhanh hơn WebView)
  Future<void> _scrapePaginationWithDio(String baseUrl, List<Chapter> chapters, String storyId, int startPage) async {
    print('🚀 Starting Dio-based pagination scraping from page $startPage...');

    final dio = _createDioInstance();

    int pageNum = startPage;
    const maxPages = 50;

    while (pageNum <= maxPages) {
      try {
        final baseUri = Uri.parse(baseUrl);
        final pageUrl = '${baseUri.origin}${baseUri.path}?p=$pageNum';
        print('📄 Scraping page $pageNum with Dio: $pageUrl');

        final response = await dio.get(pageUrl);
        if (response.statusCode == 200) {
          final document = html_parser.parse(response.data);

          // Kiểm tra có chapters không
          final chapterElements = document.querySelectorAll('.p-eplist .p-eplist__sublist');
          if (chapterElements.isEmpty) {
            print('No chapters found on page $pageNum, pagination complete');
            break;
          }

          final initialCount = chapters.length;
          await _extractChaptersFromCurrentPage(document, chapters, storyId, baseUrl);
          final newChapters = chapters.length - initialCount;
          print('✅ Added $newChapters chapters from page $pageNum (Total: ${chapters.length})');

          // Kiểm tra có trang tiếp theo không
          final nextPageLink = document.querySelector('.c-pager__item--next[href]');
          if (nextPageLink == null) {
            print('No next page link found, pagination complete');
            break;
          }

          pageNum++;

          // Delay ngắn để tránh spam
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          print('HTTP ${response.statusCode} for page $pageNum, stopping');
          break;
        }
      } catch (e) {
        print('Error scraping page $pageNum with Dio: $e');
        // Thử tiếp trang sau
        pageNum++;
        if (pageNum > startPage + 5) {
          // Nếu fail quá 5 trang liên tiếp thì dừng
          print('Too many consecutive failures, stopping Dio pagination');
          break;
        }
      }
    }

    print('🎉 Dio pagination completed! Total chapters: ${chapters.length}');
  }

  // Tạo Dio instance với headers chuẩn
  Dio _createDioInstance() {
    final dio = Dio();
    dio.options.headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'ja,en-US;q=0.7,en;q=0.3',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };
    return dio;
  }

  // Scrape từ Syosetu với chapters sử dụng Dio (nhanh và ổn định)
  Future<Map<String, dynamic>?> scrapeStoryWithChaptersDio(String url, {bool scrapeContent = false}) async {
    try {
      print('🚀 Starting Syosetu scraping with Dio for: $url');

      final dio = _createDioInstance();

      // Scrape trang đầu tiên
      print('📄 Fetching page 1...');
      final response = await dio.get(url);
      if (response.statusCode != 200) {
        print('❌ HTTP ${response.statusCode} for main page');
        return null;
      }

      final document = html_parser.parse(response.data);
      print('✅ Page 1 parsed successfully');

      // Trích xuất story info và chapters
      final result = await _extractStoryWithChaptersFromDocument(document, url, scrapeContent: scrapeContent);
      if (result == null) {
        print('❌ Failed to extract story information');
        return null;
      }

      print('🎉 Syosetu scraping completed successfully!');
      return result;

    } catch (e, stackTrace) {
      print('❌ Error in Syosetu Dio scraping: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }



  // Trích xuất tiêu đề từ Syosetu
  String _extractTitle(dom.Document document) {
    print('DEBUG: Looking for Syosetu title...');

    // Debug: Tìm tất cả elements có class chứa "novel"
    final novelElements = document.querySelectorAll('[class*="novel"]');
    print('DEBUG: Found ${novelElements.length} elements with "novel" in class');
    for (int i = 0; i < novelElements.length && i < 5; i++) {
      final element = novelElements[i];
      print('DEBUG: Novel element $i: ${element.className} - ${element.text.trim().substring(0, element.text.trim().length.clamp(0, 50))}');
    }

    // Tìm tiêu đề trong .p-novel__title
    final titleElement = document.querySelector('.p-novel__title');
    print('DEBUG: .p-novel__title found: ${titleElement != null}');
    if (titleElement != null) {
      final title = titleElement.text.trim();
      print('DEBUG: Title from .p-novel__title: "$title"');
      if (title.isNotEmpty) {
        return title;
      }
    }

    // Thử tìm với h1.p-novel__title
    final h1TitleElement = document.querySelector('h1.p-novel__title');
    print('DEBUG: h1.p-novel__title found: ${h1TitleElement != null}');
    if (h1TitleElement != null) {
      final title = h1TitleElement.text.trim();
      print('DEBUG: Title from h1.p-novel__title: "$title"');
      if (title.isNotEmpty) {
        return title;
      }
    }

    // Thử lấy từ title tag
    final titleTag = document.querySelector('title');
    print('DEBUG: title tag found: ${titleTag != null}');
    if (titleTag != null) {
      final titleText = titleTag.text.trim();
      print('DEBUG: Title tag content: "$titleText"');
      // Loại bỏ phần " - 小説家になろう" ở cuối
      final cleanTitle = titleText.replaceAll(
        RegExp(r' - 小説家になろう.*$'),
        '',
      );
      if (cleanTitle.isNotEmpty) {
        return cleanTitle;
      }
    }

    print('DEBUG: No Syosetu title found');
    return '';
  }

  // Trích xuất tác giả từ Syosetu
  String _extractAuthor(dom.Document document) {
    // Tìm tác giả trong .p-novel__author
    final authorElement = document.querySelector('.p-novel__author a');
    if (authorElement != null) {
      return authorElement.text.trim();
    }

    // Thử tìm trong text của .p-novel__author
    final authorDiv = document.querySelector('.p-novel__author');
    if (authorDiv != null) {
      final authorText = authorDiv.text.trim();
      // Loại bỏ "作者：" ở đầu
      final cleanAuthor = authorText.replaceAll(RegExp(r'^作者：'), '');
      if (cleanAuthor.isNotEmpty) {
        return cleanAuthor;
      }
    }

    return 'Không rõ';
  }

  // Trích xuất mô tả từ Syosetu
  String _extractDescription(dom.Document document) {
    // Tìm phần tóm tắt trong #novel_ex hoặc .p-novel__summary
    final summaryElement = document.querySelector('#novel_ex') ??
                          document.querySelector('.p-novel__summary');

    if (summaryElement != null) {
      // Lấy text và xử lý các thẻ <br>
      final htmlContent = summaryElement.innerHtml;
      final cleanContent = htmlContent
          .replaceAll('<br>', '\n')
          .replaceAll('<br/>', '\n')
          .replaceAll('<br />', '\n');

      // Parse lại để lấy text thuần
      final tempDoc = html_parser.parseFragment(cleanContent);
      final description = tempDoc.text?.trim() ?? '';

      if (description.isNotEmpty) {
        return description;
      }
    }

    return '';
  }

  // Scrape nội dung của các chapters
  Future<void> _scrapeChapterContents(List<Chapter> chapters) async {
    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      print('Scraping Syosetu content for chapter ${i + 1}/${chapters.length}: ${chapter.title}');

      try {
        final content = await scrapeChapterContent(chapter.url);
        if (content.isNotEmpty) {
          chapters[i] = chapter.copyWith(
            content: content,
            wordCount: _countWords(content),
          );
          print('Successfully scraped Syosetu content for: ${chapter.title}');
        } else {
          print('No Syosetu content found for: ${chapter.title}');
        }
      } catch (e) {
        print('Error scraping Syosetu content for ${chapter.title}: $e');
      }

      // Delay để tránh spam requests
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  // Scrape nội dung của một chapter sử dụng Dio
  Future<String> scrapeChapterContent(String chapterUrl) async {
    try {
      print('📄 Scraping chapter content with Dio: $chapterUrl');
      final dio = _createDioInstance();

      final response = await dio.get(chapterUrl);
      if (response.statusCode != 200) {
        print('❌ HTTP ${response.statusCode} for chapter: $chapterUrl');
        return '';
      }

      final document = html_parser.parse(response.data);
      final content = _extractChapterContentFromDocument(document);

      if (content.isNotEmpty) {
        print('✅ Successfully scraped chapter content (${content.length} chars)');
      } else {
        print('⚠️ No content found for chapter');
      }

      return content;
    } catch (e) {
      print('❌ Error scraping Syosetu chapter content: $e');
      return '';
    }
  }

  // Trích xuất nội dung chapter từ document
  String _extractChapterContentFromDocument(dom.Document document) {
    try {
      // Tìm content container cho Syosetu - cấu trúc mới
      final contentElement = document.querySelector('.p-novel__text') ??
                            document.querySelector('#novel_honbun') ??
                            document.querySelector('.novel_view') ??
                            document.querySelector('#honbun');

      if (contentElement != null) {
        // Lấy tất cả thẻ p và xử lý
        final paragraphs = contentElement.querySelectorAll('p');
        final contentLines = <String>[];

        for (final p in paragraphs) {
          final text = p.text.trim();
          if (text.isNotEmpty) {
            contentLines.add(text);
          } else {
            // Thêm dòng trống cho <br> hoặc <p> rỗng
            contentLines.add('');
          }
        }

        final content = contentLines.join('\n');
        print('📖 Extracted chapter content: ${content.length} chars, ${paragraphs.length} paragraphs');
        return content;
      }

      // Fallback: lấy toàn bộ text trong .p-novel__body
      final bodyElement = document.querySelector('.p-novel__body');
      if (bodyElement != null) {
        final content = bodyElement.text.trim();
        print('📖 Fallback extracted content: ${content.length} chars');
        return content;
      }

      print('❌ No content container found');
      return '';
    } catch (e) {
      print('❌ Error extracting chapter content: $e');
      return '';
    }
  }

  // Utility methods
  DateTime _parseDate(String dateText) {
    try {
      // Xử lý format date của Syosetu: "2025/06/08 19:39"
      if (dateText.contains('/') && dateText.contains(' ')) {
        final parts = dateText.split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];

          final dateComponents = datePart.split('/');
          final timeComponents = timePart.split(':');

          if (dateComponents.length == 3 && timeComponents.length >= 2) {
            final year = int.parse(dateComponents[0]);
            final month = int.parse(dateComponents[1]);
            final day = int.parse(dateComponents[2]);
            final hour = int.parse(timeComponents[0]);
            final minute = int.parse(timeComponents[1]);

            return DateTime(year, month, day, hour, minute);
          }
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

    // Lấy ID từ URL Syosetu (ví dụ: n1706ko)
    for (final segment in pathSegments) {
      if (RegExp(r'^n\d+[a-z]+$').hasMatch(segment)) {
        return '${uri.host}_$segment';
      }
    }

    // Fallback: sử dụng hash của URL
    return '${uri.host}_${url.hashCode.abs()}';
  }

  String _generateChapterId(String url) {
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments;

    // Tìm segment chứa chapter ID (ví dụ: n1706ko/1/)
    if (pathSegments.length >= 2) {
      final storyId = pathSegments[0];
      final chapterNum = pathSegments[1];
      if (RegExp(r'^n\d+[a-z]+$').hasMatch(storyId) && RegExp(r'^\d+$').hasMatch(chapterNum)) {
        return '${uri.host}_${storyId}_c$chapterNum';
      }
    }

    // Fallback: sử dụng hash của URL
    return '${uri.host}_chapter_${url.hashCode.abs()}';
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    // Đếm ký tự cho tiếng Nhật thay vì từ
    return text.trim().length;
  }
}
