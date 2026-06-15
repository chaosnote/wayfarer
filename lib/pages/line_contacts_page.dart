import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

import '../models/app_packages.dart';

// 如何取得 Line 專屬連結？
// 主頁 -> 右上設定 -> 個人檔案 -> 顯示行動條碼 -> 複製連結

class LineContact {
  final String name;
  final String lineId;

  LineContact({required this.name, required this.lineId});

  Map<String, dynamic> toJson() => {'name': name, 'lineId': lineId};

  factory LineContact.fromJson(Map<String, dynamic> json) =>
      LineContact(name: json['name'], lineId: json['lineId'] ?? '');
}

class LineContactsPage extends StatefulWidget {
  const LineContactsPage({super.key});

  @override
  State<LineContactsPage> createState() => _LineContactsPageState();
}

class _LineContactsPageState extends State<LineContactsPage> {
  final List<LineContact> _contacts = [];
  static const String _contactsPrefsKey = 'saved_line_contacts';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  // 從 SharedPreferences 讀取 Line 聯絡人
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_contactsPrefsKey);
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      setState(() {
        _contacts.addAll(decoded.map((e) => LineContact.fromJson(e)).toList());
      });
    }
  }

  // 將聯絡人清單儲存到 SharedPreferences
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsPrefsKey, encoded);
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final lineIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增 Line 聯絡人', style: TextStyle(fontSize: 24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(fontSize: 20),
                decoration: const InputDecoration(labelText: '名稱', labelStyle: TextStyle(fontSize: 20)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lineIdController,
                style: const TextStyle(fontSize: 20),
                decoration: InputDecoration(
                  labelText: 'Line 專屬連結',
                  labelStyle: const TextStyle(fontSize: 20),
                  hintText: '例如: https://line.me/ti/p/...',
                  hintStyle: const TextStyle(fontSize: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.help_outline, size: 28),
                    tooltip: '如何取得連結？',
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('如何取得 Line 專屬連結？', style: TextStyle(fontSize: 22)),
                          content: const SingleChildScrollView(
                            child: Text(
                              '請對方依照以下步驟操作，並將複製好的連結傳給您：\n\n'
                              '1. 開啟 Line App，切換到「主頁」。\n'
                              '2. 點擊右上角的「設定」(齒輪圖示)。\n'
                              '3. 點擊「個人檔案」。\n'
                              '4. 點擊「顯示行動條碼」。\n'
                              '5. 點擊「複製連結」。',
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('我知道了', style: TextStyle(fontSize: 18)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () {
                final String name = nameController.text.trim();
                final String lineId = lineIdController.text.trim();

                if (name.isEmpty || lineId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('名稱與專屬連結不能為空')));
                  return;
                }

                // 驗證是否為有效的 Line 專屬連結格式
                if (!lineId.startsWith('https://line.me/ti/p/')) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('請輸入有效的 Line 專屬連結 (https://line.me/ti/p/...)')));
                  return;
                }

                setState(() {
                  _contacts.add(LineContact(name: name, lineId: lineId));
                });
                _saveContacts();
                Navigator.pop(context);
              },
              child: const Text('新增', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts();
  }

  Future<void> _launchLineProfile(String lineId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('此功能僅支援 Android 設備')));
      return;
    }

    // 判斷使用者輸入的是 網址(專屬連結) 還是 單純的 Line ID
    String intentData;
    if (lineId.startsWith('http')) {
      // 將 https://line.me/ 替換為 Line 原生 Scheme (line://)
      // 確保 Android 強制直接喚醒 Line App，避免跳出瀏覽器
      intentData = lineId.replaceAll(RegExp(r'https?://line\.me/'), 'line://');
    } else {
      // 單純的 Line ID 搜尋需要加上 ~
      intentData = 'line://ti/p/~$lineId';
    }

    // 透過 Intent scheme 開啟特定 Line ID 或連結的個人檔案畫面
    final AndroidIntent intent = AndroidIntent(action: 'action_view', data: intentData, package: AppPackages.line);

    try {
      final bool canResolve = await intent.canResolveActivity() ?? false;
      if (canResolve) {
        await intent.launch();
      } else {
        // 未安裝 Line 時導向 Google Play 商店
        final AndroidIntent storeIntent = AndroidIntent(
          action: 'action_view',
          data: 'market://details?id=${AppPackages.line}',
        );
        await storeIntent.launch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('無法開啟 Line: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _contacts.isEmpty
          ? const Center(child: Text('目前沒有聯絡人，請點擊右下角新增'))
          : ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.chat, size: 36, color: Colors.green),
                    title: Text(contact.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      contact.lineId,
                      style: const TextStyle(fontSize: 16),
                      maxLines: 1, // 限制網址只能顯示一行
                      overflow: TextOverflow.ellipsis, // 超出範圍顯示 ...
                    ),
                    onTap: () => _launchLineProfile(contact.lineId),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 32),
                      onPressed: () => _deleteContact(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addLineContact',
        onPressed: _showAddContactDialog,
        tooltip: '新增 Line 聯絡人',
        child: const Icon(Icons.add),
      ),
    );
  }
}
