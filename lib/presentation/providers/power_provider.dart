import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/power_manager_service.dart';

final powerServiceProvider = Provider((ref) => PowerManagerService());

final rootStatusProvider = FutureProvider<bool>((ref) async {
  final powerService = ref.watch(powerServiceProvider);
  return await powerService.isRooted();
});

// ✅ YENİ: Device Admin status provider
final deviceAdminStatusProvider = FutureProvider<bool>((ref) async {
  final powerService = ref.watch(powerServiceProvider);
  return await powerService.isDeviceAdminActive();
});

class PowerNotifier extends StateNotifier<Map<String, dynamic>> {
  final PowerManagerService _powerService;

  PowerNotifier(this._powerService)
      : super({
          'isScreenOn': true,
          'brightness': 1.0,
          'dndEnabled': false,
          'isDeviceAdminActive': false,
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

  Future<void> shutdownDevice() async {
    await _powerService.shutdownDevice();
  }

  // ✅ YENİ: Device Admin metodları
  Future<void> requestDeviceAdmin() async {
    await _powerService.requestDeviceAdmin();
  }

  Future<void> lockScreen() async {
    await _powerService.lockScreen();
  }

  Future<void> checkDeviceAdminStatus() async {
    final active = await _powerService.isDeviceAdminActive();
    state = {...state, 'isDeviceAdminActive': active};
  }
}

final powerNotifierProvider =
    StateNotifierProvider<PowerNotifier, Map<String, dynamic>>((ref) {
  final powerService = ref.watch(powerServiceProvider);
  return PowerNotifier(powerService);
});
