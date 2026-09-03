import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../models/bluetooth_device_info.dart';
import '../l10n/app_localizations.dart';

class ScannerScreen extends StatefulWidget {
  final int sensorSlot; // 1, 2, 3 or 4

  const ScannerScreen({super.key, required this.sensorSlot});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              AppLocalizations.of(context).connectSensorTitle(widget.sensorSlot))),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Scanning indicator
              if (provider.isScanning) const LinearProgressIndicator(),

              // Scan button
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                  ),
                ),
              ),

              // Devices list
              Expanded(
                child: provider.discoveredDevices.isEmpty
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context).noDeviceFound,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: Colors.blue),
        title: Text(
          device.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device.name, style: const TextStyle(fontSize: 11)),
            Text(device.address, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.rssi,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            Text(
              '${device.rssi}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        onTap: () async {
          // Stop scanning
          await provider.stopScanning();

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
                  Text(l10n.connecting),
                ],
              ),
            ),
          );

          // Connect to the sensor using dynamic method
          bool success = await provider.connectSensor(
            widget.sensorSlot,
            device,
          );

          // Close connecting dialog
          if (!context.mounted) return;
          Navigator.pop(context);

          if (success) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.connectedToSensor(device.name, widget.sensorSlot),
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Return to main screen
            Navigator.pop(context);
          } else {
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.connectError),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _provider.stopScanning();
    super.dispose();
  }
}
