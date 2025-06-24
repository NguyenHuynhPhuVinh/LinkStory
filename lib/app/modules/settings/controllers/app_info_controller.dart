import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppInfoController extends GetxController {
  // Observable app info
  final RxString appName = ''.obs;
  final RxString packageName = ''.obs;
  final RxString version = ''.obs;
  final RxString buildNumber = ''.obs;
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      isLoading.value = true;
      
      final packageInfo = await PackageInfo.fromPlatform();
      
      appName.value = packageInfo.appName;
      packageName.value = packageInfo.packageName;
      version.value = packageInfo.version;
      buildNumber.value = packageInfo.buildNumber;
      
    } catch (e) {
      print('❌ Error loading app info: $e');
      // Set default values if package info fails
      appName.value = 'LinkStory';
      packageName.value = 'com.tomisakae.linkstory';
      version.value = '1.0.0';
      buildNumber.value = '1';
    } finally {
      isLoading.value = false;
    }
  }

  // Get formatted version string
  String get formattedVersion => '${version.value} (${buildNumber.value})';

  // App info data for display
  List<AppInfoItem> get appInfoItems => [
    AppInfoItem(
      label: 'Tên ứng dụng',
      value: appName.value,
      icon: 'app',
    ),
    AppInfoItem(
      label: 'Phiên bản',
      value: formattedVersion,
      icon: 'version',
    ),
    AppInfoItem(
      label: 'Package Name',
      value: packageName.value,
      icon: 'package',
    ),
    AppInfoItem(
      label: 'Nhà phát triển',
      value: 'TomiSakae',
      icon: 'developer',
    ),
    AppInfoItem(
      label: 'Ngôn ngữ',
      value: 'Tiếng Việt',
      icon: 'language',
    ),
    AppInfoItem(
      label: 'Framework',
      value: 'Flutter',
      icon: 'framework',
    ),
  ];
}

class AppInfoItem {
  final String label;
  final String value;
  final String icon;

  AppInfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });
}
