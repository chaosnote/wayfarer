import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// 處理 App 相關互動（例如在 Android 上檢查安裝狀態與啟動應用程式）的服務。
class AppLauncherService {
  // 單例模式 (Singleton)，確保整個 App 只有單一實體。
  static final AppLauncherService _instance = AppLauncherService._internal();
  factory AppLauncherService() => _instance;
  AppLauncherService._internal();

  // 建立與 Android 原生溝通的通道
  static const MethodChannel _channel = MethodChannel('wayfarer/app_launcher');

  /// 透過 package name 檢查特定 App 是否已安裝。
  /// 在非 Android 平台上回傳 `false`。
  Future<bool> isAppInstalled(String packageName) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      // 呼叫原生層的檢查方法
      final bool result = await _channel.invokeMethod('isAppInstalled', {'packageName': packageName});
      return result;
    } catch (e) {
      debugPrint('檢查安裝狀態失敗: $e');
      return false;
    }
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
      try {
        // 呼叫原生層最標準的 getLaunchIntentForPackage 來啟動
        await _channel.invokeMethod('launchApp', {'packageName': packageName});
      } catch (e) {
        debugPrint('啟動 APP 失敗: $e');
        await _launchStore(packageName);
      }
    } else {
      await _launchStore(packageName);
    }
  }

  // 統一使用 url_launcher 開啟商店，支援度與穩定性更好
  Future<void> _launchStore(String packageName) async {
    final Uri marketUri = Uri.parse('market://details?id=$packageName');
    final Uri webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

    try {
      // 優先嘗試用商店協議打開，若無 Play 商店則用網頁瀏覽器打開
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('開啟商店失敗: $e');
    }
  }
}
