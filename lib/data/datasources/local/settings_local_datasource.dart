import 'package:hive/hive.dart';
import '../../models/settings_model.dart';
import 'hive_boxes.dart';

class SettingsLocalDataSource {
  final Box<SettingsModel> _box = HiveBoxes.settingsBox;
  static const String _defaultKey = 'default';

  SettingsModel getSettings() {
    return _box.get(_defaultKey) ?? SettingsModel();
  }

  Future<void> updateSettings(SettingsModel settings) async {
    await _box.put(_defaultKey, settings);
  }
}
