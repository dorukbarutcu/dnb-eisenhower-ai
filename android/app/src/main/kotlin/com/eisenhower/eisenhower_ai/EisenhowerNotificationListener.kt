package com.eisenhower.eisenhower_ai

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import java.util.concurrent.CopyOnWriteArrayList

class EisenhowerNotificationListener : NotificationListenerService() {

    companion object {
        val TARGET_PACKAGES = setOf(
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "org.telegram.messenger.web",
            "org.thunderdog.challegram",
            "com.google.android.apps.messaging",
            "com.samsung.android.messaging",
            "com.android.mms",
            "com.oneplus.mms",
            "com.coloros.mms",
            "com.oppo.mms",
            "com.huawei.message"
        )

        private val listeners = CopyOnWriteArrayList<(Map<String, Any?>) -> Unit>()

        fun registerListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.add(listener)
        }

        fun unregisterListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.remove(listener)
        }

        fun dispatchPayload(payload: Map<String, Any?>) {
            for (listener in listeners) {
                try {
                    listener(payload)
                } catch (_: Exception) {}
            }
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
            else -> "SMS"
        }

        val payload = mapOf(
            "source" to source,
            "packageName" to packageName,
            "title" to title,
            "text" to text,
            "postTime" to sbn.postTime
        )

        dispatchPayload(payload)
    }
}
