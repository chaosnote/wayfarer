import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // 引入 gestures 以支援滑鼠拖曳設定

import 'pages/main_scaffold_page.dart';

void main() async {
  // 確保 Flutter 核心初始化完成，才能執行非同步的服務初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 1. 必須先執行 runApp，讓 Flutter 建立主畫面與 Activity
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wayfarer',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange), useMaterial3: true),
      // 如果您在網頁版或模擬器測試，這行能讓您直接用「滑鼠按住拖曳」來滑動畫面
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
      ),
      home: const MainScaffoldPage(),
    );
  }
}
