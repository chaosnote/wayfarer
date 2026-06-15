import 'dart:io';

import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart';

enum RecordState { idle, recording, stopped }

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  // 錄音狀態與播放清單資料
  RecordState _recordState = RecordState.idle;
  final List<String> _playlist = [];
  String? _playingItem;

  late final FlutterSoundRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  String? _tempRecordPath;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingItem = null;
        });
      }
    });

    _initRecorder();
    _loadPlaylist(); // 初始化時讀取現有錄音檔
  }

  Future<void> _initRecorder() async {
    await _audioRecorder.openRecorder();
  }

  // 讀取已經存在的錄音檔
  Future<void> _loadPlaylist() async {
    final dir = await getDownloadsDirectory();
    if (dir == null || !dir.existsSync()) return;

    final List<String> loadedFiles = [];
    try {
      final files = dir.listSync();
      for (var entity in files) {
        // 確保只讀取副檔名為 .aac 且包含 '錄音檔_' 的檔案，避免讀到其他下載物
        if (entity is File && entity.path.endsWith('.aac') && entity.path.contains('錄音檔_')) {
          loadedFiles.add(entity.path);
        }
      }
    } catch (e) {
      debugPrint('讀取目錄失敗: $e');
    }

    // 依照檔名遞減排序 (讓最新錄製的顯示在最上面)
    loadedFiles.sort((a, b) => b.compareTo(a));

    if (mounted) {
      setState(() {
        _playlist.clear();
        _playlist.addAll(loadedFiles);
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ================= 錄音相關操作 =================
  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要麥克風權限才能錄音')));
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    // 將副檔名改為 .aac
    _tempRecordPath = '${dir.path}/temp_record.aac';

    await _audioRecorder.startRecorder(
      toFile: _tempRecordPath,
      codec: Codec.aacADTS, // 明確指定使用 AAC 編碼格式
    );

    setState(() {
      _recordState = RecordState.recording;
    });
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stopRecorder();
    setState(() {
      _recordState = RecordState.stopped;
    });
  }

  Future<void> _cancelRecording() async {
    if (_audioRecorder.isRecording) {
      await _audioRecorder.stopRecorder();
    }
    if (_tempRecordPath != null) {
      final file = File(_tempRecordPath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _tempRecordPath = null;
    }
    setState(() {
      _recordState = RecordState.idle;
    });
  }

  Future<void> _saveRecording() async {
    if (_tempRecordPath == null) return;

    final dir = await getDownloadsDirectory();
    if (dir == null) return; // 加上 null 檢查：如果平台不支援下載目錄，則終止儲存動作

    // 根據 path_provider 的建議，在使用前先確保目錄存在
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    // 儲存的檔案副檔名也同步改為 .aac
    final String newRecordName = '錄音檔_${DateTime.now().toIso8601String().replaceAll(':', '').split('.')[0]}.aac';
    final String newPath = '${dir.path}/$newRecordName';
    debugPrint('SaveFilePath: $newPath');

    final tempFile = File(_tempRecordPath!);
    if (tempFile.existsSync()) {
      tempFile.copySync(newPath);
      tempFile.deleteSync();
    }

    setState(() {
      _playlist.insert(0, newPath); // 配合排序，將新錄音檔直接插入到清單最上方
      _recordState = RecordState.idle;
      _tempRecordPath = null;
    });
  }

  // ================= 播放清單相關操作 =================
  Future<void> _startPlaying(String item) async {
    await _audioPlayer.play(DeviceFileSource(item));
    setState(() {
      _playingItem = item;
    });
  }

  Future<void> _stopPlaying() async {
    await _audioPlayer.stop();
    setState(() {
      _playingItem = null;
    });
  }

  Future<void> _deleteItem(String item) async {
    if (_playingItem == item) {
      await _stopPlaying();
    }

    final file = File(item);
    if (file.existsSync()) {
      file.deleteSync();
    }

    setState(() {
      _playlist.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('錄音與播放程式', style: TextStyle(fontSize: 28))),
      body: _buildPlaylistSection(),
      bottomNavigationBar: _buildRecorderDock(),
    );
  }

  // 建構下方錄音控制 Dock
  Widget _buildRecorderDock() {
    return BottomAppBar(
      height: 110, // 微調高度確保空間充足
      padding: EdgeInsets.zero, // 移除 BottomAppBar 預設的內距，釋放最大空間
      child: Row(
        children: [
          Expanded(
            child: _buildDockButton(
              icon: Icons.mic,
              label: '開始',
              onPressed: _recordState == RecordState.idle ? _startRecording : null,
            ),
          ),
          Expanded(
            child: _buildDockButton(
              icon: Icons.stop,
              label: '停止',
              onPressed: _recordState == RecordState.recording ? _stopRecording : null,
            ),
          ),
          Expanded(
            child: _buildDockButton(
              icon: Icons.cancel,
              label: '取消',
              onPressed: _recordState != RecordState.idle ? _cancelRecording : null,
            ),
          ),
          Expanded(
            child: _buildDockButton(
              icon: Icons.save,
              label: '儲存',
              onPressed: _recordState == RecordState.stopped ? _saveRecording : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDockButton({required IconData icon, required String label, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0), // 移除水平固定內距，交給外層的 Expanded 自動平分寬度
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40.0, // 放大圖示尺寸
              color: onPressed != null ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 18.0, // 放大文字尺寸
                fontWeight: FontWeight.w500, // 讓字體稍微加粗，增加識別度
                color: onPressed != null ? Theme.of(context).colorScheme.primary : Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 建構播放清單區塊
  Widget _buildPlaylistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('播放清單 (${_playlist.length} 個物件)', style: Theme.of(context).textTheme.titleLarge),
        ),
        Expanded(
          child: _playlist.isEmpty
              ? const Center(child: Text('目前沒有錄音檔'))
              : ListView.builder(
                  itemCount: _playlist.length,
                  itemBuilder: (context, index) {
                    final item = _playlist[index];
                    final isPlaying = _playingItem == item;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // 增加項目整體的上下內距，擴大視覺空間
                      leading: CircleAvatar(child: Icon(isPlaying ? Icons.volume_up : Icons.audio_file)),
                      title: Text(item.split('/').last), // 使用 split 切割路徑，只取最後面的檔名
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isPlaying)
                            IconButton(
                              iconSize: 36.0, // 放大播放圖示與點擊範圍
                              icon: const Icon(Icons.play_arrow, color: Colors.green),
                              onPressed: () => _startPlaying(item),
                              tooltip: '開始',
                            )
                          else
                            IconButton(
                              iconSize: 36.0, // 放大停止圖示與點擊範圍
                              icon: const Icon(Icons.stop, color: Colors.orange),
                              onPressed: _stopPlaying,
                              tooltip: '停止',
                            ),
                          const SizedBox(width: 8.0), // 在播放控制與刪除按鈕間增加安全間距，防止誤觸
                          IconButton(
                            iconSize: 36.0, // 放大刪除圖示與點擊範圍
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteItem(item),
                            tooltip: '刪除',
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
