package com.example.digital_frame

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val POWER_CHANNEL = "com.digital_frame/power"
    private val ALARM_CHANNEL = "com.digital_frame/alarm"
    private var originalBrightness: Float = -1f

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "slideshow_channel"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("DigitalFrame", "✅ MainActivity initialized!")
        
        createNotificationChannel()
        
        // Power Management Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POWER_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setScreenBrightness" -> {
                    val brightness = call.argument<Double>("brightness") ?: 1.0
                    setScreenBrightness(brightness.toFloat())
                    result.success(null)
                }
                "turnScreenOff" -> {
                    turnScreenOff()
                    result.success(null)
                }
                "turnScreenOn" -> {
                    turnScreenOn()
                    result.success(null)
                }
                "isRooted" -> {
                    result.success(isDeviceRooted())
                }
                "shutdownDevice" -> {
                    shutdownDevice()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        // Alarm Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "onStartAlarm" -> {
                    handleStartAlarm()
                    result.success(null)
                }
                "onStopAlarm" -> {
                    val useRootShutdown = call.argument<Boolean>("useRootShutdown") ?: false
                    handleStopAlarm(useRootShutdown)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    // Intent'ten gelen flag'leri kontrol et
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.let {
            if (it.getBooleanExtra("AUTO_START_SLIDESHOW", false)) {
                Log.d("DigitalFrame", "🎬 Auto-starting slideshow from alarm!")
                // Flag'i temizle (tekrar tetiklememek için)
                it.removeExtra("AUTO_START_SLIDESHOW")
                
                // Flutter'a slideshow başlat mesajı gönder
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, ALARM_CHANNEL).invokeMethod("autoStartSlideshow", null)
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Slideshow Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Digital frame slideshow notifications"
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun handleStartAlarm() {
        Log.d("DigitalFrame", "🎬 START ALARM - Handling...")
        
        // Ekranı aç
        turnScreenOn()
        
        // Uygulamayı aç ve slideshow'u başlat
        openAppAndStartSlideshow()
        
        // Notification göster (bilgilendirme için)
        showStartNotification()
    }

    private fun openAppAndStartSlideshow() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("AUTO_START_SLIDESHOW", true)
            }
            startActivity(intent)
            Log.d("DigitalFrame", "✅ App opened with slideshow flag")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error opening app: ${e.message}")
        }
    }

    private fun handleStopAlarm(useRootShutdown: Boolean) {
        Log.d("DigitalFrame", "⏹️ STOP ALARM - Handling...")
        
        // Ekranı karart
        turnScreenOff()
        
        // Notification göster
        showStopNotification()
        
        // Root shutdown varsa
        if (useRootShutdown) {
            Log.d("DigitalFrame", "🔌 ROOT SHUTDOWN!")
            shutdownDevice()
        }
    }

    private fun showStartNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Digital Frame")
            .setContentText("Slayt gösterisi başlatıldı! 🎬")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(true)
            .build()
        
        notificationManager.notify(100, notification)
        Log.d("DigitalFrame", "✅ Start notification shown")
    }

    private fun showStopNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Digital Frame")
            .setContentText("Ekran kapatıldı. Yarın görüşürüz! 😴")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setAutoCancel(true)
            .build()
        
        notificationManager.notify(101, notification)
        Log.d("DigitalFrame", "✅ Stop notification shown")
    }

    private fun setScreenBrightness(brightness: Float) {
        try {
            val layoutParams = window.attributes
            if (originalBrightness < 0) originalBrightness = layoutParams.screenBrightness
            layoutParams.screenBrightness = brightness
            window.attributes = layoutParams
            Log.d("DigitalFrame", "✅ Brightness: $brightness")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error: ${e.message}")
        }
    }

    private fun turnScreenOff() {
        try {
            setScreenBrightness(0.01f)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            Log.d("DigitalFrame", "✅ Screen turned off")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error: ${e.message}")
        }
    }

    private fun turnScreenOn() {
        try {
            if (originalBrightness >= 0) {
                setScreenBrightness(originalBrightness)
            } else {
                setScreenBrightness(1.0f)
            }
            
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD
            )
            
            // Android 8.0+ için ekstra ayarlar
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            }
            
            Log.d("DigitalFrame", "✅ Screen turned on")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error: ${e.message}")
        }
    }

    private fun isDeviceRooted(): Boolean {
        val paths = arrayOf("/system/app/Superuser.apk", "/sbin/su", "/system/bin/su", "/system/xbin/su")
        return paths.any { File(it).exists() } || Build.TAGS?.contains("test-keys") == true
    }

    private fun shutdownDevice() {
        try {
            Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot -p"))
            Log.d("DigitalFrame", "✅ Shutdown executed")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Shutdown failed: ${e.message}")
        }
    }
}