import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/providers/alarm_provider.dart';

class DigitalFrameApp extends ConsumerWidget {
  const DigitalFrameApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize services
    ref.watch(servicesInitProvider);

    return MaterialApp(
      title: 'Digital Frame',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
