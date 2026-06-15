import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/app_packages.dart';
import '../services/app_launcher_service.dart';

class LaunchAppPage extends StatefulWidget {
  const LaunchAppPage({super.key});

  @override
  State<LaunchAppPage> createState() => _LaunchAppPageState();
}

class _LaunchAppPageState extends State<LaunchAppPage> {
  // Get the service instance
  final AppLauncherService _launcherService = AppLauncherService();

  // 用來記錄每個 App 的安裝狀態 (key: package name, value: 是否已安裝)
  // null 代表還在檢查中
  final Map<String, bool?> _installedStatus = {};

  @override
  void initState() {
    super.initState();
    _checkAllAppsStatus();
  }

  // Batch check all app statuses using the service.
  Future<void> _checkAllAppsStatus() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      // On non-Android, we can immediately set all to false.
      setState(() {
        _installedStatus[AppPackages.line] = false;
        _installedStatus[AppPackages.facebook] = false;
        _installedStatus[AppPackages.youtube] = false;
        _installedStatus[AppPackages.trashPass] = false;
      });
      return;
    }

    final packages = [AppPackages.line, AppPackages.facebook, AppPackages.youtube, AppPackages.trashPass];
    final statuses = await _launcherService.checkInstallationStatus(packages);

    if (mounted) {
      // Update the UI state in a single call.
      setState(() => _installedStatus.addAll(statuses));
    }
  }

  // The UI-facing method to handle the tap event.
  Future<void> _launchOrInstallApp(String packageName) async {
    // Handle UI feedback for non-supported platforms.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('此功能僅支援 Android 設備')));
      }
      return;
    }

    // Delegate the core logic to the service.
    await _launcherService.launchOrInstallApp(packageName);
  }

  // 建立清單項目的共用小工具
  Widget _buildAppTile({
    required String title,
    required String packageName,
    required IconData icon,
    required Color iconColor,
  }) {
    // 根據檢查結果決定要顯示的副標題文字
    String subtitleText;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      subtitleText = '僅支援 Android 設備';
    } else {
      final isInstalled = _installedStatus[packageName];
      if (isInstalled == null) {
        subtitleText = '檢查狀態中...';
      } else {
        subtitleText = isInstalled ? '啟動' : '前往 Play 商店安裝';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: Icon(icon, size: 40, color: iconColor),
        title: Text(title, style: const TextStyle(fontSize: 20)),
        subtitle: Text(subtitleText, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _launchOrInstallApp(packageName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('常用 APP')),
      body: ListView(
        children: [
          _buildAppTile(title: 'Line', packageName: AppPackages.line, icon: Icons.chat, iconColor: Colors.green),
          _buildAppTile(
            title: 'Facebook',
            packageName: AppPackages.facebook,
            icon: Icons.facebook,
            iconColor: Colors.blue,
          ),
          _buildAppTile(
            title: 'YouTube',
            packageName: AppPackages.youtube,
            icon: Icons.video_library,
            iconColor: Colors.red,
          ),
          _buildAppTile(
            title: '全國垃圾通',
            packageName: AppPackages.trashPass,
            icon: Icons.recycling,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}
