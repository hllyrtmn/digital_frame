package com.example.digital_frame

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
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
    private val POWER_CHANNEL = "com.digitalframe/power"
    private val ALARM_CHANNEL = "com.digitalframe/alarm"
    private var originalBrightness: Float = -1f

    // ✅ Device Policy Manager
    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "slideshow_channel"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("DigitalFrame", "✅ MainActivity initialized!")
        
        // ✅ Device Admin setup
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)
        
        createNotificationChannel()
        
        // POWER CHANNEL - ✅ YENİ METODLAR EKLENDİ
        Log.d("DigitalFrame", "📡 Setting up POWER channel...")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, POWER_CHANNEL).setMethodCallHandler { call, result ->
            Log.d("DigitalFrame", "📞 POWER Method called: ${call.method}")
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
                    val rooted = isDeviceRooted()
                    Log.d("DigitalFrame", "Root status: $rooted")
                    result.success(rooted)
                }
                "shutdownDevice" -> {
                    shutdownDevice()
                    result.success(null)
                }
                // ✅ YENİ: Device Admin metodları
                "isDeviceAdminActive" -> {
                    val active = devicePolicyManager.isAdminActive(adminComponent)
                    Log.d("DigitalFrame", "Device Admin active: $active")
                    result.success(active)
                }
                "requestDeviceAdmin" -> {
                    Log.d("DigitalFrame", "🔐 Requesting Device Admin...")
                    requestDeviceAdmin()
                    result.success(null)
                }
                "lockScreen" -> {
                    Log.d("DigitalFrame", "🔒 Locking screen...")
                    lockScreen()
                    result.success(null)
                }
                else -> {
                    Log.d("DigitalFrame", "❌ Unknown POWER method: ${call.method}")
                    result.notImplemented()
                }
            }
        }

        // ALARM CHANNEL
        Log.d("DigitalFrame", "📡 Setting up ALARM channel...")
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            Log.d("DigitalFrame", "🔔 ALARM Method called: ${call.method}")
            when (call.method) {
                "onStartAlarm" -> {
                    Log.d("DigitalFrame", "🎬 onStartAlarm received!")
                    handleStartAlarm()
                    result.success(null)
                }
                "onStopAlarm" -> {
                    Log.d("DigitalFrame", "⏹️ onStopAlarm received!")
                    val useRootShutdown = call.argument<Boolean>("useRootShutdown") ?: false
                    handleStopAlarm(useRootShutdown)
                    result.success(null)
                }
                else -> {
                    Log.d("DigitalFrame", "❌ Unknown ALARM method: ${call.method}")
                    result.notImplemented()
                }
            }
        }
        
        Log.d("DigitalFrame", "✅ All channels configured!")
    }

    // ✅ Device Admin izni iste
    private fun requestDeviceAdmin() {
        try {
            if (!devicePolicyManager.isAdminActive(adminComponent)) {
                Log.d("DigitalFrame", "📱 Opening Device Admin permission screen...")
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(
                        DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                        "Digital Frame uygulaması ekranı kilitlemek için Device Admin izni gerektiriyor."
                    )
                }
                startActivity(intent)
            } else {
                Log.d("DigitalFrame", "✅ Device Admin already active")
            }
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error requesting device admin: ${e.message}")
        }
    }

    // ✅ Ekranı kilitle
    private fun lockScreen() {
        try {
            if (devicePolicyManager.isAdminActive(adminComponent)) {
                devicePolicyManager.lockNow()
                Log.d("DigitalFrame", "🔒 Screen locked successfully")
            } else {
                Log.e("DigitalFrame", "❌ Device Admin not active, cannot lock screen")
            }
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error locking screen: ${e.message}")
        }
    }

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
                it.removeExtra("AUTO_START_SLIDESHOW")
                
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
            Log.d("DigitalFrame", "✅ Notification channel created")
        }
    }

    private fun handleStartAlarm() {
        Log.d("DigitalFrame", "🎬 START ALARM - Handling...")
        
        turnScreenOn()
        openAppAndStartSlideshow()
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
        
        // ✅ Device Admin varsa ekranı kilitle
        if (devicePolicyManager.isAdminActive(adminComponent)) {
            Log.d("DigitalFrame", "🔒 Device Admin active, locking screen...")
            lockScreen()
        } else {
            // Yoksa sadece karart
            Log.d("DigitalFrame", "💡 Device Admin not active, dimming screen...")
            turnScreenOff()
        }
        
        showStopNotification()
        
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
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        
        notificationManager.notify(100, notification)
        Log.d("DigitalFrame", "✅ Start notification shown")
    }

    private fun showStopNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        val contentText = if (devicePolicyManager.isAdminActive(adminComponent)) {
            "Ekran kilitlendi. Yarın görüşürüz! 🔒"
        } else {
            "Ekran karartıldı. Yarın görüşürüz! 😴"
        }
        
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Digital Frame")
            .setContentText(contentText)
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
            Log.d("DigitalFrame", "✅ Brightness set to: $brightness")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error setting brightness: ${e.message}")
        }
    }

    private fun turnScreenOff() {
        try {
            setScreenBrightness(0.01f)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            Log.d("DigitalFrame", "✅ Screen dimmed")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error turning screen off: ${e.message}")
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
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
            }
            
            Log.d("DigitalFrame", "✅ Screen turned on")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error turning screen on: ${e.message}")
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
            Log.e("DigitalFrame", "❌ Error shutting down: ${e.message}")
        }
    }
}