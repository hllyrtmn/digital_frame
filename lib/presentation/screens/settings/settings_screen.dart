import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/alarm_provider.dart';
import '../../providers/power_provider.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final alarmActive = ref.watch(alarmNotifierProvider);
    final rootStatus = ref.watch(rootStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          // Slideshow Settings Section
          _buildSectionHeader(context, 'Slayt Gösterisi'),

          // Transition Duration
          ListTile(
            title: const Text('Geçiş Süresi'),
            subtitle: Text('${settings.transitionDuration} saniye'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.transitionDuration.toDouble(),
                min: 1,
                max: 30,
                divisions: 29,
                label: '${settings.transitionDuration}s',
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .updateTransitionDuration(value.toInt());
                },
              ),
            ),
          ),

          // Transition Effect
          ListTile(
            title: const Text('Geçiş Efekti'),
            subtitle: Text(_getEffectName(settings.transitionEffect)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: AppConstants.transitionEffects.map((effect) {
                final isSelected = settings.transitionEffect == effect;
                return ChoiceChip(
                  label: Text(_getEffectName(effect)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      ref
                          .read(settingsProvider.notifier)
                          .updateTransitionEffect(effect);
                    }
                  },
                );
              }).toList(),
            ),
          ),

          const Divider(height: 32),

          // Scheduling Section
          _buildSectionHeader(context, 'Zamanlama'),

          SwitchListTile(
            title: const Text('Otomatik Başlat/Durdur'),
            subtitle: Text(alarmActive
                ? 'Alarmlar aktif'
                : 'Belirlenen saatlerde otomatik çalışsın'),
            value: settings.autoStartEnabled,
            onChanged: (value) async {
              await ref
                  .read(settingsProvider.notifier)
                  .updateSchedule(autoStartEnabled: value);

              // Alarm'ları güncelle
              await ref.read(alarmNotifierProvider.notifier).updateAlarms();
            },
          ),

          if (settings.autoStartEnabled) ...[
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Başlangıç Saati'),
              subtitle: Text(settings.startTime ?? 'Belirlenmedi'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _parseTime(settings.startTime) ??
                      const TimeOfDay(hour: 8, minute: 0),
                );
                if (time != null) {
                  await ref.read(settingsProvider.notifier).updateSchedule(
                        startTime:
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      );

                  // Alarm'ları güncelle
                  await ref.read(alarmNotifierProvider.notifier).updateAlarms();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_outlined),
              title: const Text('Bitiş Saati'),
              subtitle: Text(settings.endTime ?? 'Belirlenmedi'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _parseTime(settings.endTime) ??
                      const TimeOfDay(hour: 22, minute: 0),
                );
                if (time != null) {
                  await ref.read(settingsProvider.notifier).updateSchedule(
                        endTime:
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      );

                  // Alarm'ları güncelle
                  await ref.read(alarmNotifierProvider.notifier).updateAlarms();
                }
              },
            ),

            // Alarm Status Card
            if (alarmActive)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alarmlar Aktif',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Slayt gösterisi ${settings.startTime} - ${settings.endTime} arasında otomatik çalışacak',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],

          const Divider(height: 32),

          // Power Management Section
          _buildSectionHeader(context, 'Güç Yönetimi'),

          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Test: Ekranı Karart'),
            subtitle: const Text('Geçici olarak ekranı karartır'),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                final powerNotifier = ref.read(powerNotifierProvider.notifier);

                // Ekranı karart
                await powerNotifier.setBrightness(0.1);

                // 3 saniye bekle
                await Future.delayed(const Duration(seconds: 3));

                // Geri aç
                await powerNotifier.setBrightness(1.0);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test tamamlandı')),
                  );
                }
              },
            ),
          ),

          const Divider(height: 32),

          // Root Features Section
          _buildSectionHeader(context, 'Gelişmiş Özellikler'),

          rootStatus.when(
            data: (isRooted) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isRooted ? Icons.verified : Icons.security,
                      color: isRooted ? Colors.orange : Colors.grey,
                    ),
                    title: Text(
                      isRooted ? 'Cihaz Root\'lu' : 'Cihaz Root\'lu Değil',
                    ),
                    subtitle: Text(
                      isRooted
                          ? 'Gelişmiş özellikler kullanılabilir'
                          : 'Kapatma özelliği kullanılamaz',
                    ),
                  ),
                  if (isRooted)
                    SwitchListTile(
                      secondary: const Icon(Icons.power_settings_new),
                      title: const Text('Root ile Kapat'),
                      subtitle:
                          const Text('Belirlenen saatte cihaz tamamen kapanır'),
                      value: settings.useRootShutdown,
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .toggleRootShutdown(value);
                      },
                    ),
                  if (isRooted)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Cihazı Kapat'),
                              content: const Text(
                                'Cihaz şimdi kapanacak. Emin misiniz?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Kapat'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await ref
                                .read(powerNotifierProvider.notifier)
                                .shutdownDevice();
                          }
                        },
                        icon: const Icon(Icons.power_settings_new),
                        label: const Text('Test: Cihazı Kapat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const ListTile(
              title: Text('Root durumu kontrol ediliyor...'),
              trailing: CircularProgressIndicator(),
            ),
            error: (e, s) => ListTile(
              title: const Text('Root durumu kontrol edilemedi'),
              subtitle: Text(e.toString()),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Bilgilendirme',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Otomatik başlatma özelliği belirlediğiniz saatlerde bildirim gösterir\n'
                      '• Root özelliği sadece root\'lu cihazlarda çalışır\n'
                      '• Ekran kapatma özelliği enerji tasarrufu sağlar\n'
                      '• Alarmlar cihaz yeniden başlatıldığında otomatik ayarlanır',
                      style: TextStyle(fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          const Divider(height: 32),

          // 🧪 DEBUG TEST SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test Butonları',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Test Start
                    ElevatedButton.icon(
                      onPressed: () async {
                        const platform =
                            MethodChannel('com.digitalframe/alarm');
                        try {
                          await platform.invokeMethod('onStartAlarm');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('✅ START ALARM manuel tetiklendi!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Hata: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('TEST: Slideshow Başlat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Test Stop
                    ElevatedButton.icon(
                      onPressed: () async {
                        const platform =
                            MethodChannel('com.digitalframe/alarm');
                        try {
                          await platform.invokeMethod('onStopAlarm',
                              {'useRootShutdown': settings.useRootShutdown});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('✅ STOP ALARM manuel tetiklendi!'),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Hata: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.stop),
                      label:
                          const Text('TEST: Slideshow Durdur + Ekran Karart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Bu butonlar alarm\'ın yapacağı işlemi manuel test eder. '
                      'Eğer çalışırsa native kod OK, sorun alarm schedule\'da.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getEffectName(String effect) {
    switch (effect) {
      case 'fade':
        return 'Solma';
      case 'slide':
        return 'Kayma';
      case 'zoom':
        return 'Yakınlaşma';
      case 'none':
        return 'Yok';
      default:
        return effect;
    }
  }

  TimeOfDay? _parseTime(String? timeString) {
    if (timeString == null) return null;
    final parts = timeString.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}
