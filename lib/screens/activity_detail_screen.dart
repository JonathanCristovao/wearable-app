import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/activity_record.dart';
import '../models/phone_sensor_data.dart';
import '../l10n/app_localizations.dart';
import 'activity_graphs_screen.dart';
import 'activity_analysis_screen.dart';
import 'activity_table_screen.dart';
import '../config/app_config.dart';

class ActivityDetailScreen extends StatelessWidget {
  final ActivityRecord record;

  const ActivityDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    IconData? icon;
    Color color;
    final hasEmoji = record.emoji != null;

    if (hasEmoji) {
      icon = null;
      color = Colors.blue;
    } else if (record.type == 'walking') {
      icon = Icons.directions_walk;
      color = Colors.green;
    } else if (record.type == 'running') {
      icon = Icons.directions_run;
      color = Colors.orange;
    } else {
      icon = Icons.directions_bike;
      color = Colors.blue;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).activityDetails),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
              ),
              child: Column(
                children: [
                  hasEmoji
                      ? Text(record.emoji!, style: const TextStyle(fontSize: 64))
                      : Icon(icon, size: 64, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    record.activityName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(record.startTime),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Duration card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.timer, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        record.formattedDuration,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        l10n.totalDuration,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      l10n.start,
                      _formatTime(record.startTime),
                      Icons.play_arrow,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.end,
                      _formatTime(record.endTime),
                      Icons.stop,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      l10n.dataPoints,
                      record.dataPoints.length.toString(),
                      Icons.data_usage,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      l10n.sensors,
                      record.dataPoints.isNotEmpty
                          ? (record.dataPoints.first.sensors.length +
                                    (record.dataPoints.any(
                                          (dp) => dp.phoneSensors != null,
                                        )
                                        ? 1
                                        : 0))
                                .toString()
                          : '0',
                      Icons.sensors,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ActivityGraphsScreen(record: record),
                              ),
                            );
                          },
                          icon: const Icon(Icons.show_chart),
                          label: Text(l10n.seeGraphs),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _exportToCSV(context),
                          icon: const Icon(Icons.download),
                          label: Text(l10n.exportCSV),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActivityAnalysisScreen(record: record),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics),
                      label: Text(l10n.seeDetailedAnalysisShort),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActivityTableScreen(record: record),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_chart),
                      label: Text(l10n.seeTable),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data summary
            if (record.dataPoints.isNotEmpty) ...[
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.dataSummary,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...record.dataPoints.first.sensors.entries.map(
                      (entry) => _buildSensorSummaryCard(
                        context,
                        entry.key,
                        _calculateSensorStats(entry.key, record.dataPoints),
                      ),
                    ),
                    if (record.dataPoints.any((dp) => dp.phoneSensors != null))
                      _buildPhoneSensorSummaryCard(
                        context,
                        _calculatePhoneSensorStats(record.dataPoints),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorSummaryCard(
    BuildContext context,
    String sensorName,
    Map<String, dynamic> stats,
  ) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sensorName.toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('${l10n.avgRoll}:', stats['avgRoll']),
            _buildStatRow('${l10n.avgPitch}:', stats['avgPitch']),
            _buildStatRow('${l10n.avgYaw}:', stats['avgYaw']),
            _buildStatRow('${l10n.maxAcceleration}:', stats['maxAccel']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateSensorStats(
    String sensorId,
    List<ActivityDataPoint> dataPoints,
  ) {
    double sumRoll = 0, sumPitch = 0, sumYaw = 0;
    double maxAccel = 0;
    int count = 0;

    for (var dp in dataPoints) {
      final sensor = dp.sensors[sensorId];
      if (sensor != null) {
        sumRoll += sensor.roll;
        sumPitch += sensor.pitch;
        sumYaw += sensor.yaw;

        final accel =
            (sensor.accelX * sensor.accelX +
                    sensor.accelY * sensor.accelY +
                    sensor.accelZ * sensor.accelZ)
                .sqrt();
        if (accel > maxAccel) maxAccel = accel;

        count++;
      }
    }

    return {
      'avgRoll': count > 0 ? (sumRoll / count).toStringAsFixed(2) : '0.00',
      'avgPitch': count > 0 ? (sumPitch / count).toStringAsFixed(2) : '0.00',
      'avgYaw': count > 0 ? (sumYaw / count).toStringAsFixed(2) : '0.00',
      'maxAccel': maxAccel.toStringAsFixed(2),
    };
  }

  Widget _buildPhoneSensorSummaryCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.smartphone, color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n.smartphone.toUpperCase(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (stats['hasAccel'] == true) ...[
              _buildStatRow('${l10n.maxAccelX}:', '${stats['maxAccelX']} m/s²'),
              _buildStatRow('${l10n.maxAccelY}:', '${stats['maxAccelY']} m/s²'),
              _buildStatRow('${l10n.maxAccelZ}:', '${stats['maxAccelZ']} m/s²'),
            ],
            if (stats['hasGyro'] == true) ...[
              _buildStatRow('${l10n.avgGyroX}:', '${stats['avgGyroX']} rad/s'),
              _buildStatRow('${l10n.avgGyroY}:', '${stats['avgGyroY']} rad/s'),
              _buildStatRow('${l10n.avgGyroZ}:', '${stats['avgGyroZ']} rad/s'),
            ],
            if (stats['hasGps'] == true)
              _buildStatRow('${l10n.avgGpsSpeed}:', '${stats['avgSpeed']} m/s'),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _calculatePhoneSensorStats(
    List<ActivityDataPoint> dataPoints,
  ) {
    double maxAccelX = 0, maxAccelY = 0, maxAccelZ = 0;
    double sumGyroX = 0, sumGyroY = 0, sumGyroZ = 0;
    double sumSpeed = 0;
    int accelCount = 0, gyroCount = 0, gpsCount = 0;

    for (final dp in dataPoints) {
      final phone = dp.phoneSensors;
      if (phone == null) continue;

      if (phone.accelX != null) {
        if (phone.accelX!.abs() > maxAccelX.abs()) maxAccelX = phone.accelX!;
        if (phone.accelY != null && phone.accelY!.abs() > maxAccelY.abs()) {
          maxAccelY = phone.accelY!;
        }
        if (phone.accelZ != null && phone.accelZ!.abs() > maxAccelZ.abs()) {
          maxAccelZ = phone.accelZ!;
        }
        accelCount++;
      }

      if (phone.gyroX != null) {
        sumGyroX += phone.gyroX!;
        sumGyroY += phone.gyroY ?? 0;
        sumGyroZ += phone.gyroZ ?? 0;
        gyroCount++;
      }

      if (phone.gpsSpeed != null) {
        sumSpeed += phone.gpsSpeed!;
        gpsCount++;
      }
    }

    return {
      'hasAccel': accelCount > 0,
      'maxAccelX': maxAccelX.toStringAsFixed(2),
      'maxAccelY': maxAccelY.toStringAsFixed(2),
      'maxAccelZ': maxAccelZ.toStringAsFixed(2),
      'hasGyro': gyroCount > 0,
      'avgGyroX': gyroCount > 0
          ? (sumGyroX / gyroCount).toStringAsFixed(2)
          : '0.00',
      'avgGyroY': gyroCount > 0
          ? (sumGyroY / gyroCount).toStringAsFixed(2)
          : '0.00',
      'avgGyroZ': gyroCount > 0
          ? (sumGyroZ / gyroCount).toStringAsFixed(2)
          : '0.00',
      'hasGps': gpsCount > 0,
      'avgSpeed': gpsCount > 0
          ? (sumSpeed / gpsCount).toStringAsFixed(2)
          : '0.00',
    };
  }

  Future<void> _exportToCSV(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      // Request storage permission on Android
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Try with manageExternalStorage for Android 11+
          final manageStatus = await Permission.manageExternalStorage.request();
          if (!manageStatus.isGranted) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.storagePermissionDenied),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      // Generate CSV content
      StringBuffer csvContent = StringBuffer();

      // CSV Header - Generate dynamically based on NUMBER_OF_SENSORS
      StringBuffer header = StringBuffer();
      header.write('user-id,user-name,timestamp,activity_name,activity_type,activity_environment,f-level');
      
      // Add sensor columns dynamically
      for (int i = 1; i <= NUMBER_OF_SENSORS; i++) {
        header.write(
          ',sensor${i}_accelX,sensor${i}_accelY,sensor${i}_accelZ,'
          'sensor${i}_gyroX,sensor${i}_gyroY,sensor${i}_gyroZ,'
          'sensor${i}_roll,sensor${i}_pitch,sensor${i}_yaw,'
          'sensor${i}_quatW,sensor${i}_quatX,sensor${i}_quatY,sensor${i}_quatZ'
        );
      }
      
      // Add phone sensor columns
      header.write(
        ',phone_accelX,phone_accelY,phone_accelZ,'
        'phone_gyroX,phone_gyroY,phone_gyroZ,'
        'phone_magX,phone_magY,phone_magZ'
      );
      
      csvContent.writeln(header.toString());

      // CSV Data
      DateTime currentTime = record.startTime;
      final dataInterval = Duration(
        milliseconds: DATA_COLLECTION_INTERVAL_MS,
      );

      for (var dataPoint in record.dataPoints) {
        List<String> row = [];

        // User ID and name from record
        row.add(record.userId ?? '');
        row.add(record.userName ?? '');

        // Timestamp
        row.add(currentTime.toIso8601String());
        currentTime = currentTime.add(dataInterval);

        // Activity info
        row.add(record.activityName);
        row.add(record.type);
        row.add(record.environment);

        // Fatigue level
        row.add(dataPoint.fatigueLevel?.toString() ?? '');

        // Add data for each sensor (dynamic based on NUMBER_OF_SENSORS)
        for (int i = 1; i <= NUMBER_OF_SENSORS; i++) {
          final sensorKey = 'sensor$i';
          final sensor = dataPoint.sensors[sensorKey];

          if (sensor != null) {
            row.add(sensor.accelX.toString());
            row.add(sensor.accelY.toString());
            row.add(sensor.accelZ.toString());
            row.add(sensor.gyroX.toString());
            row.add(sensor.gyroY.toString());
            row.add(sensor.gyroZ.toString());
            row.add(sensor.roll.toString());
            row.add(sensor.pitch.toString());
            row.add(sensor.yaw.toString());
            row.add(sensor.quaternionW.toString());
            row.add(sensor.quaternionX.toString());
            row.add(sensor.quaternionY.toString());
            row.add(sensor.quaternionZ.toString());
          } else {
            // Add empty values if sensor data not available
            row.addAll(List.filled(13, ''));
          }
        }

        // Add phone sensor data (accelerometer, gyroscope, magnetometer)
        final phone = dataPoint.phoneSensors;
        if (phone != null) {
          row.add(phone.accelX?.toString() ?? '');
          row.add(phone.accelY?.toString() ?? '');
          row.add(phone.accelZ?.toString() ?? '');
          row.add(phone.gyroX?.toString() ?? '');
          row.add(phone.gyroY?.toString() ?? '');
          row.add(phone.gyroZ?.toString() ?? '');
          row.add(phone.magX?.toString() ?? '');
          row.add(phone.magY?.toString() ?? '');
          row.add(phone.magZ?.toString() ?? '');
        } else {
          row.addAll(List.filled(9, ''));
        }

        csvContent.writeln(row.join(','));
      }

      // Determine save location
      Directory? directory;
      String filePath;

      if (Platform.isAndroid) {
        // Try to save to Downloads folder
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS - use application documents directory
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Other platforms
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception(
          l10n.cannotAccessStorage,
        );
      }

      final fileName =
          'activity_${record.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
      filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvContent.toString());

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Platform.isAndroid
                  ? '${l10n.csvSavedToDownload}!\n$fileName'
                  : '${l10n.csvExported}!\n$filePath',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: l10n.copy,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorExportingCsv('$e')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

extension on num {
  double sqrt() {
    return this < 0 ? 0 : toDouble();
  }
}
