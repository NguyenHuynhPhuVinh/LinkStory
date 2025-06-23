import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:iconsax/iconsax.dart';

import '../controllers/home_controller.dart';
import '../../library/views/library_view.dart';
import '../../reader/views/reader_view.dart';
import '../../history/views/history_view.dart';
import '../../settings/views/settings_view.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: const [
          LibraryView(),
          ReaderView(),
          HistoryView(),
          SettingsView(),
        ],
      )),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: Obx(() => GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.black,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: const [
                GButton(
                  icon: Iconsax.book,
                  text: 'Thư viện',
                ),
                GButton(
                  icon: Iconsax.book_1,
                  text: 'Đọc truyện',
                ),
                GButton(
                  icon: Iconsax.clock,
                  text: 'Lịch sử',
                ),
                GButton(
                  icon: Iconsax.setting_2,
                  text: 'Cài đặt',
                ),
              ],
              selectedIndex: controller.currentIndex.value,
              onTabChange: (index) {
                controller.changeTabIndex(index);
              },
            )),
          ),
        ),
      ),
    );
  }
}
