import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/slideshow/slideshow_screen.dart';
import 'presentation/providers/alarm_provider.dart';
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
      if (call.method == 'autoStartSlideshow') {
        // Slideshow'u otomatik aç
        final context = navigatorKey.currentContext;
        if (context != null) {
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
