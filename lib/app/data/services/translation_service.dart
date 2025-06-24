import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:get/get.dart';
import 'firebase_config_service.dart';

class TranslationService {
  // Singleton pattern
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  late GenerativeModel _model;
  bool _isInitialized = false;
  final FirebaseConfigService _configService = FirebaseConfigService();

  // Initialize the service
  Future<void> init() async {
    try {
      // Initialize config service first
      await _configService.init();

      // Initialize the Gemini Developer API backend service
      _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
      _isInitialized = true;
      print('✅ Translation Service initialized successfully with API key: ${_configService.apiKey.substring(0, 20)}...');
    } catch (e) {
      print('❌ Error initializing Translation Service: $e');
      _isInitialized = false;
    }
  }

  // Check if service is ready
  bool get isReady => _isInitialized;

  // Translate story information to Vietnamese
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
      // Create a comprehensive prompt for translation
      final prompt = _buildTranslationPrompt(
        title: title,
        author: author,
        description: description,
        genres: genres,
      );

      print('🔄 Translating story info...');
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text == null) {
        print('❌ No response from translation service');
        return null;
      }

      // Parse the response
      final translatedInfo = _parseTranslationResponse(response.text!);
      
      if (translatedInfo != null) {
        print('✅ Translation completed successfully');
        return translatedInfo;
      } else {
        print('❌ Failed to parse translation response');
        return null;
      }
    } catch (e) {
      print('❌ Error during translation: $e');
      return null;
    }
  }

  // Build translation prompt
  String _buildTranslationPrompt({
    required String title,
    required String author,
    required String description,
    List<String> genres = const [],
  }) {
    final genresText = genres.isNotEmpty ? '\nThể loại: ${genres.join(', ')}' : '';
    
    return '''
Bạn là một chuyên gia dịch thuật chuyên dịch thông tin truyện từ tiếng Nhật sang tiếng Việt. 
Hãy dịch thông tin truyện sau đây một cách chính xác và tự nhiên:

THÔNG TIN GỐC:
Tiêu đề: $title
Tác giả: $author
Mô tả: $description$genresText

YÊU CẦU:
1. Dịch tiêu đề sao cho phù hợp với văn hóa Việt Nam nhưng vẫn giữ nguyên ý nghĩa
2. Dịch tên tác giả (nếu có thể) hoặc giữ nguyên nếu là tên riêng
3. Dịch mô tả một cách tự nhiên, dễ hiểu
4. Dịch các thể loại nếu có
5. Trả về kết quả theo định dạng JSON chính xác như sau:

{
  "title": "Tiêu đề đã dịch",
  "author": "Tác giả đã dịch", 
  "description": "Mô tả đã dịch",
  "genres": ["Thể loại 1", "Thể loại 2"]
}

CHÚ Ý: Chỉ trả về JSON, không thêm bất kỳ text nào khác.
''';
  }

  // Parse translation response
  Map<String, String>? _parseTranslationResponse(String response) {
    try {
      // Clean the response to extract JSON
      String cleanResponse = response.trim();
      
      // Remove markdown code blocks if present
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      
      cleanResponse = cleanResponse.trim();
      
      // Find JSON object
      int startIndex = cleanResponse.indexOf('{');
      int endIndex = cleanResponse.lastIndexOf('}');
      
      if (startIndex == -1 || endIndex == -1 || startIndex >= endIndex) {
        print('❌ No valid JSON found in response');
        return null;
      }
      
      String jsonString = cleanResponse.substring(startIndex, endIndex + 1);
      
      // Parse JSON
      final Map<String, dynamic> parsed = 
          Map<String, dynamic>.from(jsonDecode(jsonString));
      
      // Convert to Map<String, String>
      final result = <String, String>{};
      
      if (parsed['title'] != null) {
        result['title'] = parsed['title'].toString();
      }
      if (parsed['author'] != null) {
        result['author'] = parsed['author'].toString();
      }
      if (parsed['description'] != null) {
        result['description'] = parsed['description'].toString();
      }
      
      // Handle genres array
      if (parsed['genres'] != null && parsed['genres'] is List) {
        final genresList = (parsed['genres'] as List)
            .map((e) => e.toString())
            .toList();
        result['genres'] = genresList.join(',');
      }
      
      return result;
    } catch (e) {
      print('❌ Error parsing translation response: $e');
      print('Response was: $response');
      return null;
    }
  }

  // Quick translate method for single text
  Future<String?> translateText(String text, {String targetLanguage = 'Vietnamese'}) async {
    if (!_isInitialized) {
      print('❌ Translation Service not initialized');
      return null;
    }

    try {
      final prompt = '''
Dịch đoạn text sau sang tiếng Việt một cách tự nhiên và chính xác:

"$text"

Chỉ trả về kết quả dịch, không thêm bất kỳ text nào khác.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim();
    } catch (e) {
      print('❌ Error translating text: $e');
      return null;
    }
  }
}
