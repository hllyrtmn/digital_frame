import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/settings_model.dart';
import '../../data/datasources/local/settings_local_datasource.dart';

final settingsDataSourceProvider = Provider((ref) => SettingsLocalDataSource());

class SettingsNotifier extends StateNotifier<SettingsModel> {
  final SettingsLocalDataSource _dataSource;

  SettingsNotifier(this._dataSource) : super(SettingsModel()) {
    _loadSettings();
  }

  void _loadSettings() {
    state = _dataSource.getSettings();
  }

  Future<void> updateTransitionDuration(int duration) async {
    final updated = state.copyWith(transitionDuration: duration);
    await _dataSource.updateSettings(updated);
    state = updated;
  }

  Future<void> updateTransitionEffect(String effect) async {
    final updated = state.copyWith(transitionEffect: effect);
    await _dataSource.updateSettings(updated);
    state = updated;
  }

  Future<void> updateSchedule({
    String? startTime,
    String? endTime,
    bool? autoStartEnabled,
  }) async {
    final updated = state.copyWith(
      startTime: startTime,
      endTime: endTime,
      autoStartEnabled: autoStartEnabled,
    );
    await _dataSource.updateSettings(updated);
    state = updated;
  }

  Future<void> toggleRootShutdown(bool value) async {
    final updated = state.copyWith(useRootShutdown: value);
    await _dataSource.updateSettings(updated);
    state = updated;
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsModel>((ref) {
  final dataSource = ref.watch(settingsDataSourceProvider);
  return SettingsNotifier(dataSource);
});
