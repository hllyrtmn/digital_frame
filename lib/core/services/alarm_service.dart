import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'notification_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const int _startAlarmId = 100;
  static const int _stopAlarmId = 101;

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  // Alarm callback'leri (static olmalı)
  @pragma('vm:entry-point')
  static void startSlideshowCallback() {
    print('🎬 Start slideshow alarm triggered!');
    NotificationService().showSlideshowStartNotification();
    // TODO: Slideshow'u başlat
  }

  @pragma('vm:entry-point')
  static void stopSlideshowCallback() {
    print('⏹️ Stop slideshow alarm triggered!');
    NotificationService().showSlideshowStopNotification();
    // TODO: Slideshow'u durdur
  }

  Future<void> scheduleAlarms({
    required String startTime,
    required String endTime,
  }) async {
    // Parse times
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');

    final now = DateTime.now();

    // Start time
    var startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );

    // Eğer start time geçmişse, yarına ayarla
    if (startDateTime.isBefore(now)) {
      startDateTime = startDateTime.add(const Duration(days: 1));
    }

    // End time
    var endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    // Eğer end time geçmişse, yarına ayarla
    if (endDateTime.isBefore(now)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    // Schedule start alarm (günlük tekrar)
    await AndroidAlarmManager.periodic(
      const Duration(days: 1),
      _startAlarmId,
      startSlideshowCallback,
      startAt: startDateTime,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );

    // Schedule stop alarm (günlük tekrar)
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
    print('   Start: $startDateTime');
    print('   Stop: $endDateTime');
  }

  Future<void> cancelAlarms() async {
    await AndroidAlarmManager.cancel(_startAlarmId);
    await AndroidAlarmManager.cancel(_stopAlarmId);
    print('❌ Alarms cancelled');
  }

  Future<bool> hasScheduledAlarms() async {
    // Bu method tam olarak çalışmayabilir, alternatif kontrol gerekebilir
    return true; // Şimdilik her zaman true döndür
  }
}
