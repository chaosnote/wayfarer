import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';

class JsonListViewerPage extends StatefulWidget {
  const JsonListViewerPage({super.key});

  @override
  State<JsonListViewerPage> createState() => _JsonListViewerPageState();
}

class _JsonListViewerPageState extends State<JsonListViewerPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _jsonData;
  String? _errorMessage;
  String? _fileName;

  Future<void> _pickAndLoadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'], // 允許 JSON 或純文字檔 , 'txt'
      );

      if (result == null) {
        return; // 使用者取消選擇
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _jsonData = null;
        _fileName = result.files.single.name;
      });

      String jsonString;
      if (result.files.single.bytes != null) {
        // 針對 Web 等平台
        jsonString = utf8.decode(result.files.single.bytes!);
      } else if (result.files.single.path != null) {
        // 針對 Mobile / Desktop 平台
        final file = File(result.files.single.path!);
        jsonString = await file.readAsString();
      } else {
        throw Exception('無法讀取檔案內容');
      }

      final decoded = jsonDecode(jsonString);

      if (decoded is Map<String, dynamic>) {
        setState(() {
          _jsonData = decoded;
        });
      } else {
        setState(() {
          _errorMessage = 'JSON 格式不符預期，最外層必須是 Object (Map)';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '發生錯誤，請檢查檔案格式是否為合法 JSON: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildJsonViewer() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 16)),
        ),
      );
    }
    if (_jsonData == null) {
      return const Center(
        child: Text('請點擊上方按鈕選擇本地 JSON 檔案', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }
    if (_jsonData!.isEmpty) {
      return const Center(
        child: Text('取得的 JSON 資料為空', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    final keys = _jsonData!.keys.toList();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final groupKey = keys[index];
        final groupData = _jsonData![groupKey];

        return ExpansionTile(
          initiallyExpanded: true, // 預設展開
          title: Text(
            groupKey,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          children: _buildGroupItems(groupData),
        );
      },
    );
  }

  List<Widget> _buildGroupItems(dynamic groupData) {
    if (groupData is! List) {
      return [const Padding(padding: EdgeInsets.all(16.0), child: Text('此群組資料格式非陣列 (List)'))];
    }

    return groupData.map<Widget>((item) {
      if (item is! Map<String, dynamic>) {
        return ListTile(title: Text(item.toString()));
      }

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: item.entries.map((entry) {
              final valueStr = '${entry.value}';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8.0),
                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: valueStr));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已複製: $valueStr')));
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Key 先改為不顯示
                        Expanded(child: Text(valueStr, style: const TextStyle(fontSize: 20))),
                        const SizedBox(width: 8),
                        const Icon(Icons.copy_all, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('本地 JSON 檢視', style: TextStyle(fontSize: 28))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _fileName ?? '尚未選擇檔案',
                      style: TextStyle(fontSize: 16, color: _fileName != null ? null : Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickAndLoadFile,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('選擇檔案', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildJsonViewer()),
        ],
      ),
    );
  }
}
