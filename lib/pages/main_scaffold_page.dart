import 'package:flutter/material.dart';
import 'line_contacts_page.dart';
import 'phone_contacts_page.dart';
import 'launch_app_page.dart';
import 'device_status_page.dart';
import '../services/battery_monitor_service.dart';

class MainScaffoldPage extends StatefulWidget {
  const MainScaffoldPage({super.key});

  @override
  State<MainScaffoldPage> createState() => _MainScaffoldPageState();
}

class _MainScaffoldPageState extends State<MainScaffoldPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    PhoneContactsPage(),
    LineContactsPage(),
    DeviceStatusPage(),
    LaunchAppPage(), // 加入新建立的啟動軟體頁面
  ];

  @override
  void initState() {
    super.initState();
    // 在首頁畫面初始化完成後，才啟動背景通知服務，確保 Activity 存在且安全
    WidgetsBinding.instance.addPostFrameCallback((_) {
      BatteryMonitorService().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // 恢復為只載入單一頁面，節省記憶體
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        iconSize: 40.0,
        selectedFontSize: 20.0,
        unselectedFontSize: 18.0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Phone'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Line'),
          BottomNavigationBarItem(icon: Icon(Icons.perm_device_information), label: '狀態'),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: '軟體'),
        ],
      ),
    );
  }
}
