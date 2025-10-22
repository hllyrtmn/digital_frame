import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../data/models/photo_model.dart';
import '../../providers/photo_provider.dart';
import '../../providers/settings_provider.dart';

class SlideshowScreen extends ConsumerStatefulWidget {
  const SlideshowScreen({super.key});

  @override
  ConsumerState<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends ConsumerState<SlideshowScreen> {
  Timer? _timer;
  int _currentIndex = 0;
  int _tapCount = 0;
  Timer? _doubleTapTimer;

  @override
  void initState() {
    super.initState();

    // TAM EKRAN - Hiçbir şey görünmesin
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Ekranı açık tut
    WakelockPlus.enable();

    // Auto-play başlat
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _startAutoPlay() {
    _timer?.cancel();
    final settings = ref.read(settingsProvider);

    _timer = Timer.periodic(
      Duration(seconds: settings.transitionDuration),
      (timer) {
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
      Navigator.pop(context); // Menüye dön
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
        onTap: _handleTap, // Çift tıklama kontrolü
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
