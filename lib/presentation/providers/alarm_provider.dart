import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/alarm_service.dart';
import '../../core/services/notification_service.dart';
import 'settings_provider.dart';

final alarmServiceProvider = Provider((ref) => AlarmService());

final alarmStatusProvider = StateProvider<bool>((ref) => false);

final servicesInitProvider = FutureProvider<void>((ref) async {
  await NotificationService().initialize();
  await AlarmService().initialize();
});

class AlarmNotifier extends StateNotifier<bool> {
  final AlarmService _alarmService;
  final Ref _ref;

  AlarmNotifier(this._alarmService, this._ref) : super(false);

  Future<void> updateAlarms() async {
    final settings = _ref.read(settingsProvider);

    if (settings.autoStartEnabled &&
        settings.startTime != null &&
        settings.endTime != null) {
      await _alarmService.scheduleAlarms(
        startTime: settings.startTime!,
        endTime: settings.endTime!,
        useRootShutdown: settings.useRootShutdown, // ✅ EKLENDI
      );
      state = true;
    } else {
      await _alarmService.cancelAlarms();
      state = false;
    }
  }

  Future<void> cancelAlarms() async {
    await _alarmService.cancelAlarms();
    state = false;
  }
}

final alarmNotifierProvider = StateNotifierProvider<AlarmNotifier, bool>((ref) {
  final alarmService = ref.watch(alarmServiceProvider);
  return AlarmNotifier(alarmService, ref);
});
