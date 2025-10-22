import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/slideshow/slideshow_screen.dart';
import 'presentation/providers/alarm_provider.dart';
import 'presentation/providers/photo_provider.dart';
import 'main.dart';

class DigitalFrameApp extends ConsumerStatefulWidget {
  const DigitalFrameApp({super.key});

  @override
  ConsumerState<DigitalFrameApp> createState() => _DigitalFrameAppState();
}

class _DigitalFrameAppState extends ConsumerState<DigitalFrameApp> {
  @override
  void initState() {
    super.initState();

    // Alarm kanalını dinle
    const platform = MethodChannel('com.digitalframe/alarm');
    platform.setMethodCallHandler((call) async {
      print('📞 Flutter received: ${call.method}');

      if (call.method == 'autoStartSlideshow') {
        print('🎬 Auto-starting slideshow in Flutter!');

        // Fotoğraf var mı kontrol et
        final photos = ref.read(photoProvider);
        if (photos.isEmpty) {
          print('❌ No photos to show');
          return;
        }

        // Slideshow'u aç
        await Future.delayed(const Duration(milliseconds: 500));
        final context = navigatorKey.currentContext;
        if (context != null && mounted) {
          print('✅ Navigating to slideshow...');
          // ignore: use_build_context_synchronously
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SlideshowScreen()),
            (route) => false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(servicesInitProvider);

    return MaterialApp(
      title: 'Digital Frame',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
      routes: {
        '/slideshow': (context) => const SlideshowScreen(),
      },
    );
  }
}
