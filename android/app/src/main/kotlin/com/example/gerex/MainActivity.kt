package com.example.gerex

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.gerex/health_connect"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openHealthConnectSettings") {
                try {
                    // Try Android 14+ built-in intent
                    val intent = Intent("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                        putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    result.success(true)
                } catch (e1: Exception) {
                    try {
                        // Try Android 13 and below standalone intent
                        val intent = Intent("androidx.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                            putExtra(Intent.EXTRA_PACKAGE_NAME, packageName)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e2: Exception) {
                        try {
                            // Try Health Connect app home intent
                            val intent = Intent(Intent.ACTION_MAIN).apply {
                                setPackage("com.google.android.apps.healthdata")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e3: Exception) {
                            try {
                                // Generic App details fallback
                                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                    data = Uri.parse("package:$packageName")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (e4: Exception) {
                                result.error("UNAVAILABLE", "Could not open Health Connect settings: ${e4.message}", null)
                            }
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
