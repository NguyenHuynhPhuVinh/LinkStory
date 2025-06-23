import 'package:hive/hive.dart';
import '../models/website_model.dart';

class WebsiteService {
  static const String _boxName = 'websites';
  Box<Website>? _websiteBox;

  // Singleton pattern
  static final WebsiteService _instance = WebsiteService._internal();
  factory WebsiteService() => _instance;
  WebsiteService._internal();

  // Initialize service
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(WebsiteAdapter());
    }
    _websiteBox = await Hive.openBox<Website>(_boxName);

    // Thêm dữ liệu mặc định nếu chưa có
    if (_websiteBox!.isEmpty) {
      await _addDefaultWebsites();
    }
  }

  // Thêm các website mặc định
  Future<void> _addDefaultWebsites() async {
    final defaultWebsites = [
      Website(
        id: 'hako_ln',
        name: 'Hako Light Novel',
        url: 'https://docln.sbs/',
        iconUrl: 'https://docln.sbs/img/favicon.png?v=3',
        description: 'Website đọc light novel tiếng Việt',
      ),
      Website(
        id: 'syosetu',
        name: 'Syosetu',
        url: 'https://syosetu.com/',
        iconUrl: 'https://syosetu.com/favicon.ico',
        description: 'Website light novel Nhật Bản',
      ),
    ];

    for (final website in defaultWebsites) {
      await _websiteBox!.put(website.id, website);
    }
  }

  // Lấy tất cả websites
  List<Website> getAllWebsites() {
    return _websiteBox?.values.where((website) => website.isActive).toList() ??
        [];
  }

  // Lấy website theo ID
  Website? getWebsiteById(String id) {
    return _websiteBox?.get(id);
  }

  // Thêm website mới
  Future<void> addWebsite(Website website) async {
    await _websiteBox?.put(website.id, website);
  }

  // Cập nhật website
  Future<void> updateWebsite(Website website) async {
    final updatedWebsite = website.copyWith(updatedAt: DateTime.now());
    await _websiteBox?.put(website.id, updatedWebsite);
  }

  // Xóa website (soft delete)
  Future<void> deleteWebsite(String id) async {
    final website = _websiteBox?.get(id);
    if (website != null) {
      final updatedWebsite = website.copyWith(
        isActive: false,
        updatedAt: DateTime.now(),
      );
      await _websiteBox?.put(id, updatedWebsite);
    }
  }

  // Xóa website hoàn toàn
  Future<void> permanentDeleteWebsite(String id) async {
    await _websiteBox?.delete(id);
  }

  // Kiểm tra website có tồn tại không
  bool websiteExists(String id) {
    return _websiteBox?.containsKey(id) ?? false;
  }

  // Lấy số lượng websites
  int getWebsiteCount() {
    return _websiteBox?.values.where((website) => website.isActive).length ?? 0;
  }

  // Tìm kiếm websites
  List<Website> searchWebsites(String query) {
    if (query.isEmpty) return getAllWebsites();

    return _websiteBox?.values
            .where(
              (website) =>
                  website.isActive &&
                  (website.name.toLowerCase().contains(query.toLowerCase()) ||
                      website.description.toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      website.url.toLowerCase().contains(query.toLowerCase())),
            )
            .toList() ??
        [];
  }

  // Đóng service
  Future<void> close() async {
    await _websiteBox?.close();
  }
}
