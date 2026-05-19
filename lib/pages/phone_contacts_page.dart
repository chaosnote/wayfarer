import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneContact {
  final String name;
  final String phone;

  PhoneContact({required this.name, required this.phone});

  // 將物件轉為 Map 以便編碼為 JSON
  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  // 從 JSON 解碼回物件
  factory PhoneContact.fromJson(Map<String, dynamic> json) => PhoneContact(name: json['name'], phone: json['phone']);
}

class PhoneContactsPage extends StatefulWidget {
  const PhoneContactsPage({super.key});

  @override
  State<PhoneContactsPage> createState() => _PhoneContactsPageState();
}

class _PhoneContactsPageState extends State<PhoneContactsPage> {
  final List<PhoneContact> _contacts = [];
  // 將 SharedPreferences 的 key 獨立成共用常數
  static const String _contactsPrefsKey = 'saved_phone_contacts';

  @override
  void initState() {
    super.initState();
    _loadContacts(); // 頁面初始化時讀取資料
  }

  // 從 SharedPreferences 讀取聯絡人
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_contactsPrefsKey);
    if (contactsJson != null) {
      final List<dynamic> decoded = jsonDecode(contactsJson);
      setState(() {
        _contacts.addAll(decoded.map((e) => PhoneContact.fromJson(e)).toList());
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
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新增聯絡人'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '名稱'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: '電話號碼'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () {
                final String name = nameController.text.trim();
                final String phone = phoneController.text.trim();

                // 1. 驗證是否為空值
                if (name.isEmpty || phone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('名稱與電話號碼不能為空')));
                  return;
                }

                // 2. 驗證電話號碼格式 (只允許數字與 +-()及空格)
                if (!RegExp(r'^[\d+\-\(\)\s]+$').hasMatch(phone)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('請輸入有效的電話號碼格式')));
                  return;
                }

                setState(() {
                  _contacts.add(PhoneContact(name: name, phone: phone));
                });
                _saveContacts(); // 新增完後儲存
                Navigator.pop(context);
              },
              child: const Text('新增'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importContact() async {
    // 1. 檢查並請求聯絡人讀取權限 (設定 readonly: true，因為我們只要讀取)
    if (await FlutterContacts.requestPermission(readonly: true)) {
      // 2. 開啟原生聯絡人選擇器
      Contact? contact = await FlutterContacts.openExternalPick();

      if (contact != null) {
        // 3. 檢查是否有電話號碼
        if (contact.phones.isNotEmpty) {
          setState(() {
            // 4. 將選擇的聯絡人加入到我們的清單中
            _contacts.add(PhoneContact(name: contact.displayName, phone: contact.phones.first.number));
          });
          _saveContacts(); // 匯入完後儲存
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('選擇的聯絡人沒有電話號碼')));
          }
        }
      }
    } else {
      // 如果使用者拒絕權限
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要聯絡人權限才能從電話簿匯入')));
      }
    }
  }

  void _deleteContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
    _saveContacts(); // 刪除完後儲存
  }

  // 開啟撥號畫面並帶入電話號碼
  Future<void> _dialContact(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('無法開啟撥號畫面')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phone 聯絡人', style: TextStyle(fontSize: 28)),
        actions: [
          IconButton(
            onPressed: _importContact,
            icon: const Icon(Icons.contact_phone, size: 36), // 在這裡設定 size 屬性來放大圖示
            tooltip: '從電話簿匯入',
          ),
        ],
      ),
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
                    leading: const Icon(Icons.person, size: 36),
                    title: Text(contact.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    subtitle: Text(contact.phone, style: const TextStyle(fontSize: 16)),
                    onTap: () => _dialContact(contact.phone),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 32),
                      onPressed: () => _deleteContact(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddContactDialog, child: const Icon(Icons.add)),
    );
  }
}
