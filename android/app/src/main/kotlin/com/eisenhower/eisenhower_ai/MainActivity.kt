package com.eisenhower.eisenhower_ai

import android.content.ComponentName
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CONTROL_CHANNEL = "com.eisenhower.ai/notifications_control"
    private val STREAM_CHANNEL = "com.eisenhower.ai/notifications_stream"

    private var eventSink: EventChannel.EventSink? = null
    private val notificationCallback: (Map<String, Any?>) -> Unit = { payload ->
        runOnUiThread {
            eventSink?.success(payload)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CONTROL_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationAccessGranted" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "getPendingNotifications" -> {
                    val pending = EisenhowerNotificationListener.getAndClearPendingNotifications(context)
                    result.success(pending)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    EisenhowerNotificationListener.registerListener(notificationCallback)
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    EisenhowerNotificationListener.unregisterListener(notificationCallback)
                }
            }
        )
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat?.contains(pkgName) == true
    }

    private fun openNotificationSettings() {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        } else {
            Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        EisenhowerNotificationListener.unregisterListener(notificationCallback)
    }
}
