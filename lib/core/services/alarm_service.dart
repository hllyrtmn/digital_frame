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
    print('🔔 AlarmService initializing...');
    await AndroidAlarmManager.initialize();
    print('✅ AlarmService initialized');
  }

  void setRootShutdown(bool value) {
    _useRootShutdown = value;
    print('🔧 Root shutdown set to: $value');
  }

  // START CALLBACK - Native koda alarm tetiklendiğini bildir
  @pragma('vm:entry-point')
  static void startSlideshowCallback() {
    final now = DateTime.now();
    print('🎬 ═══════════════════════════════════════════════');
    print('🎬 START ALARM TRIGGERED!');
    print('🎬 Time: ${now.hour}:${now.minute}:${now.second}');
    print('🎬 Date: ${now.day}/${now.month}/${now.year}');
    print('🎬 ═══════════════════════════════════════════════');

    // Native koda gönder - MainActivity.handleStartAlarm() çağrılacak
    const platform = MethodChannel('com.digitalframe/alarm');
    try {
      platform.invokeMethod('onStartAlarm');
      print('✅ onStartAlarm invoked successfully');
    } catch (e) {
      print('❌ Start callback error: $e');
    }
  }

  // STOP CALLBACK - Native koda alarm tetiklendiğini bildir
  @pragma('vm:entry-point')
  static void stopSlideshowCallback() {
    final now = DateTime.now();
    print('⏹️ ═══════════════════════════════════════════════');
    print('⏹️ STOP ALARM TRIGGERED!');
    print('⏹️ Time: ${now.hour}:${now.minute}:${now.second}');
    print('⏹️ Date: ${now.day}/${now.month}/${now.year}');
    print('⏹️ Root shutdown: $_useRootShutdown');
    print('⏹️ ═══════════════════════════════════════════════');

    // Native koda gönder - MainActivity.handleStopAlarm() çağrılacak
    const platform = MethodChannel('com.digitalframe/alarm');
    try {
      platform.invokeMethod('onStopAlarm', {
        'useRootShutdown': _useRootShutdown,
      });
      print('✅ onStopAlarm invoked successfully');
    } catch (e) {
      print('❌ Stop callback error: $e');
    }
  }

  Future<void> scheduleAlarms({
    required String startTime,
    required String endTime,
    required bool useRootShutdown,
  }) async {
    print('📅 ═══════════════════════════════════════════════');
    print('📅 SCHEDULING ALARMS');
    print('📅 Start time: $startTime');
    print('📅 End time: $endTime');
    print('📅 Root shutdown: $useRootShutdown');
    print('📅 ═══════════════════════════════════════════════');

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
      print('⏭️ Start time is in the past, scheduling for tomorrow');
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
      print('⏭️ End time is in the past, scheduling for tomorrow');
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    print('📍 Current time: ${now.hour}:${now.minute}:${now.second}');
    print(
        '🎬 Start alarm scheduled for: ${startDateTime.day}/${startDateTime.month} ${startDateTime.hour}:${startDateTime.minute}');
    print(
        '⏹️ Stop alarm scheduled for: ${endDateTime.day}/${endDateTime.month} ${endDateTime.hour}:${endDateTime.minute}');

    try {
      // Start alarm
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _startAlarmId,
        startSlideshowCallback,
        startAt: startDateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      print('✅ Start alarm scheduled successfully');

      // Stop alarm
      await AndroidAlarmManager.periodic(
        const Duration(days: 1),
        _stopAlarmId,
        stopSlideshowCallback,
        startAt: endDateTime,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      print('✅ Stop alarm scheduled successfully');

      print('📅 ═══════════════════════════════════════════════');
      print('✅ ALARMS SCHEDULED SUCCESSFULLY');
      print('   → Slideshow will auto-start at $startTime');
      print('   → Slideshow will auto-stop at $endTime');
      if (useRootShutdown) {
        print('   → Device will SHUTDOWN at stop time (root)');
      }
      print('📅 ═══════════════════════════════════════════════');
    } catch (e) {
      print('❌ Error scheduling alarms: $e');
      rethrow;
    }
  }

  Future<void> cancelAlarms() async {
    print('🚫 Cancelling alarms...');

    try {
      await AndroidAlarmManager.cancel(_startAlarmId);
      print('✅ Start alarm cancelled');

      await AndroidAlarmManager.cancel(_stopAlarmId);
      print('✅ Stop alarm cancelled');

      print('🚫 All alarms cancelled successfully');
    } catch (e) {
      print('❌ Error cancelling alarms: $e');
      rethrow;
    }
  }
}
