import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/services.dart';

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

  // START CALLBACK - Basit tutuyoruz, sadece native kod
  @pragma('vm:entry-point')
  static void startSlideshowCallback() {
    print('🎬 START ALARM TRIGGERED!');

    // MethodChannel ile native koda gönder
    const platform = MethodChannel('com.digitalframe/alarm');
    try {
      platform.invokeMethod('onStartAlarm');
    } catch (e) {
      print('❌ Start callback error: $e');
    }
  }

  // STOP CALLBACK - Basit tutuyoruz, sadece native kod
  @pragma('vm:entry-point')
  static void stopSlideshowCallback() {
    print('⏹️ STOP ALARM TRIGGERED!');

    // MethodChannel ile native koda gönder
    const platform = MethodChannel('com.digitalframe/alarm');
    try {
      // Root shutdown flag'ini de gönder
      platform
          .invokeMethod('onStopAlarm', {'useRootShutdown': _useRootShutdown});
    } catch (e) {
      print('❌ Stop callback error: $e');
    }
  }

  Future<void> scheduleAlarms({
    required String startTime,
    required String endTime,
    required bool useRootShutdown,
  }) async {
    _useRootShutdown = useRootShutdown;
    setRootShutdown(useRootShutdown);

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

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      _startAlarmId,
      startSlideshowCallback,
      startAt: startDateTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      _stopAlarmId,
      stopSlideshowCallback,
      startAt: endDateTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    print('✅ Alarms scheduled:');
    print('   Start: $startDateTime → Ekranı aç + Notification göster');
    print(
        '   Stop: $endDateTime → Ekranı karart ${useRootShutdown ? "+ Cihazı kapat" : ""}');
  }

  Future<void> cancelAlarms() async {
    await AndroidAlarmManager.cancel(_startAlarmId);
    await AndroidAlarmManager.cancel(_stopAlarmId);
    print('❌ Alarms cancelled');
  }
}
