import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../models/bluetooth_device_info.dart';
import '../l10n/app_localizations.dart';

/// Universal Scanner Screen - Auto-detects sensor slot based on tag
/// 
/// When a device with tag (s1, s2, s3, etc.) is selected,
/// it automatically connects to the corresponding sensor slot.
class UniversalScannerScreen extends StatefulWidget {
  const UniversalScannerScreen({super.key});

  @override
  State<UniversalScannerScreen> createState() => _UniversalScannerScreenState();
}

class _UniversalScannerScreenState extends State<UniversalScannerScreen> {
  late SensorProvider _provider;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<SensorProvider>();
    // Start scanning when screen opens
    Future.delayed(Duration.zero, () {
      _provider.startScanning();
    });
  }

  /// Extract slot number from sensor tag (e.g., "s1" -> 1, "s5" -> 5)
  int? _getSlotFromTag(String? tag) {
    if (tag == null || tag.isEmpty) return null;
    
    // Remove 's' prefix and parse number
    final numberStr = tag.toLowerCase().replaceAll('s', '');
    return int.tryParse(numberStr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).scanSensors),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Scanning indicator
              if (provider.isScanning) const LinearProgressIndicator(),

              // Info banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).selectSensorAutoConnect,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Scan button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (provider.isScanning) {
                        provider.stopScanning();
                      } else {
                        provider.startScanning();
                      }
                    },
                    icon: Icon(provider.isScanning ? Icons.stop : Icons.search),
                    label: Text(
                      provider.isScanning
                          ? AppLocalizations.of(context).stopScanning
                          : AppLocalizations.of(context).scan,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Devices list
              Expanded(
                child: provider.discoveredDevices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth_searching, 
                                size: 64, 
                                color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context).noDeviceFound,
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context).pressScanToStart,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: provider.discoveredDevices.length,
                        itemBuilder: (context, index) {
                          final device = provider.discoveredDevices[index];
                          return _buildDeviceItem(context, device, provider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeviceItem(
    BuildContext context,
    BluetoothDeviceInfo device,
    SensorProvider provider,
  ) {
    final l10n = AppLocalizations.of(context);
    final slotNumber = _getSlotFromTag(device.sensorTag)!;
    final isConnected = provider.getSensorState(slotNumber).status == 'Conectado';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isConnected ? Colors.green.shade50 : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade100 : Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isConnected ? Icons.check_circle : Icons.bluetooth,
            color: isConnected ? Colors.green.shade700 : Colors.blue.shade700,
          ),
        ),
        title: Row(
          children: [
            Text(
              device.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green.shade100 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isConnected ? Colors.green.shade500 : Colors.green.shade300,
                ),
              ),
              child: Text(
                isConnected ? l10n.connectedLabel : l10n.slotNumberLabel(slotNumber),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isConnected ? Colors.green.shade900 : Colors.green.shade800,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              device.name,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              device.address,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: isConnected
            ? Icon(Icons.check_circle, color: Colors.green.shade600, size: 28)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.rssi,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    '${device.rssi}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
        onTap: isConnected ? null : () => _connectDevice(context, device, slotNumber, provider),
      ),
    );
  }

  Future<void> _connectDevice(
    BuildContext context,
    BluetoothDeviceInfo device,
    int slotNumber,
    SensorProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    // Show connecting dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(
              child: Text(l10n.connectingToSlot(device.displayName, slotNumber)),
            ),
          ],
        ),
      ),
    );

    // Connect to the sensor at the auto-detected slot
    bool success = await provider.connectSensor(slotNumber, device);

    // Close connecting dialog
    if (!context.mounted) return;
    Navigator.pop(context);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.connectedToSensorLabel(device.displayName, slotNumber),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.connectErrorTryAgain),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _provider.stopScanning();
    super.dispose();
  }
}
