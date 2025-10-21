import 'package:hive/hive.dart';

part 'settings_model.g.dart';

@HiveType(typeId: 1)
class SettingsModel extends HiveObject {
  @HiveField(0)
  int transitionDuration; // seconds

  @HiveField(1)
  String transitionEffect;

  @HiveField(2)
  bool autoStartEnabled;

  @HiveField(3)
  String? startTime; // Format: "HH:mm"

  @HiveField(4)
  String? endTime; // Format: "HH:mm"

  @HiveField(5)
  bool useRootShutdown; // Root cihazlar için

  SettingsModel({
    this.transitionDuration = 3,
    this.transitionEffect = 'fade',
    this.autoStartEnabled = false,
    this.startTime,
    this.endTime,
    this.useRootShutdown = false,
  });

  SettingsModel copyWith({
    int? transitionDuration,
    String? transitionEffect,
    bool? autoStartEnabled,
    String? startTime,
    String? endTime,
    bool? useRootShutdown,
  }) {
    return SettingsModel(
      transitionDuration: transitionDuration ?? this.transitionDuration,
      transitionEffect: transitionEffect ?? this.transitionEffect,
      autoStartEnabled: autoStartEnabled ?? this.autoStartEnabled,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      useRootShutdown: useRootShutdown ?? this.useRootShutdown,
    );
  }
}
