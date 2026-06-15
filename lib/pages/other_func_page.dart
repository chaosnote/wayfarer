import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:android_intent_plus/android_intent.dart';

import 'launch_app_page.dart';
import 'json_list_viewer_page.dart';
import 'media_page.dart';

class OtherFuncPage extends StatefulWidget {
  const OtherFuncPage({super.key});

  @override
  State<OtherFuncPage> createState() => _OtherFuncPageState();
}

class _OtherFuncPageState extends State<OtherFuncPage> {
  Future<void> _setSystemTimer() async {
    // 平台防呆機制
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('此功能僅支援 Android 設備')));
      }
      return;
    }

    try {
      const AndroidIntent intent = AndroidIntent(
        action: 'android.intent.action.SET_TIMER',
        arguments: <String, dynamic>{
          'android.intent.extra.alarm.MESSAGE': 'Wayfarer 倒數計時',
          'android.intent.extra.alarm.SKIP_UI': false, // 設為 false 會跳轉至時鐘 APP 讓使用者自行設定時間
        },
      );
      await intent.launch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('無法開啟倒數計時設定: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('其他功能', style: TextStyle(fontSize: 28))),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.apps, size: 36, color: Colors.blue),
              title: const Text('常用 APP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('啟動或安裝常用的應用程式', style: TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LaunchAppPage()));
              },
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.timer, size: 36, color: Colors.teal),
              title: const Text('煮菜倒數計時', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('使用 Android 原生時鐘設定倒數', style: TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _setSystemTimer,
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.mic, size: 36, color: Colors.green),
              title: const Text('錄音與播放', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('使用麥克風錄製音訊並播放', style: TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MediaPage()));
              },
            ),
          ),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.data_object, size: 36, color: Colors.purple),
              title: const Text('本地 JSON 檢視', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              subtitle: const Text('選取本地檔案並顯示 JSON 清單', style: TextStyle(fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const JsonListViewerPage()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
