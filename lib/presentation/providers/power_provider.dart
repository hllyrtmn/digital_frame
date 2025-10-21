import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/power_manager_service.dart';

// Power service provider
final powerServiceProvider = Provider((ref) => PowerManagerService());

// Root status provider
final rootStatusProvider = FutureProvider<bool>((ref) async {
  final powerService = ref.watch(powerServiceProvider);
  return await powerService.isRooted();
});

// Power management notifier
class PowerNotifier extends StateNotifier<Map<String, dynamic>> {
  final PowerManagerService _powerService;

  PowerNotifier(this._powerService)
      : super({
          'isScreenOn': true,
          'brightness': 1.0,
          'dndEnabled': false,
        });

  Future<void> setBrightness(double brightness) async {
    await _powerService.setScreenBrightness(brightness);
    state = {...state, 'brightness': brightness};
  }

  Future<void> turnScreenOff() async {
    await _powerService.turnScreenOff();
    state = {...state, 'isScreenOn': false};
  }

  Future<void> turnScreenOn() async {
    await _powerService.turnScreenOn();
    state = {...state, 'isScreenOn': true};
  }

  Future<void> toggleDoNotDisturb(bool enable) async {
    await _powerService.setDoNotDisturb(enable);
    state = {...state, 'dndEnabled': enable};
  }

  Future<void> shutdownDevice() async {
    await _powerService.shutdownDevice();
  }
}

final powerNotifierProvider =
    StateNotifierProvider<PowerNotifier, Map<String, dynamic>>((ref) {
  final powerService = ref.watch(powerServiceProvider);
  return PowerNotifier(powerService);
});
