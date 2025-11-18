import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

@pragma('vm:entry-point')
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const int _startAlarmId = 100;
  static const int _stopAlarmId = 101;
  static bool _useRootShutdown = false;

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  void setRootShutdown(bool value) {
    _useRootShutdown = value;
  }

  @pragma('vm:entry-point')
  static Future<void> startSlideshowCallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_action', 'START');
      await prefs.setInt(
          'alarm_timestamp', DateTime.now().millisecondsSinceEpoch);

      try {
        const platform = MethodChannel('android.intent.action.VIEW');
        await platform.invokeMethod('launchApp', {
          'package': 'com.example.digital_frame',
          'action': 'START_SLIDESHOW',
        });
      } catch (e) {}
    } catch (e) {}
  }

  @pragma('vm:entry-point')
  static Future<void> stopSlideshowCallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('alarm_action', 'STOP');
      await prefs.setBool('use_root_shutdown', _useRootShutdown);
      await prefs.setInt(
          'alarm_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {}
  }

  Future<void> scheduleAlarms({
    required String startTime,
    required String endTime,
    required bool useRootShutdown,
  }) async {
    _useRootShutdown = useRootShutdown;

    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    final now = DateTime.now();

    var startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    if (startDateTime.isBefore(now)) {
      startDateTime = startDateTime.add(const Duration(days: 1));
    }

    var endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    if (endDateTime.isBefore(now)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    try {
      await AndroidAlarmManager.cancel(_startAlarmId);
      await AndroidAlarmManager.cancel(_stopAlarmId);

      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _startAlarmId,
        startSlideshowCallback,
        startAt: startDateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );

      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _stopAlarmId,
        stopSlideshowCallback,
        startAt: endDateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
        allowWhileIdle: true,
      );

      if (useRootShutdown) {}
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelAlarms() async {
    try {
      await AndroidAlarmManager.cancel(_startAlarmId);
      await AndroidAlarmManager.cancel(_stopAlarmId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('alarm_action');
      await prefs.remove('use_root_shutdown');
      await prefs.remove('alarm_timestamp');
    } catch (e) {
      rethrow;
    }
  }
}
