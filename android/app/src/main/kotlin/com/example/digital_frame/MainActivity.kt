package com.example.digital_frame

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.digitalframe/power"
    private var originalBrightness: Float = -1f

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("DigitalFrame", "✅ MainActivity initialized!")
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            Log.d("DigitalFrame", "📞 Method called: ${call.method}")
            
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
                "setDoNotDisturb" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    setDoNotDisturb(enable)
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
                else -> {
                    Log.d("DigitalFrame", "❌ Method not implemented: ${call.method}")
                    result.notImplemented()
                }
            }
        }
    }

    private fun setScreenBrightness(brightness: Float) {
        try {
            val window = window
            val layoutParams = window.attributes
            
            if (originalBrightness < 0) {
                originalBrightness = layoutParams.screenBrightness
            }
            
            layoutParams.screenBrightness = brightness
            window.attributes = layoutParams
            Log.d("DigitalFrame", "✅ Brightness set to: $brightness")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error setting brightness: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun turnScreenOff() {
        try {
            setScreenBrightness(0.01f)
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            window.clearFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
            Log.d("DigitalFrame", "✅ Screen turned off")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error turning screen off: ${e.message}")
            e.printStackTrace()
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
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
            Log.d("DigitalFrame", "✅ Screen turned on")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error turning screen on: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun setDoNotDisturb(enable: Boolean) {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (notificationManager.isNotificationPolicyAccessGranted) {
                    val interruptionFilter = if (enable) {
                        NotificationManager.INTERRUPTION_FILTER_NONE
                    } else {
                        NotificationManager.INTERRUPTION_FILTER_ALL
                    }
                    notificationManager.setInterruptionFilter(interruptionFilter)
                    Log.d("DigitalFrame", "✅ DND set to: $enable")
                } else {
                    val intent = android.content.Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                    startActivity(intent)
                    Log.d("DigitalFrame", "⚠️ DND permission not granted, opening settings")
                }
            }
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error setting DND: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun isDeviceRooted(): Boolean {
        return checkRootMethod1() || checkRootMethod2() || checkRootMethod3()
    }

    private fun checkRootMethod1(): Boolean {
        val buildTags = Build.TAGS
        return buildTags != null && buildTags.contains("test-keys")
    }

    private fun checkRootMethod2(): Boolean {
        val paths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        for (path in paths) {
            if (File(path).exists()) return true
        }
        return false
    }

    private fun checkRootMethod3(): Boolean {
        var process: Process? = null
        return try {
            process = Runtime.getRuntime().exec(arrayOf("/system/xbin/which", "su"))
            val input = java.io.BufferedReader(java.io.InputStreamReader(process.inputStream))
            input.readLine() != null
        } catch (t: Throwable) {
            false
        } finally {
            process?.destroy()
        }
    }

    private fun shutdownDevice() {
        try {
            Runtime.getRuntime().exec(arrayOf("su", "-c", "reboot -p"))
            Log.d("DigitalFrame", "✅ Shutdown command executed")
        } catch (e: Exception) {
            Log.e("DigitalFrame", "❌ Error shutting down: ${e.message}")
            try {
                val intent = android.content.Intent("android.intent.action.ACTION_REQUEST_SHUTDOWN")
                intent.putExtra("android.intent.extra.KEY_CONFIRM", false)
                intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK
                startActivity(intent)
            } catch (ex: Exception) {
                Log.e("DigitalFrame", "❌ Fallback shutdown failed: ${ex.message}")
                ex.printStackTrace()
            }
        }
    }
}