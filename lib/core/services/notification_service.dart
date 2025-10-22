import 'package:flutter/material.dart'; // ✅ Navigator için
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../main.dart'; // ✅ navigatorKey için - EN ÜSTTE

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.notification.request();
    if (status.isDenied) {
      print('Notification permission denied');
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');

    if (response.payload == 'start_slideshow') {
      // Slideshow'u başlat
      _openSlideshow();
    }
  }

  void _openSlideshow() {
    // Global navigator key kullanarak slideshow'u aç
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.pushNamed(context, '/slideshow');
    }
  }

  Future<void> showSlideshowStartNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'slideshow_channel',
      'Slideshow',
      channelDescription: 'Digital frame slideshow notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
      autoCancel: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Digital Frame',
      'Slayt gösterisi başlatılıyor... Dokun!',
      details,
      payload: 'start_slideshow',
    );
  }

  Future<void> showSlideshowStopNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'slideshow_channel',
      'Slideshow',
      channelDescription: 'Digital frame slideshow notifications',
      importance: Importance.low,
      priority: Priority.low,
      showWhen: false,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      'Digital Frame',
      'Ekran kapatıldı. Yarın görüşürüz! 😴',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
