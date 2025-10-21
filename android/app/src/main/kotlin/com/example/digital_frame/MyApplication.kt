package com.example.digital_frame

import android.util.Log
import io.flutter.app.FlutterApplication

class MyApplication : FlutterApplication() {
    override fun onCreate() {
        super.onCreate()
        Log.d("DigitalFrame", "✅ MyApplication initialized!")
    }
}