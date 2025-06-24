import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'firebase_config_service.dart';

class TranslationService {
  // Singleton pattern
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  late GenerativeModel _model;
  bool _isInitialized = false;
  final FirebaseConfigService _configService = FirebaseConfigService();

  // Define JSON schema for structured translation output
  static final _translationSchema = Schema.object(
    properties: {
      'title': Schema.string(),
      'author': Schema.string(),
      'description': Schema.string(),
      'genres': Schema.array(items: Schema.string()),
      'success': Schema.boolean(),
      'message': Schema.string(),
    },
    optionalProperties: ['message'],
  );

  // Initialize the service
  Future<void> init() async {
    try {
      // Initialize config service first
      await _configService.init();

      // Configure safety settings to allow all content for translation
      final safetySettings = [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none, null),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none, null),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.none,
          null,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.none,
          null,
        ),
      ];

      // Initialize the Gemini Developer API backend service with structured output
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system(_getSystemInstruction()),
        safetySettings: safetySettings,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: _translationSchema,
          temperature:
              0.2, // Very low temperature for consistent, deterministic translations
          topP: 0.8, // Focus on high-probability tokens for accuracy
          topK: 40, // Limit vocabulary for more focused translations
          maxOutputTokens: 2048,
        ),
      );
      _isInitialized = true;
      print(
        '✅ Translation Service initialized successfully with structured output and safety settings disabled',
      );
    } catch (e) {
      print('❌ Error initializing Translation Service: $e');
      _isInitialized = false;
    }
  }

  // Get system instruction for translation
  String _getSystemInstruction() {
    return '''
Bạn là một chuyên gia dịch thuật chuyên nghiệp với 10+ năm kinh nghiệm dịch light novel và web novel từ tiếng Nhật sang tiếng Việt.

CHUYÊN MÔN:
- Thành thạo cả tiếng Nhật và tiếng Việt ở mức độ bản ngữ
- Hiểu sâu văn hóa và ngôn ngữ của cả hai nước
- Chuyên gia về các thể loại: isekai, romance, fantasy, slice of life, comedy, drama
- Nắm vững thuật ngữ và cách diễn đạt trong cộng đồng đọc truyện Việt Nam

NGUYÊN TẮC DỊCH:
1. TIÊU ĐỀ:
   - Dịch hấp dẫn, catchy, dễ nhớ
   - Giữ nguyên ý nghĩa nhưng có thể điều chỉnh để phù hợp văn hóa Việt
   - Có thể thêm phụ đề hoặc ghi chú làm rõ nội dung
   - Tránh dịch quá dài hoặc khó hiểu

2. TÁC GIẢ:
   - Giữ nguyên tên tiếng Nhật (romanized)
   - Không dịch tên riêng của tác giả

3. MÔ TẢ:
   - Dịch tự nhiên, mượt mà như người Việt viết
   - Sử dụng từ ngữ phù hợp với độ tuổi và thể loại
   - Giữ nguyên tone và cảm xúc của bản gốc
   - Tránh từ ngữ cứng nhắc, dịch máy

4. THỂ LOẠI:
   - Sử dụng thuật ngữ chuẩn trong cộng đồng: "Isekai", "Romance", "Harem", "Slice of Life"
   - Dịch các thể loại phổ biến: "学園" → "Học đường", "恋愛" → "Romance"
   - Giữ nguyên các thuật ngữ đã được cộng đồng chấp nhận

CHẤT LƯỢNG:
- Ưu tiên độ tự nhiên và dễ đọc
- Đảm bảo bản dịch không mất ý nghĩa gốc
- Sử dụng ngôn ngữ phù hợp với từng thể loại truyện
- Tránh lặp từ không cần thiết

ĐỊNH DẠNG ĐẦU RA:
- Luôn trả về JSON hợp lệ với đầy đủ các trường
- success: true (luôn luôn, trừ khi có lỗi nghiêm trọng)
- Đảm bảo tất cả các trường đều có giá trị hợp lệ
''';
  }

  // Check if service is ready
  bool get isReady => _isInitialized;

  // Translate story information to Vietnamese using structured output
  Future<Map<String, String>?> translateStoryInfo({
    required String title,
    required String author,
    required String description,
    List<String> genres = const [],
  }) async {
    if (!_isInitialized) {
      print('❌ Translation Service not initialized');
      return null;
    }

    try {
      // Create a structured prompt for translation
      final prompt = _buildStructuredPrompt(
        title: title,
        author: author,
        description: description,
        genres: genres,
      );

      print('🔄 Translating story info with structured output...');
      final response = await _model.generateContent([Content.text(prompt)]);

      if (response.text == null) {
        print('❌ No response from translation service');
        return null;
      }

      // Parse the structured JSON response
      final translatedInfo = _parseStructuredResponse(response.text!);

      if (translatedInfo != null) {
        print('✅ Translation completed successfully');
        return translatedInfo;
      } else {
        print('❌ Failed to parse structured translation response');
        return null;
      }
    } catch (e) {
      print('❌ Error during translation: $e');
      return null;
    }
  }

  // Build structured prompt for translation
  String _buildStructuredPrompt({
    required String title,
    required String author,
    required String description,
    List<String> genres = const [],
  }) {
    final genresText = genres.isNotEmpty
        ? 'Thể loại: ${genres.join(', ')}'
        : 'Không có thông tin thể loại';

    return '''
Hãy dịch thông tin truyện sau từ tiếng Nhật sang tiếng Việt:

THÔNG TIN TRUYỆN GỐC:
📖 Tiêu đề: $title
✍️ Tác giả: $author
📝 Mô tả: $description
🏷️ $genresText

HƯỚNG DẪN DỊCH:
- Tiêu đề: Dịch hấp dẫn, có thể thêm phụ đề làm rõ nội dung
- Tác giả: Giữ nguyên tên Nhật, có thể romanize nếu cần
- Mô tả: Dịch tự nhiên, sử dụng từ ngữ phù hợp độ tuổi
- Thể loại: Sử dụng thuật ngữ quen thuộc trong cộng đồng

Đảm bảo bản dịch tự nhiên và phù hợp văn hóa Việt Nam.
''';
  }

  // Parse structured JSON response
  Map<String, String>? _parseStructuredResponse(String response) {
    try {
      print(
        '📄 Raw response: ${response.substring(0, response.length > 200 ? 200 : response.length)}...',
      );

      // Parse JSON directly (no need to clean since it's structured output)
      final Map<String, dynamic> parsed = jsonDecode(response);

      // Check if translation was successful
      if (parsed['success'] == false) {
        print('❌ Translation failed: ${parsed['message'] ?? 'Unknown error'}');
        return null;
      }

      // Validate required fields
      if (parsed['title'] == null ||
          parsed['author'] == null ||
          parsed['description'] == null) {
        print('❌ Missing required fields in translation response');
        return null;
      }

      // Convert to Map<String, String>
      final result = <String, String>{};

      result['title'] = parsed['title'].toString().trim();
      result['author'] = parsed['author'].toString().trim();
      result['description'] = parsed['description'].toString().trim();

      // Handle genres array
      if (parsed['genres'] != null && parsed['genres'] is List) {
        final genresList = (parsed['genres'] as List)
            .map((e) => e.toString().trim())
            .where((genre) => genre.isNotEmpty)
            .toList();
        result['genres'] = genresList.join(',');
      } else {
        result['genres'] = '';
      }

      print('✅ Parsed translation: ${result['title']}');
      return result;
    } catch (e) {
      print('❌ Error parsing structured response: $e');
      print('Response was: $response');
      return null;
    }
  }

  // Translate chapter content and title
  Future<Map<String, String>?> translateChapter({
    required String title,
    required String content,
  }) async {
    if (!_isInitialized) {
      print('❌ Translation Service not initialized');
      return null;
    }

    try {
      // Configure safety settings for chapter translation
      final safetySettings = [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none, null),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none, null),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.none,
          null,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.none,
          null,
        ),
      ];

      // Create model for chapter translation
      final chapterModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system(
          'Bạn là chuyên gia dịch light novel từ tiếng Nhật sang tiếng Việt. '
          'Hãy dịch cả tiêu đề và nội dung chương một cách tự nhiên, giữ nguyên format và cấu trúc. '
          'Sử dụng thuật ngữ phù hợp với thể loại light novel. '
          'Trả về JSON với format: {"title": "tiêu đề đã dịch", "content": "nội dung đã dịch"}',
        ),
        safetySettings: safetySettings,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.2,
          topP: 0.8,
          topK: 40,
          maxOutputTokens: 8192, // Tăng limit cho nội dung dài
        ),
      );

      print('🔄 Translating chapter: $title');

      // Chia nhỏ nội dung nếu quá dài
      if (content.length > 10000) {
        return await _translateLongChapter(chapterModel, title, content);
      }

      final prompt =
          '''
Dịch tiêu đề và nội dung chương sau từ tiếng Nhật sang tiếng Việt:

TIÊU ĐỀ: $title

NỘI DUNG:
$content

Hãy dịch tự nhiên và giữ nguyên format. Trả về JSON với format chính xác.
''';

      final response = await chapterModel.generateContent([
        Content.text(prompt),
      ]);

      if (response.text == null) {
        print('❌ No response from chapter translation service');
        return null;
      }

      final result = _parseChapterTranslationResponse(response.text!);
      if (result != null) {
        print('✅ Chapter translation completed successfully');
        return result;
      } else {
        print('❌ Failed to parse chapter translation response');
        return null;
      }
    } catch (e) {
      print('❌ Error during chapter translation: $e');
      return null;
    }
  }

  // Quick translate method for single text (using simple text model)
  Future<String?> translateText(
    String text, {
    String targetLanguage = 'Vietnamese',
  }) async {
    if (!_isInitialized) {
      print('❌ Translation Service not initialized');
      return null;
    }

    try {
      // Configure safety settings for text translation
      final safetySettings = [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none, null),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none, null),
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.none,
          null,
        ),
        SafetySetting(
          HarmCategory.dangerousContent,
          HarmBlockThreshold.none,
          null,
        ),
      ];

      // Create a simple model for text translation (without JSON schema)
      final textModel = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system(
          'Bạn là chuyên gia dịch thuật. Dịch text từ tiếng Nhật sang tiếng Việt một cách tự nhiên và chính xác. '
          'Chỉ trả về kết quả dịch, không thêm giải thích.',
        ),
        safetySettings: safetySettings,
        generationConfig: GenerationConfig(
          temperature: 0.2, // Low temperature for consistent translations
          topP: 0.8, // Focus on high-probability tokens
          topK: 40, // Limit vocabulary for focused output
          maxOutputTokens: 1024,
        ),
      );

      final prompt = 'Dịch sang tiếng Việt: "$text"';
      final response = await textModel.generateContent([Content.text(prompt)]);

      return response.text?.trim();
    } catch (e) {
      print('❌ Error translating text: $e');
      return null;
    }
  }

  // Translate long chapter by splitting into chunks
  Future<Map<String, String>?> _translateLongChapter(
    GenerativeModel model,
    String title,
    String content,
  ) async {
    try {
      print('📄 Translating long chapter in chunks...');

      // Dịch tiêu đề trước
      final titlePrompt =
          'Dịch tiêu đề chương này từ tiếng Nhật sang tiếng Việt: "$title"';
      final titleResponse = await model.generateContent([
        Content.text(titlePrompt),
      ]);
      final translatedTitle =
          titleResponse.text?.trim().replaceAll('"', '') ?? title;

      // Chia nội dung thành các đoạn
      final chunks = _splitContentIntoChunks(content, 8000);
      final translatedChunks = <String>[];

      for (int i = 0; i < chunks.length; i++) {
        print('🔄 Translating chunk ${i + 1}/${chunks.length}');

        final chunkPrompt =
            '''
Dịch đoạn văn sau từ tiếng Nhật sang tiếng Việt. Giữ nguyên format và cấu trúc:

${chunks[i]}

Chỉ trả về nội dung đã dịch, không thêm giải thích.
''';

        final chunkResponse = await model.generateContent([
          Content.text(chunkPrompt),
        ]);
        if (chunkResponse.text != null) {
          translatedChunks.add(chunkResponse.text!.trim());
        } else {
          translatedChunks.add(
            chunks[i],
          ); // Fallback to original if translation fails
        }

        // Delay nhỏ để tránh rate limit
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final translatedContent = translatedChunks.join('\n\n');

      return {'title': translatedTitle, 'content': translatedContent};
    } catch (e) {
      print('❌ Error translating long chapter: $e');
      return null;
    }
  }

  // Split content into manageable chunks
  List<String> _splitContentIntoChunks(String content, int maxChunkSize) {
    final chunks = <String>[];
    final paragraphs = content.split('\n');

    String currentChunk = '';
    for (final paragraph in paragraphs) {
      if (currentChunk.length + paragraph.length + 1 > maxChunkSize) {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk.trim());
          currentChunk = paragraph;
        } else {
          // Paragraph itself is too long, split it
          chunks.add(paragraph);
        }
      } else {
        if (currentChunk.isNotEmpty) {
          currentChunk += '\n$paragraph';
        } else {
          currentChunk = paragraph;
        }
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk.trim());
    }

    return chunks;
  }

  // Parse chapter translation response
  Map<String, String>? _parseChapterTranslationResponse(String response) {
    try {
      final jsonResponse = json.decode(response);
      if (jsonResponse is Map<String, dynamic>) {
        return {
          'title': jsonResponse['title']?.toString() ?? '',
          'content': jsonResponse['content']?.toString() ?? '',
        };
      }
    } catch (e) {
      print('❌ Error parsing chapter translation response: $e');
    }
    return null;
  }
}
