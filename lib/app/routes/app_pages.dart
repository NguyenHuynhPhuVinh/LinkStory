import 'package:get/get.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/library/bindings/library_binding.dart';
import '../modules/library/views/library_view.dart';
import '../modules/reader/bindings/reader_binding.dart';
import '../modules/reader/views/reader_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/history_view.dart';
import '../modules/settings/bindings/settings_binding.dart';
import '../modules/settings/views/settings_view.dart';
import '../modules/settings/bindings/firebase_settings_binding.dart';
import '../modules/settings/views/firebase_settings_view.dart';
import '../modules/settings/bindings/app_info_binding.dart';
import '../modules/settings/views/app_info_view.dart';
import '../modules/ai/bindings/ai_binding.dart';
import '../modules/ai/views/ai_view.dart';
import '../modules/webview/bindings/webview_binding.dart';
import '../modules/webview/views/webview_view.dart';
import '../modules/story_detail/bindings/story_detail_binding.dart';
import '../modules/story_detail/views/story_detail_view.dart';
import '../modules/reading/bindings/reading_binding.dart';
import '../modules/reading/views/reading_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LIBRARY,
      page: () => const LibraryView(),
      binding: LibraryBinding(),
    ),
    GetPage(
      name: _Paths.READER,
      page: () => const ReaderView(),
      binding: ReaderBinding(),
    ),
    GetPage(
      name: _Paths.HISTORY,
      page: () => const HistoryView(),
      binding: HistoryBinding(),
    ),
    GetPage(
      name: _Paths.SETTINGS,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
    ),
    GetPage(
      name: _Paths.FIREBASE_SETTINGS,
      page: () => const FirebaseSettingsView(),
      binding: FirebaseSettingsBinding(),
    ),
    GetPage(
      name: _Paths.APP_INFO,
      page: () => const AppInfoView(),
      binding: AppInfoBinding(),
    ),
    GetPage(name: _Paths.AI, page: () => const AiView(), binding: AiBinding()),
    GetPage(
      name: _Paths.WEBVIEW,
      page: () => const WebViewView(),
      binding: WebViewBinding(),
    ),
    GetPage(
      name: _Paths.STORY_DETAIL,
      page: () => const StoryDetailView(),
      binding: StoryDetailBinding(),
    ),
    GetPage(
      name: _Paths.READING,
      page: () => const ReadingView(),
      binding: ReadingBinding(),
    ),
  ];
}
