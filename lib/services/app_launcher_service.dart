import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:android_intent_plus/android_intent.dart';

/// 處理 App 相關互動（例如在 Android 上檢查安裝狀態與啟動應用程式）的服務。
class AppLauncherService {
  // 單例模式 (Singleton)，確保整個 App 只有單一實體。
  static final AppLauncherService _instance = AppLauncherService._internal();
  factory AppLauncherService() => _instance;
  AppLauncherService._internal();

  /// 透過 package name 檢查特定 App 是否已安裝。
  /// 在非 Android 平台上回傳 `false`。
  Future<bool> isAppInstalled(String packageName) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    final AndroidIntent intent = AndroidIntent(
      action: 'action_main',
      category: 'android.intent.category.LAUNCHER',
      package: packageName,
    );
    // canResolveActivity() 檢查是否有 activity 能處理此 intent。
    return await intent.canResolveActivity() ?? false;
  }

  /// 平行檢查多個 App 的安裝狀態。
  ///
  /// 回傳一個 Map，key 為 package name，若已安裝則 value 為 `true`，否則為 `false`。
  Future<Map<String, bool>> checkInstallationStatus(List<String> packageNames) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      // 在非 Android 平台上，預設全部回傳 false。
      return {for (var pkg in packageNames) pkg: false};
    }

    // 平行執行所有檢查以提升效能。
    final checks = packageNames.map((pkg) => isAppInstalled(pkg));
    final results = await Future.wait(checks);

    return Map.fromIterables(packageNames, results);
  }

  /// 若 App 已安裝則將其啟動。若未安裝，則開啟 Google Play 商店頁面。
  ///
  /// 在非 Android 平台上不執行任何動作。
  Future<void> launchOrInstallApp(String packageName) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    if (await isAppInstalled(packageName)) {
      final AndroidIntent launchIntent = AndroidIntent(
        action: 'action_main',
        category: 'android.intent.category.LAUNCHER',
        package: packageName,
      );
      await launchIntent.launch();
    } else {
      final AndroidIntent storeIntent = AndroidIntent(action: 'action_view', data: 'market://details?id=$packageName');
      await storeIntent.launch();
    }
  }
}
