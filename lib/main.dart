import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/datasources/local/hive_boxes.dart';
import 'app.dart';

void main() async {
  print('=== UYGULAMA BAŞLADI ===');
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    // Initialize Hive
    await HiveBoxes.init();
    print('✅ Hive initialized successfully');
  } catch (e) {
    print('❌ Hive initialization failed: $e');
  }

  runApp(
    const ProviderScope(
      child: DigitalFrameApp(),
    ),
  );
}
