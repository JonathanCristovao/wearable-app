import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/phone_sensor_data.dart';
import '../providers/sensor_provider.dart';

class PhoneSensorsScreen extends StatefulWidget {
  const PhoneSensorsScreen({super.key});

  @override
  State<PhoneSensorsScreen> createState() => _PhoneSensorsScreenState();
}

class _PhoneSensorsScreenState extends State<PhoneSensorsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, provider, _) {
        final settings = provider.phoneSensorSettings;
        final data = provider.phoneSensorData;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sensores do Smartphone'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.phone_android,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: provider.isPhoneSensorRunning
                                  ? Colors.green
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              provider.isPhoneSensorRunning
                                  ? 'Ativo'
                                  : 'Inativo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (settings.anyEnabled) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Ative os sensores desejados abaixo. '
                          'Os dados serão coletados simultaneamente com os sensores BLE durante as atividades.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum sensor do smartphone ativado. '
                          'Ative ao menos um abaixo para coletar dados adicionais.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sensor toggles
              Card(
                child: Column(
                  children: [
                    _SensorToggleTile(
                      icon: Icons.vibration,
                      title: 'Acelerômetro',
                      subtitle: 'Aceleração linear (m/s²) nos eixos X, Y, Z',
                      value: settings.accelerometerEnabled,
                      onChanged: (v) => _updateSettings(
                        provider,
                        settings.copyWith(accelerometerEnabled: v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SensorToggleTile(
                      icon: Icons.rotate_right,
                      title: 'Giroscópio',
                      subtitle: 'Velocidade angular (rad/s) nos eixos X, Y, Z',
                      value: settings.gyroscopeEnabled,
                      onChanged: (v) => _updateSettings(
                        provider,
                        settings.copyWith(gyroscopeEnabled: v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SensorToggleTile(
                      icon: Icons.explore,
                      title: 'Magnetômetro / Bússola',
                      subtitle: 'Campo magnético (µT) nos eixos X, Y, Z',
                      value: settings.magnetometerEnabled,
                      onChanged: (v) => _updateSettings(
                        provider,
                        settings.copyWith(magnetometerEnabled: v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SensorToggleTile(
                      icon: Icons.location_on,
                      title: 'GPS',
                      subtitle:
                          'Latitude, longitude, altitude, velocidade e direção',
                      value: settings.gpsEnabled,
                      onChanged: (v) => _updateSettings(
                        provider,
                        settings.copyWith(gpsEnabled: v),
                      ),
                    ),
                    const Divider(height: 1),
                    _SensorToggleTile(
                      icon: Icons.speed,
                      title: 'Barômetro',
                      subtitle: 'Pressão atmosférica (hPa)',
                      value: settings.barometerEnabled,
                      onChanged: (v) => _updateSettings(
                        provider,
                        settings.copyWith(barometerEnabled: v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Live data preview (only when running)
              if (provider.isPhoneSensorRunning && data != null) ...[
                const Text(
                  'Dados em Tempo Real',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (settings.accelerometerEnabled)
                  _DataCard(
                    title: 'Acelerômetro',
                    icon: Icons.vibration,
                    rows: [
                      _DataRow('X', data.accelX, 'm/s²'),
                      _DataRow('Y', data.accelY, 'm/s²'),
                      _DataRow('Z', data.accelZ, 'm/s²'),
                    ],
                  ),
                if (settings.gyroscopeEnabled)
                  _DataCard(
                    title: 'Giroscópio',
                    icon: Icons.rotate_right,
                    rows: [
                      _DataRow('X', data.gyroX, 'rad/s'),
                      _DataRow('Y', data.gyroY, 'rad/s'),
                      _DataRow('Z', data.gyroZ, 'rad/s'),
                    ],
                  ),
                if (settings.magnetometerEnabled)
                  _DataCard(
                    title: 'Magnetômetro',
                    icon: Icons.explore,
                    rows: [
                      _DataRow('X', data.magX, 'µT'),
                      _DataRow('Y', data.magY, 'µT'),
                      _DataRow('Z', data.magZ, 'µT'),
                    ],
                  ),
                if (settings.gpsEnabled)
                  _DataCard(
                    title: 'GPS',
                    icon: Icons.location_on,
                    rows: [
                      _DataRow('Lat', data.latitude, '°'),
                      _DataRow('Lon', data.longitude, '°'),
                      _DataRow('Alt', data.altitude, 'm'),
                      _DataRow('Vel', data.gpsSpeed, 'm/s'),
                      _DataRow('Precisão', data.gpsAccuracy, 'm'),
                    ],
                  ),
                if (settings.barometerEnabled)
                  _DataCard(
                    title: 'Barômetro',
                    icon: Icons.speed,
                    rows: [_DataRow('Pressão', data.barometricPressure, 'hPa')],
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateSettings(
    SensorProvider provider,
    PhoneSensorSettings newSettings,
  ) async {
    await provider.updatePhoneSensorSettings(newSettings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newSettings.anyEnabled
                ? 'Sensores do smartphone ativados'
                : 'Sensores do smartphone desativados',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class _SensorToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SensorToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _DataRow {
  final String label;
  final double? value;
  final String unit;
  const _DataRow(this.label, this.value, this.unit);
}

class _DataCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_DataRow> rows;

  const _DataCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(row.label, style: const TextStyle(fontSize: 13)),
                    Text(
                      row.value != null
                          ? '${row.value!.toStringAsFixed(4)} ${row.unit}'
                          : '—',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: row.value != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
