import 'package:flutter/material.dart';
import 'launch_app_page.dart';

class OtherFuncPage extends StatelessWidget {
  const OtherFuncPage({super.key});

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
          // TODO: 未來可以在這裡繼續加入其他的 Card 作為新的次功能入口
        ],
      ),
    );
  }
}
