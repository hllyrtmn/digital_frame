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

    if (!_isWithinScheduledTime()) {
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

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    WakelockPlus.enable();

    _startAutoPlay();

    _startTimeCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timeCheckTimer?.cancel();
    _doubleTapTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    WakelockPlus.disable();

    super.dispose();
  }

  void _startTimeCheck() {
    _timeCheckTimer?.cancel();

    _timeCheckTimer = Timer.periodic(
      const Duration(minutes: 1),
      (timer) {
        if (!_isWithinScheduledTime()) {
          _stopSlideshowAndDim();
        }
      },
    );
  }

  bool _isWithinScheduledTime() {
    final settings = ref.read(settingsProvider);

    if (!settings.autoStartEnabled) {
      return true;
    }

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

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes < startMinutes) {
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
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

  Future<void> _stopSlideshowAndDim() async {
    _timer?.cancel();
    _timeCheckTimer?.cancel();

    final settings = ref.read(settingsProvider);

    if (!settings.autoStartEnabled) {
      try {
        final powerNotifier = ref.read(powerNotifierProvider.notifier);
        final powerState = ref.read(powerNotifierProvider);
        final isDeviceAdminActive =
            powerState['isDeviceAdminActive'] as bool? ?? false;

        if (isDeviceAdminActive) {
          await powerNotifier.lockScreen();
        } else {
          await powerNotifier.turnScreenOff();
        }
      } catch (e) {}
    } else {
      print(
          '⏰ Otomatik başlatma açık - Alarm callback\'i ekranı kontrol edecek');
      print(
          '   (MainActivity.handleStopAlarm() Device Admin kontrolü yapacak)');
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    final settings = ref.read(settingsProvider);

    _timer = Timer.periodic(
      Duration(seconds: settings.transitionDuration),
      (timer) {
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
