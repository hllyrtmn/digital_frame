package com.example.digital_frame

import android.app.AlarmManager
import android.app.KeyguardManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Timer
import java.util.TimerTask

class MainActivity: FlutterActivity() {
    private val POWER_CHANNEL = "com.digitalframe/power"
    private val ALARM_CHANNEL = "com.digitalframe/alarm"
    private var originalBrightness: Float = -1f

    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName
    private lateinit var keyguardManager: KeyguardManager
    

    private var sharedPrefsTimer: Timer? = null

    companion object {
        const val NOTIFICATION_CHANNEL_ID = "slideshow_channel"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        startSharedPrefsPolling()
        Log.d("DigitalFrame", "🎬 ════════════════════════════════════════")
        Log.d("DigitalFrame", "🎬 MainActivity onCreate called")
        Log.d("DigitalFrame", "🎬 ════════════════════════════════════════")
        
        keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        Log.d("DigitalFrame", "▶️ ════════════════════════════════════════")
        Log.d("DigitalFrame", "▶️ MainActivity onResume called")
        Log.d("DigitalFrame", "▶️ ════════════════════════════════════════")
        

        startSharedPrefsPolling()
        
        handleIntent(intent)
    }

    override fun onPause() {
        super.onPause()
        Log.d("DigitalFrame", "⏸️ onPause called")

    }

    override fun onDestroy() {
        super.onDestroy()
        sharedPrefsTimer?.cancel()
        Log.d("DigitalFrame", "⏹️ MainActivity destroyed, timer cancelled")
    }


