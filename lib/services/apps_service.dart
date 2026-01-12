import 'package:device_apps/device_apps.dart';

class AppInfo {
  final String packageName;
  final String appName;
  final String? icon;

  AppInfo({
    required this.packageName,
    required this.appName,
    this.icon,
  });
}

class AppsService {
  // Get all installed apps (non-system apps)
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final apps = await DeviceApps.getInstalledApplications(
        includeAppIcons: true,
        includeSystemApps: false,
        onlyAppsWithLaunchIntent: true,
      );

      return apps.map((app) {
        return AppInfo(
          packageName: app.packageName,
          appName: app.appName,
          icon: app is ApplicationWithIcon ? app.icon.toString() : null,
        );
      }).toList()
        ..sort((a, b) => a.appName.compareTo(b.appName));
    } catch (e) {
      print('Error getting installed apps: $e');
      return [];
    }
  }

  // Get app name from package name
  Future<String?> getAppName(String packageName) async {
    try {
      final app = await DeviceApps.getApp(packageName);
      return app?.appName;
    } catch (e) {
      return null;
    }
  }
}

final appsService = AppsService();
