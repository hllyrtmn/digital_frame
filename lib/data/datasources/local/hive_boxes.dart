import 'package:hive_flutter/hive_flutter.dart';
import '../../models/photo_model.dart';
import '../../models/settings_model.dart';
import '../../../core/constants/app_constants.dart';

class HiveBoxes {
  static Box<PhotoModel>? _photosBox;
  static Box<SettingsModel>? _settingsBox;

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(PhotoModelAdapter());
    Hive.registerAdapter(SettingsModelAdapter());

    _photosBox = await Hive.openBox<PhotoModel>(AppConstants.photosBoxName);
    _settingsBox =
        await Hive.openBox<SettingsModel>(AppConstants.settingsBoxName);

    if (_settingsBox!.isEmpty) {
      await _settingsBox!.put('default', SettingsModel());
    }
  }

  static Box<PhotoModel> get photosBox {
    if (_photosBox == null || !_photosBox!.isOpen) {
      throw Exception('Photos box is not initialized');
    }
    return _photosBox!;
  }

  static Box<SettingsModel> get settingsBox {
    if (_settingsBox == null || !_settingsBox!.isOpen) {
      throw Exception('Settings box is not initialized');
    }
    return _settingsBox!;
  }
}
