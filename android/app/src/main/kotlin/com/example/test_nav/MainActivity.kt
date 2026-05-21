package com.example.wayfarer

import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wayfarer/volume").setMethodCallHandler { call, result ->
            // 判斷 Dart 傳過來的方法名稱
            when (call.method) {
                "setVolume" -> {
                    val isSoundOn = call.argument<Boolean>("isSoundOn") ?: true
                    val success = setSystemVolume(isSoundOn)
                    if (success) {
                        result.success(null) // 執行成功回報給 Dart
                    } else {
                        result.error("UNAVAILABLE", "音量控制失敗", null)
                    }
                }
                "getVolume" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val currentVolume = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    result.success(currentVolume) // 將取得的音量整數回傳給 Dart
                }
                else -> result.notImplemented()
            }
        }

        // 處理啟動其他 APP 的 MethodChannel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "wayfarer/app_launcher").setMethodCallHandler { call, result ->
            val packageName = call.argument<String>("packageName")
            when (call.method) {
                "isAppInstalled" -> {
                    if (packageName != null) {
                        try {
                            packageManager.getPackageInfo(packageName, 0)
                            result.success(true)
                        } catch (e: PackageManager.NameNotFoundException) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                "launchApp" -> {
                    if (packageName != null) {
                        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                        if (launchIntent != null) {
                            startActivity(launchIntent)
                            result.success(true)
                        } else {
                            result.error("APP_NOT_FOUND", "無法找到 APP 的啟動畫面", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Package Name 為 null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun setSystemVolume(isSoundOn: Boolean): Boolean {
        return try {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (isSoundOn) {
                // 開啟聲音：為了安全起見，不直接調到最大，而是設定為系統最大音量的 50%
                val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, maxVolume / 2, 0)
            } else {
                // 關閉聲音：將媒體音樂音量設為 0
                audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, 0, 0)
            }
            true
        } catch (e: Exception) {
            false
        }
    }
}