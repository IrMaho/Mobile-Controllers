package com.example.mobail_contorolers

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mobail_contorolers/mouse"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "moveCursor" -> {
                    val deltaX = call.argument<Int>("deltaX") ?: 0
                    val deltaY = call.argument<Int>("deltaY") ?: 0
                    MouseControlService.instance?.moveCursor(deltaX, deltaY)
                    result.success(null)
                }
                "performClick" -> {
                    MouseControlService.instance?.performClick()
                    result.success(null)
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
