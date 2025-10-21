import 'package:flutter/services.dart';

class PowerManagerService {
  static final PowerManagerService _instance = PowerManagerService._internal();
  factory PowerManagerService() => _instance;
  PowerManagerService._internal();

  static const _channel = MethodChannel('com.digitalframe/power');

  // Ekran parlaklığını ayarla (0.0 - 1.0)
  Future<void> setScreenBrightness(double brightness) async {
    try {
      await _channel.invokeMethod('setScreenBrightness', {
        'brightness': brightness.clamp(0.0, 1.0),
      });
    } catch (e) {
      print('Error setting brightness: $e');
    }
  }

  // Ekranı kapat (screen off)
  Future<void> turnScreenOff() async {
    try {
      await _channel.invokeMethod('turnScreenOff');
    } catch (e) {
      print('Error turning screen off: $e');
    }
  }

  // Ekranı aç (screen on)
  Future<void> turnScreenOn() async {
    try {
      await _channel.invokeMethod('turnScreenOn');
    } catch (e) {
      print('Error turning screen on: $e');
    }
  }

  // Do Not Disturb mode aç/kapat
  Future<void> setDoNotDisturb(bool enable) async {
    try {
      await _channel.invokeMethod('setDoNotDisturb', {
        'enable': enable,
      });
    } catch (e) {
      print('Error setting DND: $e');
    }
  }

  // Root kontrolü
  Future<bool> isRooted() async {
    try {
      final result = await _channel.invokeMethod('isRooted');
      return result as bool;
    } catch (e) {
      print('Error checking root: $e');
      return false;
    }
  }

  // Root shutdown (sadece root cihazlar)
  Future<void> shutdownDevice() async {
    try {
      await _channel.invokeMethod('shutdownDevice');
    } catch (e) {
      print('Error shutting down: $e');
    }
  }
}
