import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity_record.dart';
import '../providers/sensor_provider.dart';
import '../l10n/app_localizations.dart';
import 'activity_running_screen.dart';
import 'scanner_screen.dart';
import '../config/app_config.dart';

class ActivityCheckScreen extends StatefulWidget {
  final ActivityType activity;

  const ActivityCheckScreen({super.key, required this.activity});

  @override
  State<ActivityCheckScreen> createState() => _ActivityCheckScreenState();
}

class _ActivityCheckScreenState extends State<ActivityCheckScreen> {
  @override
  void initState() {
    super.initState();
  }

  /// Returns the set of BLE sensor slot numbers required by this activity.
  Set<int> get _requiredBleSlots {
    final slots = <int>{};
    for (final s in widget.activity.requiredSensors) {
      final deviceName = s.sensorDevice;
      if (deviceName != null && deviceName.startsWith('sensor')) {
        final slotNumber = int.tryParse(deviceName.substring(6));
        if (slotNumber != null && slotNumber >= 1 && slotNumber <= NUMBER_OF_SENSORS) {
          slots.add(slotNumber);
        }
      }
    }
    return slots;
  }

  bool get _requiresSmartphone => widget.activity.requiredSensors
      .any((s) => s.sensorDevice == 'smartphone');

  /// True when all required BLE sensors are connected (or there are none).
  bool _bleRequirementMet(SensorProvider provider) {
    for (final slot in _requiredBleSlots) {
      final status = provider.getSensorState(slot).status;
      if (status != 'Conectado') return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          final allConnected = _bleRequirementMet(provider);
          final l10n = AppLocalizations.of(context);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Compact status container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: allConnected ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: allConnected ? Colors.green.shade300 : Colors.orange.shade300,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          allConnected ? Icons.check_circle : Icons.info_outline,
                          color: allConnected ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            allConnected
                                ? l10n.allSensorsConnected
                                : l10n.connectRequiredSensors,
                            style: TextStyle(
                              fontSize: 14,
                              color: allConnected ? Colors.green.shade900 : Colors.orange.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Connection status
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status de Conexão',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              // Generate connection status for all required sensors dynamically
                              for (final slot in _requiredBleSlots.toList()..sort())
                                _buildConnectionStatus(
                                  '${l10n.sensor} $slot',
                                  provider.getSensorState(slot).status == 'Conectado',
                                  () => _showScannerDialog(context, slot),
                                ),
                              if (_requiresSmartphone)
                                _buildSmartphoneStatus(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  // Start button - centered
                  Center(
                    child: SizedBox(
                      width: 280,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: allConnected
                            ? () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ActivityRunningScreen(
                                      activity: widget.activity,
                                    ),
                                  ),
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: allConnected ? 8 : 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_arrow, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              l10n.startActivity,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sensor positions
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.sensorPlacement,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...widget.activity.requiredSensors.map(
                            (sensor) => _buildSensorPositionInfo(sensor, provider),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmartphoneStatus() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.indigo.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.smartphone,
            color: Colors.indigo,
            size: 32,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).smartphone,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        Text(
          AppLocalizations.of(context).available,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(
    String label,
    bool isConnected,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isConnected
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: isConnected ? Colors.green : Colors.grey,
                size: 32,
              ),
            ),
            if (!isConnected)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 16),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isConnected ? Colors.green : Colors.grey,
          ),
        ),
        Text(
          isConnected
              ? AppLocalizations.of(context).connectedLabel
              : AppLocalizations.of(context).disconnectedLabel,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSensorPositionInfo(SensorPosition sensor, SensorProvider provider) {
    // Determine if this sensor is connected
    bool isConnected = false;
    if (sensor.sensorDevice == 'smartphone') {
      isConnected = true; // Smartphone is always available
    } else if (sensor.sensorDevice != null && sensor.sensorDevice!.startsWith('sensor')) {
      final slotNumber = int.tryParse(sensor.sensorDevice!.substring(6));
      if (slotNumber != null) {
        isConnected = provider.getSensorState(slotNumber).status == 'Conectado';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? Colors.green.shade300 : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isConnected ? Icons.check_circle : Icons.sensors,
              color: isConnected ? Colors.green : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sensor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isConnected
                            ? AppLocalizations.of(context).connectedLabel
                            : AppLocalizations.of(context).waiting,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sensor.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showScannerDialog(BuildContext context, int sensorSlot) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.connectSensorTitle(sensorSlot)),
        content: Text(l10n.wantToConnectSensor),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScannerScreen(sensorSlot: sensorSlot),
                ),
              );
            },
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
  }
}
