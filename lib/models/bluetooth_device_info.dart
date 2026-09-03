import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../config/app_config.dart';

/// Wrapper for Bluetooth device scan results
class BluetoothDeviceInfo {
  final BluetoothDevice device;
  final String name;
  final String address;
  final int rssi;
  final String? sensorTag;

  BluetoothDeviceInfo({
    required this.device,
    required this.name,
    required this.address,
    required this.rssi,
    this.sensorTag,
  });

  /// Get display name for the device
  /// Returns sensor tag if available, otherwise returns device name
  String get displayName {
    if (sensorTag != null && sensorTag!.isNotEmpty) {
      return sensorTag!;
    }
    return name;
  }

  factory BluetoothDeviceInfo.fromScanResult(ScanResult result) {
    final address = result.device.remoteId.toString();
    return BluetoothDeviceInfo(
      device: result.device,
      name: result.advertisementData.advName.isEmpty 
          ? result.device.platformName.isEmpty 
              ? 'Unknown'
              : result.device.platformName
          : result.advertisementData.advName,
      address: address,
      rssi: result.rssi,
      sensorTag: getSensorTagFromMac(address),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BluetoothDeviceInfo &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;
}
