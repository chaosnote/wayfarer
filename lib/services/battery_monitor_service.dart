import 'dart:async';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/params.dart';

// 必須是頂層獨立函式 (Top-Level Function)，作為背景服務 (Isolate) 的入口點
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // 確保 Flutter 引擎在背景已初始化
  DartPluginRegistrant.ensureInitialized();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final Battery battery = Battery();

  // 背景全域計時器：系統接管，關掉 App 也會跑
  Timer.periodic(Duration(minutes: AppParams.batteryDurationCheck), (timer) async {
    try {
      final level = await battery.batteryLevel;
      final limit = AppParams.batteryAlertLimit;

      debugPrint("[背景電量監控] 檢查中... 目前 $level% / 設定 $limit%");

      if (level < limit) {
        final Int64List customVibration = Int64List.fromList(<int>[0, 600, 300, 600]);
        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'battery_alert_channel_v3',
          '系統電量警告',
          channelDescription: '當設備電量低於您的設定值時，發出推播通知',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          vibrationPattern: customVibration,
        );
        final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

        await flutterLocalNotificationsPlugin.show(0, '⚠️ 電量警告', '目前電量 ($level%) 低於設定值 ($limit%)', platformDetails);
      }
    } catch (e) {
      debugPrint("背景取得電量失敗: $e");
    }
  });
}

class BatteryMonitorService {
  // 單例模式 (Singleton)：確保整個 App 只有一個監控實體
  static final BatteryMonitorService _instance = BatteryMonitorService._internal();
  factory BatteryMonitorService() => _instance;
  BatteryMonitorService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();

  Future<void> init() async {
    if (kIsWeb) return; // 網頁版不支援本機通知

    debugPrint("[BatteryMonitorService] 進入 init()...");

    // 1. 初始化通知設定
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings(
      AppParams.batteryIconNotification,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    try {
      debugPrint("[BatteryMonitorService] 準備初始化通知套件...");
      await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint("[BatteryMonitorService] 通知套件初始化成功！");

      // 在啟動前景服務前，必須先手動建立 Notification Channel (Android 8.0+)
      if (defaultTargetPlatform == TargetPlatform.android) {
        const AndroidNotificationChannel serviceChannel = AndroidNotificationChannel(
          'battery_monitor_service_channel', // 專為背景常駐服務建立的頻道 ID
          '電量監控服務狀態',
          description: '顯示背景監控服務是否正在執行',
          importance: Importance.low, // 設為 low，確保常駐通知不會發出聲音或彈出干擾
        );
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(serviceChannel);
      }
    } catch (e) {
      debugPrint("[BatteryMonitorService] 🚨 通知套件初始化失敗: $e");
    }

    // 2. 初始化並啟動 Android 背景前景服務
    debugPrint("[BatteryMonitorService] 準備啟動真背景服務...");
    await _initBackgroundService();

    // 3. 延遲請求通知權限，確保主畫面已經渲染完成，避免啟動時找不到 Activity 而卡死
    if (defaultTargetPlatform == TargetPlatform.android) {
      Future.delayed(const Duration(seconds: 2), () async {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      });
    }
  }

  Future<void> _initBackgroundService() async {
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true, // 開啟前景模式，這會產生一個無法滑掉的常駐通知，確保系統絕不殺死 App
        notificationChannelId: 'battery_monitor_service_channel', // 修改為上方新建立的常駐服務專用頻道
        initialNotificationTitle: '電量安全監控中',
        initialNotificationContent: '系統正在背景每 5 分鐘檢查一次電量',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(autoStart: true, onForeground: onStart),
    );
  }
}
