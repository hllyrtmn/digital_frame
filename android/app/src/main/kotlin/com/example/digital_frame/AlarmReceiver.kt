package com.example.digital_frame

import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.io.File

/**
 * AlarmReceiver - android_alarm_manager_plus callback'lerinden intent alır
 * 
 * android_alarm_manager_plus callback'leri izole VM'de çalışır ve MethodChannel kullanamaz.
 * Bu yüzden SharedPreferences ile flag set ederiz, bu receiver kontrol eder.
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        const val ACTION_START_SLIDESHOW = "com.example.digital_frame.START_SLIDESHOW"
        const val ACTION_STOP_SLIDESHOW = "com.example.digital_frame.STOP_SLIDESHOW"
        const val PREFS_NAME = "digital_frame_prefs"
        const val KEY_ALARM_ACTION = "alarm_action"
        const val KEY_USE_ROOT_SHUTDOWN = "use_root_shutdown"
        const val NOTIFICATION_CHANNEL_ID = "alarm_channel"
    }

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("DigitalFrame", "🔔 ════════════════════════════════════════")
        Log.d("DigitalFrame", "🔔 AlarmReceiver.onReceive()")
        Log.d("DigitalFrame", "🔔 Action: ${intent.action}")
        Log.d("DigitalFrame", "🔔 ════════════════════════════════════════")


        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val alarmAction = prefs.getString(KEY_ALARM_ACTION, null)
        val useRootShutdown = prefs.getBoolean(KEY_USE_ROOT_SHUTDOWN, false)

        Log.d("DigitalFrame", "📋 SharedPrefs alarm_action: $alarmAction")
        Log.d("DigitalFrame", "📋 SharedPrefs use_root_shutdown: $useRootShutdown")

        when (alarmAction) {
            "START" -> {
                Log.d("DigitalFrame", "🎬 Processing START alarm...")
                handleStartAlarm(context)

                prefs.edit().remove(KEY_ALARM_ACTION).apply()
            }
            "STOP" -> {
                Log.d("DigitalFrame", "⏹️ Processing STOP alarm...")
                handleStopAlarm(context, useRootShutdown)

                prefs.edit().remove(KEY_ALARM_ACTION).apply()
            }
            else -> {
                Log.d("DigitalFrame", "⚠️ No alarm action found in SharedPreferences")
            }
        }
    }

    private fun handleStartAlarm(context: Context) {
        Log.d("DigitalFrame", "🎬 ════════════════════════════════════════")
        Log.d("DigitalFrame", "🎬 START ALARM - Receiver Handler")
        Log.d("DigitalFrame", "🎬 ════════════════════════════════════════")


        showNotification(context, "🎬 Slayt Gösterisi Başlıyor!", "Digital Frame açılıyor...")


        openMainActivity(context, true)

        Log.d("DigitalFrame", "✅ Start alarm handled")
    }

    private fun handleStopAlarm(context: Context, useRootShutdown: Boolean) {
        Log.d("DigitalFrame", "⏹️ ════════════════════════════════════════")
        Log.d("DigitalFrame", "⏹️ STOP ALARM - Receiver Handler")
        Log.d("DigitalFrame", "⏹️ Root shutdown: $useRootShutdown")
        Log.d("DigitalFrame", "⏹️ ════════════════════════════════════════")


        val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        val adminComponent = ComponentName(context, DeviceAdminReceiver::class.java)
        val isAdminActive = devicePolicyManager.isAdminActive(adminComponent)

        if (isAdminActive) {
            Log.d("DigitalFrame", "🔒 Device Admin active, will lock screen")
            showNotification(context, "🔒 Digital Frame", "Ekran kilitlendi. İyi geceler!")
        } else {
            Log.d("DigitalFrame", "💡 Device Admin not active, will dim screen")
            showNotification(context, "💡 Digital Frame", "Ekran karartıldı. İyi geceler!")
        }


        openMainActivity(context, false, useRootShutdown)


        if (useRootShutdown && isDeviceRooted()) {
            Log.d("DigitalFrame", "🔌 ROOT SHUTDOWN!")
            shutdownDevice()
        }

        Log.d("DigitalFrame", "✅ Stop alarm handled")
    }

    private fun openMainActivity(context: Context, autoStart: Boolean, useRootShutdown: Boolean = false) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                
                if (autoStart) {
                    putExtra("AUTO_START_SLIDESHOW", true)
                    Log.d("DigitalFrame", "🎬 Intent: AUTO_START_SLIDESHOW = true")
                } else {
                    putExtra("AUTO_STOP_SLIDESHOW", true)
                    putExtra("useRootShutdown", useRootShutdown)
                    Log.d("DigitalFrame", "⏹️ Intent: AUTO_STOP_SLIDESHOW = true")
                }
            }

            context.startActivity(intent)
            Log.d("DigitalFrame", "✅ MainActivity intent sent")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error opening MainActivity: ${e.message}", e)
        }
    }

    private fun showNotification(context: Context, title: String, message: String) {
        try {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager


            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "Alarm Notifications",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Digital Frame alarm notifications"
                }
                notificationManager.createNotificationChannel(channel)
            }

            val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(message)
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()

            notificationManager.notify(System.currentTimeMillis().toInt(), notification)
            Log.d("DigitalFrame", "✅ Notification shown: $title")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error showing notification: ${e.message}", e)
        }
    }

    private fun isDeviceRooted(): Boolean {
        val paths = arrayOf("/system/app/Superuser.apk", "/sbin/su", "/system/bin/su", "/system/xbin/su")
        return paths.any { File(it).exists() } || Build.TAGS?.contains("test-keys") == true
    }

    private fun shutdownDevice() {
        try {
            Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot -p"))
            Log.d("DigitalFrame", "✅ Shutdown command executed")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error shutting down: ${e.message}", e)
        }
    }
}