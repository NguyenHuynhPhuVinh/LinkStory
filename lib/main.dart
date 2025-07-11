import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/routes/app_pages.dart';
import 'app/data/models/website_model.dart';
import 'app/data/models/story_model.dart';
import 'app/data/models/reading_history_model.dart';
import 'app/data/models/chat_message_model.dart';
import 'app/data/models/chat_conversation_model.dart';
import 'app/data/services/theme_service.dart';
import 'app/data/services/history_service.dart';
import 'app/bindings/initial_binding.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(WebsiteAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(StoryAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(ReadingHistoryAdapter());
  }
  if (!Hive.isAdapterRegistered(4)) {
    Hive.registerAdapter(ReadingActionAdapter());
  }
  // Chat models adapters
  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(ChatMessageAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(ChatMessageRoleAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(ChatMessageStatusAdapter());
  }
  if (!Hive.isAdapterRegistered(13)) {
    Hive.registerAdapter(ChatConversationAdapter());
  }
  if (!Hive.isAdapterRegistered(14)) {
    Hive.registerAdapter(ConversationStatusAdapter());
  }

  // Initialize core services
  InitialBinding().dependencies();

  // Initialize services that need async setup
  await Get.find<ThemeService>().onInit();
  await Get.find<HistoryService>().onInit();

  runApp(const LinkStoryApp());
}

class LinkStoryApp extends StatelessWidget {
  const LinkStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Obx(() => GetMaterialApp(
          key: ValueKey('${ThemeService.to.themeMode.value}_${ThemeService.to.rebuildTrigger.value}'),
          title: 'LinkStory',
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: ThemeService.to.themeMode.value,
          initialRoute: AppPages.INITIAL,
          getPages: AppPages.routes,
          initialBinding: InitialBinding(),
          debugShowCheckedModeBanner: false,
        ));
      },
    );
  }
}


