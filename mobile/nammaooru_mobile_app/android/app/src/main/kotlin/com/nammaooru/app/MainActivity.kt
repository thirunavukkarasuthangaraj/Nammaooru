package com.nammaooru.app

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import androidx.core.content.ContextCompat
import com.google.android.gms.auth.api.phone.SmsRetriever
import com.google.android.gms.common.api.CommonStatusCodes
import com.google.android.gms.common.api.Status
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * OTP auto-read through Google's SMS User Consent API.
 *
 * Works with any SMS template (no app hash needed): when an OTP-looking SMS
 * arrives, Play services shows a one-tap "allow" sheet and hands us the
 * message body. No SMS permission is declared - Google Play rejects
 * RECEIVE_SMS/READ_SMS for anything but default SMS apps, so direct reading
 * is not an option for a Play-distributed app.
 *
 * Flutter side: lib/core/services/sms_user_consent.dart ("start"/"stop",
 * callback "onSms" with the message body).
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var consentReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> { startListening(); result.success(null) }
                    "stop" -> { stopListening(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun startListening() {
        stopListening()
        val r = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (SmsRetriever.SMS_RETRIEVED_ACTION != intent.action) return
                val extras = intent.extras ?: return
                @Suppress("DEPRECATION")
                val status = extras.get(SmsRetriever.EXTRA_STATUS) as? Status ?: return
                when (status.statusCode) {
                    CommonStatusCodes.SUCCESS -> {
                        @Suppress("DEPRECATION")
                        val consent = extras.getParcelable<Intent>(SmsRetriever.EXTRA_CONSENT_INTENT) ?: return
                        try { startActivityForResult(consent, REQ_CONSENT) } catch (_: Exception) {}
                    }
                    CommonStatusCodes.TIMEOUT -> stopListening()
                }
            }
        }
        consentReceiver = r
        ContextCompat.registerReceiver(
            this, r, IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION),
            SmsRetriever.SEND_PERMISSION, null, ContextCompat.RECEIVER_EXPORTED
        )
        try {
            SmsRetriever.getClient(this).startSmsUserConsent(null)
        } catch (_: Exception) {
            // No Play services - the user types the code manually.
            stopListening()
        }
    }

    private fun stopListening() {
        consentReceiver?.let { try { unregisterReceiver(it) } catch (_: Exception) {} }
        consentReceiver = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == REQ_CONSENT) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                data.getStringExtra(SmsRetriever.EXTRA_SMS_MESSAGE)?.let { body ->
                    runOnUiThread { channel?.invokeMethod("onSms", body) }
                }
            }
            stopListening()
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }

    companion object {
        const val CHANNEL = "nammaooru/sms_consent"
        const val REQ_CONSENT = 4711
    }
}
