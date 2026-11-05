package com.eisenhower.eisenhower_ai

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.CopyOnWriteArrayList

class EisenhowerNotificationListener : NotificationListenerService() {

    companion object {
        private const val PREFS_NAME = "eisenhower_notifications_queue"
        private const val KEY_PENDING = "pending_notifications"

        val TARGET_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "org.telegram.messenger.web",
            "org.thunderdog.challegram",
            "org.telegram.plus",
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.oneplus.mms",
            "com.coloros.mms",
            "com.oppo.mms",
            "com.huawei.message",
            "com.google.android.gm"
        )

        private val listeners = CopyOnWriteArrayList<(Map<String, Any?>) -> Unit>()

        fun registerListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.add(listener)
        }

        fun unregisterListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.remove(listener)
        }

        fun dispatchPayload(context: Context?, payload: Map<String, Any?>) {
            if (listeners.isNotEmpty()) {
                for (listener in listeners) {
                    try {
                        listener(payload)
                    } catch (_: Exception) {}
                }
            } else if (context != null) {
                savePendingNotification(context, payload)
            }
        }

        private fun savePendingNotification(context: Context, payload: Map<String, Any?>) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingJson = prefs.getString(KEY_PENDING, "[]") ?: "[]"
                val jsonArray = JSONArray(existingJson)
                val obj = JSONObject(payload)
                jsonArray.put(obj)
                val trimmedArray = if (jsonArray.length() > 50) {
                    val newArr = JSONArray()
                    for (i in (jsonArray.length() - 50) until jsonArray.length()) {
                        newArr.put(jsonArray.get(i))
                    }
                    newArr
                } else {
                    jsonArray
                }
                prefs.edit().putString(KEY_PENDING, trimmedArray.toString()).apply()
            } catch (_: Exception) {}
        }

        fun getAndClearPendingNotifications(context: Context): List<Map<String, Any?>> {
            val result = mutableListOf<Map<String, Any?>>()
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingJson = prefs.getString(KEY_PENDING, "[]") ?: "[]"
                val jsonArray = JSONArray(existingJson)
                for (i in 0 until jsonArray.length()) {
                    val obj = jsonArray.getJSONObject(i)
                    val map = mutableMapOf<String, Any?>()
                    val keys = obj.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        map[key] = obj.get(key)
                    }
                    result.add(map)
                }
                prefs.edit().remove(KEY_PENDING).apply()
            } catch (_: Exception) {}
            return result
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (!TARGET_PACKAGES.contains(packageName)) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: ""

        if (title.isBlank() && text.isBlank()) return

        val source = when {
            packageName.contains("whatsapp") -> "WhatsApp"
            packageName.contains("telegram") || packageName.contains("challegram") -> "Telegram"
            packageName.contains("android.gm") -> "Gmail"
            else -> "SMS"
        }

        val payload = mapOf(
            "source" to source,
            "packageName" to packageName,
            "title" to title,
            "text" to text,
            "postTime" to sbn.postTime
        )

        dispatchPayload(applicationContext, payload)
    }
}
