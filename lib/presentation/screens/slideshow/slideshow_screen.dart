import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../data/models/photo_model.dart';
import '../../providers/photo_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/power_provider.dart';

class SlideshowScreen extends ConsumerStatefulWidget {
  const SlideshowScreen({super.key});

  @override
  ConsumerState<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends ConsumerState<SlideshowScreen> {
  Timer? _timer;
  Timer? _timeCheckTimer;
  int _currentIndex = 0;
  int _tapCount = 0;
  Timer? _doubleTapTimer;

  @override
  void initState() {
    super.initState();

    print('🎬 Slideshow başlatılıyor...');

    // Saat aralığını kontrol et - çalışma saatinde miyiz?
    if (!_isWithinScheduledTime()) {
      print('⏰ Slideshow saat aralığı dışında başlatılmaya çalışıldı');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('⏰ Slayt gösterisi sadece belirlenen saatlerde çalışır'),
            backgroundColor: Colors.orange,
          ),
        );
      });
      return;
    }

    print('✅ Saat aralığı uygun, slideshow başlatılıyor');

    // TAM EKRAN
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Ekranı açık tut
    WakelockPlus.enable();

    // Auto-play başlat
    _startAutoPlay();

    // Her dakika saat kontrolü yap
    _startTimeCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeCheckTimer?.cancel();
    _doubleTapTimer?.cancel();

    // Normal moda dön
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // Wakelock'u kapat
    WakelockPlus.disable();

    super.dispose();
  }

  void _startTimeCheck() {
    _timeCheckTimer?.cancel();

    // Her dakika kontrol et
    _timeCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        final now = DateTime.now();
        print('⏰ Zaman kontrolü: ${now.hour}:${now.minute}');

        if (!_isWithinScheduledTime()) {
          print('🛑 Bitiş saatine ulaşıldı, slideshow kapatılıyor...');
          _stopSlideshowAndDim();
        }
      },
    );
  }

  bool _isWithinScheduledTime() {
    final settings = ref.read(settingsProvider);

    // Eğer otomatik başlatma kapalıysa, her zaman çalışsın
    if (!settings.autoStartEnabled) {
      return true;
    }

    // Eğer saat ayarlanmamışsa, her zaman çalışsın
    if (settings.startTime == null || settings.endTime == null) {
      return true;
    }

    final now = DateTime.now();
    final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

    final startTime = _parseTime(settings.startTime!);
    final endTime = _parseTime(settings.endTime!);

    if (startTime == null || endTime == null) {
      return true;
    }

    // Saat karşılaştırması
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    // Eğer bitiş saati başlangıçtan küçükse (örn: 22:00 - 08:00)
    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Normal durum (örn: 08:00 - 22:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  // ✅ DÜZELTİLDİ: Bitiş saatinde alarm callback'inin çalışmasını sağla
  Future<void> _stopSlideshowAndDim() async {
    print('⏹️ Flutter: Slideshow bitiş saatine ulaşıldı');

    // Timer'ları durdur
    _timer?.cancel();
    _timeCheckTimer?.cancel();

    final settings = ref.read(settingsProvider);

    // Eğer otomatik başlatma KAPALI ise, ekranı kendimiz karalt/kilitle
    // (Çünkü alarm callback'i schedule edilmemiş, çalışmayacak)
    if (!settings.autoStartEnabled) {
      print('💡 Otomatik başlatma kapalı - Ekranı kontrol ediyoruz');
      try {
        // Device Admin kontrolü yap
        final powerNotifier = ref.read(powerNotifierProvider.notifier);
        final powerState = ref.read(powerNotifierProvider);
        final isDeviceAdminActive =
            powerState['isDeviceAdminActive'] as bool? ?? false;

        if (isDeviceAdminActive) {
          print('🔒 Device Admin aktif - Ekranı kilitliyoruz');
          await powerNotifier.lockScreen();
        } else {
          print('💡 Device Admin yok - Ekranı karartıyoruz');
          await powerNotifier.turnScreenOff();
        }
      } catch (e) {
        print('❌ Ekran kontrolü hatası: $e');
      }
    } else {
      // Otomatik başlatma AÇIK ise:
      // - Alarm callback'i zaten schedule edilmiş
      // - Bitiş saatinde alarm tetiklenecek
      // - MainActivity'deki handleStopAlarm() ekranı kontrol edecek
      // - Biz sadece slideshow UI'sini kapatıyoruz
      print(
          '⏰ Otomatik başlatma açık - Alarm callback\'i ekranı kontrol edecek');
      print(
          '   (MainActivity.handleStopAlarm() Device Admin kontrolü yapacak)');
    }

    // Ekrandan çık
    if (mounted) {
      Navigator.pop(context);
      print('✅ Slideshow ekranı kapatıldı');
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    final settings = ref.read(settingsProvider);

    _timer = Timer.periodic(
      Duration(seconds: settings.transitionDuration),
      (timer) {
        // Her fotoğraf değişiminde de saat kontrolü yap
        if (!_isWithinScheduledTime()) {
          _stopSlideshowAndDim();
          return;
        }

        final photos = ref.read(photoProvider);
        if (photos.isEmpty) return;

        setState(() {
          _currentIndex = (_currentIndex + 1) % photos.length;
        });
      },
    );
  }

  // ÇİFT TIKLA - Menüye Dön
  void _handleTap() {
    _tapCount++;

    if (_tapCount == 1) {
      _doubleTapTimer = Timer(const Duration(milliseconds: 300), () {
        _tapCount = 0;
      });
    } else if (_tapCount == 2) {
      _doubleTapTimer?.cancel();
      _tapCount = 0;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = ref.watch(photoProvider);
    final settings = ref.watch(settingsProvider);

    if (photos.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.photo_library_outlined, size: 80),
              const SizedBox(height: 16),
              const Text('Gösterilecek fotoğraf yok'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _handleTap,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return _buildTransition(
                  child, animation, settings.transitionEffect);
            },
            child: _buildPhotoWidget(photos[_currentIndex]),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(PhotoModel photo) {
    return Container(
      key: ValueKey(photo.id),
      color: Colors.black,
      child: Center(
        child: Image.file(
          File(photo.path),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.broken_image,
              size: 100,
              color: Colors.white54,
            );
          },
        ),
      ),
    );
  }

  Widget _buildTransition(
      Widget child, Animation<double> animation, String effect) {
    switch (effect) {
      case 'fade':
        return FadeTransition(opacity: animation, child: child);
      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: child,
        );
      case 'zoom':
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
          child: FadeTransition(opacity: animation, child: child),
        );
      case 'none':
      default:
        return child;
    }
  }
}
