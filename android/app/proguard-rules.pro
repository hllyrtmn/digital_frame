# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

# Keep MainActivity
-keep class com.example.digital_frame.MainActivity { *; }
-keep class com.example.digital_frame.MyApplication { *; }

# AndroidAlarmManager
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }

# Hive
-keep class * extends com.hivedb.** { *; }
-keepclassmembers class * extends com.hivedb.** { *; }

# Keep method names for MethodChannel
-keepclassmembers class * {
  @io.flutter.embedding.engine.FlutterEngine *;
}