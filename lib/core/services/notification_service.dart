import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Request permission (Android 13+)
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
    // Burada slideshow başlatma logic'i gelecek
  }

  Future<void> showSlideshowStartNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'slideshow_channel',
      'Slideshow',
      channelDescription: 'Digital frame slideshow notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      'Digital Frame',
      'Slayt gösterisi başlatılıyor...',
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
      'Slayt gösterisi durduruldu',
      details,
      payload: 'stop_slideshow',
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
