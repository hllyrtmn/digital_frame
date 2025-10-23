import 'package:flutter/services.dart';

class PowerManagerService {
  static final PowerManagerService _instance = PowerManagerService._internal();
  factory PowerManagerService() => _instance;
  PowerManagerService._internal();

  static const _channel = MethodChannel('com.digitalframe/power');

  Future<void> setScreenBrightness(double brightness) async {
    try {
      await _channel.invokeMethod('setScreenBrightness', {
        'brightness': brightness.clamp(0.0, 1.0),
      });
    } catch (e) {
      print('Error setting brightness: $e');
    }
  }

  Future<void> turnScreenOff() async {
    try {
      await _channel.invokeMethod('turnScreenOff');
    } catch (e) {
      print('Error turning screen off: $e');
    }
  }

  Future<void> turnScreenOn() async {
    try {
      await _channel.invokeMethod('turnScreenOn');
    } catch (e) {
      print('Error turning screen on: $e');
    }
  }

  Future<bool> isRooted() async {
    try {
      final result = await _channel.invokeMethod('isRooted');
      return result as bool;
    } catch (e) {
      print('Error checking root: $e');
      return false;
    }
  }

  Future<void> shutdownDevice() async {
    try {
      await _channel.invokeMethod('shutdownDevice');
    } catch (e) {
      print('Error shutting down: $e');
    }
  }

  // ✅ YENİ: Device Admin metodları
  Future<bool> isDeviceAdminActive() async {
    try {
      final result = await _channel.invokeMethod('isDeviceAdminActive');
      return result as bool;
    } catch (e) {
      print('Error checking device admin: $e');
      return false;
    }
  }

  Future<void> requestDeviceAdmin() async {
    try {
      await _channel.invokeMethod('requestDeviceAdmin');
    } catch (e) {
      print('Error requesting device admin: $e');
    }
  }

  Future<void> lockScreen() async {
    try {
      await _channel.invokeMethod('lockScreen');
    } catch (e) {
      print('Error locking screen: $e');
    }
  }
}