    private fun startSharedPrefsPolling() {

        sharedPrefsTimer?.cancel()
        
        sharedPrefsTimer = Timer().apply {
            scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    checkAlarmFlags()
                }
            }, 0, 1000) // İlk kontrolü hemen yap, sonra her 2 saniyede
        }
        
        Log.d("DigitalFrame", "⏱️ ════════════════════════════════════════")
        Log.d("DigitalFrame", "⏱️ SharedPreferences polling STARTED")
        Log.d("DigitalFrame", "⏱️ Checking every 2 seconds")
        Log.d("DigitalFrame", "⏱️ ════════════════════════════════════════")
    }

    private fun checkAlarmFlags() {
        val prefs = getSharedPreferences("digital_frame_prefs", Context.MODE_PRIVATE)
        val alarmAction = prefs.getString("alarm_action", null)
        
        if (alarmAction != null) {
            Log.d("DigitalFrame", "🚨 ════════════════════════════════════════")
            Log.d("DigitalFrame", "🚨 ALARM FLAG DETECTED!")
            Log.d("DigitalFrame", "🚨 Action: $alarmAction")
            Log.d("DigitalFrame", "🚨 ════════════════════════════════════════")
            
            when (alarmAction) {
                "START" -> {
                    runOnUiThread {
                        handleStartAlarm()
                    }
                    prefs.edit().remove("alarm_action").apply()
                    Log.d("DigitalFrame", "✅ START flag cleared from SharedPreferences")
                }
                "STOP" -> {
                    val useRootShutdown = prefs.getBoolean("use_root_shutdown", false)
                    runOnUiThread {
                        handleStopAlarm(useRootShutdown)
                    }
                    prefs.edit().remove("alarm_action").apply()
                    prefs.edit().remove("use_root_shutdown").apply()
                    Log.d("DigitalFrame", "✅ STOP flag cleared from SharedPreferences")
                }
                else -> {
                    Log.d("DigitalFrame", "⚠️ Unknown alarm action: $alarmAction")
                }
            }
        }

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("DigitalFrame", "✅ MainActivity configureFlutterEngine called")
        
        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, DeviceAdminReceiver::class.java)
        

        checkAlarmPermissions()
        
        createNotificationChannel()
        

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
                    val rooted = isDeviceRooted()
                    result.success(rooted)
                }
                "shutdownDevice" -> {
                    shutdownDevice()
                    result.success(null)
                }
                "isDeviceAdminActive" -> {
                    val active = devicePolicyManager.isAdminActive(adminComponent)
                    result.success(active)
                }
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin()
                    result.success(null)
                }
                "lockScreen" -> {
                    lockScreen()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }


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

    private fun checkAlarmPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
            if (!alarmManager.canScheduleExactAlarms()) {
                Log.e("DigitalFrame", "❌ SCHEDULE_EXACT_ALARM permission NOT granted!")
                Log.e("DigitalFrame", "📱 Opening alarm permission settings...")
                
                try {
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                    startActivity(intent)
                } catch (e: Exception) {
                    Log.e("DigitalFrame", "❌ Error opening alarm settings: ${e.message}")
                }
            } else {
                Log.d("DigitalFrame", "✅ SCHEDULE_EXACT_ALARM permission granted")
            }
        }
    }

    private fun requestDeviceAdmin() {
        try {
            if (!devicePolicyManager.isAdminActive(adminComponent)) {
                val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
                    putExtra(
                        DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
                        "Digital Frame uygulaması ekranı kilitlemek için Device Admin izni gerektiriyor."
                    )
                }
                startActivity(intent)
            }
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error requesting device admin: ${e.message}")
        }
    }

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
        Log.d("DigitalFrame", "🔄 onNewIntent called")
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        Log.d("DigitalFrame", "🔍 handleIntent called")
        intent?.let {
            if (it.getBooleanExtra("AUTO_START_SLIDESHOW", false)) {
                Log.d("DigitalFrame", "🎬 AUTO_START_SLIDESHOW flag detected in intent!")
                it.removeExtra("AUTO_START_SLIDESHOW")
                
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                        MethodChannel(messenger, ALARM_CHANNEL).invokeMethod("autoStartSlideshow", null)
                    }, 500)
                }
            }
            
            if (it.getBooleanExtra("AUTO_STOP_SLIDESHOW", false)) {
                Log.d("DigitalFrame", "⏹️ AUTO_STOP_SLIDESHOW flag detected in intent!")
                it.removeExtra("AUTO_STOP_SLIDESHOW")
                
                val useRootShutdown = it.getBooleanExtra("useRootShutdown", false)
                handleStopAlarm(useRootShutdown)
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
        Log.d("DigitalFrame", "🎬 ════════════════════════════════════════")
        Log.d("DigitalFrame", "🎬 START ALARM HANDLER")
        Log.d("DigitalFrame", "🎬 ════════════════════════════════════════")
        
        turnScreenOn()
        unlockScreen()
        showStartNotification()
        openAppAndStartSlideshow()
    }

    private fun unlockScreen() {
        try {
            Log.d("DigitalFrame", "🔓 Unlocking screen...")
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    keyguardManager.requestDismissKeyguard(this, null)
                }
            }
            
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
            
            Log.d("DigitalFrame", "✅ Screen unlock flags added")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error unlocking screen: ${e.message}")
        }
    }

    private fun openAppAndStartSlideshow() {
        try {
            val intent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                putExtra("AUTO_START_SLIDESHOW", true)
            }
            
            startActivity(intent)
            setIntent(intent)
            
            Log.d("DigitalFrame", "✅ App opening intent sent")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error opening app: ${e.message}")
        }
    }

    private fun handleStopAlarm(useRootShutdown: Boolean) {
        Log.d("DigitalFrame", "⏹️ ════════════════════════════════════════")
        Log.d("DigitalFrame", "⏹️ STOP ALARM HANDLER")
        Log.d("DigitalFrame", "⏹️ ════════════════════════════════════════")
        
        if (devicePolicyManager.isAdminActive(adminComponent)) {
            Log.d("DigitalFrame", "🔒 Device Admin active, locking screen...")
            lockScreen()
        } else {
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
    }

    private fun setScreenBrightness(brightness: Float) {
        try {
            val layoutParams = window.attributes
            if (originalBrightness < 0) originalBrightness = layoutParams.screenBrightness
            layoutParams.screenBrightness = brightness
            window.attributes = layoutParams
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error setting brightness: ${e.message}")
        }
    }

    private fun turnScreenOff() {
        try {
            setScreenBrightness(0.01f)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
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
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error shutting down: ${e.message}")
        }
    }
}