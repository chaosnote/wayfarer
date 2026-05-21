import 'package:flutter/material.dart';
import 'launch_app_page.dart';
import 'json_list_viewer_page.dart';

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
