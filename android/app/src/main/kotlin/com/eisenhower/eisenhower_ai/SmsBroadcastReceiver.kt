package com.eisenhower.eisenhower_ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony

class SmsBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        try {
            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
            if (messages.isNullOrEmpty()) return

            val sender = messages[0].displayOriginatingAddress ?: "SMS"
            val body = messages.joinToString(separator = "") { it.displayMessageBody ?: "" }

            if (body.isBlank()) return

            val payload = mapOf(
                "source" to "SMS",
                "packageName" to "telephony.sms",
                "title" to sender,
                "text" to body,
                "postTime" to System.currentTimeMillis()
            )

            EisenhowerNotificationListener.dispatchPayload(payload)
        } catch (_: Exception) {}
    }
}
