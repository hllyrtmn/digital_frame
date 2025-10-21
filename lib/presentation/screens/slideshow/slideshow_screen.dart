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
  bool _isPlaying = true;
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();

    // Tam ekran yap
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Ekranı açık tut
    WakelockPlus.enable();

    // Auto-play başlat
    _startAutoPlay();

    // Kontrolleri otomatik gizle
    _startControlsTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controlsTimer?.cancel();

    // Normal moda dön
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // Wakelock'u kapat
    WakelockPlus.disable();

    super.dispose();
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _showControlsTemporarily() {
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
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

  void _stopAutoPlay() {
    _timer?.cancel();
  }

  void _goToNext() {
    final photos = ref.read(photoProvider);
    setState(() {
      _currentIndex = (_currentIndex + 1) % photos.length;
    });
    _showControlsTemporarily();
  }

  void _goToPrevious() {
    final photos = ref.read(photoProvider);
    setState(() {
      _currentIndex = (_currentIndex - 1 + photos.length) % photos.length;
    });
    _showControlsTemporarily();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startAutoPlay();
      } else {
        _stopAutoPlay();
      }
    });
    _showControlsTemporarily();
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
        onTap: _showControlsTemporarily,
        onHorizontalDragEnd: (details) {
          // Swipe gesture
          if (details.primaryVelocity! > 0) {
            _goToPrevious();
          } else if (details.primaryVelocity! < 0) {
            _goToNext();
          }
        },
        child: Stack(
          children: [
            // Slideshow with AnimatedSwitcher
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  return _buildTransition(
                    child,
                    animation,
                    settings.transitionEffect,
                  );
                },
                child: _buildPhotoWidget(photos[_currentIndex]),
              ),
            ),

            // Controls overlay
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildControls(photos.length),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(PhotoModel photo) {
    // Key önemli! AnimatedSwitcher'ın ne zaman değiştiğini anlaması için
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
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        );

      case 'zoom':
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );

      case 'none':
      default:
        return child;
    }
  }

  Widget _buildControls(int photoCount) {
    return Stack(
      children: [
        // Top bar - Photo counter
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentIndex + 1} / $photoCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar - Controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      color: Colors.white, size: 32),
                  onPressed: _goToPrevious,
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      color: Colors.white, size: 32),
                  onPressed: _goToNext,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
