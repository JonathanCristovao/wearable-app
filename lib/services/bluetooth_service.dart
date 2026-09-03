import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../models/sensor_data.dart';
import '../models/bluetooth_device_info.dart';
import '../models/sensor_slot.dart';
import '../config/app_config.dart';

/// Service to manage Bluetooth connections with WT9011DCL sensors
/// 
/// This service now supports dynamic sensor management!
/// To add more sensors, simply change NUMBER_OF_SENSORS in app_config.dart
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal() {
    // Initialize sensor slots based on configuration
    _sensorSlots = SensorSlotsConfig(numberOfSlots: NUMBER_OF_SENSORS);
  }

  // Dynamic sensor management
  late final SensorSlotsConfig _sensorSlots;
  
  // Stream controller for discovered devices
  final _discoveredDevicesController =
      StreamController<List<BluetoothDeviceInfo>>.broadcast();

  // Stream controller for scanning state
  final _isScanningController = StreamController<bool>.broadcast();

  // Public streams
  Stream<List<BluetoothDeviceInfo>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;
  Stream<bool> get isScanningStream => _isScanningController.stream;

  // Discovered devices
  final List<BluetoothDeviceInfo> _discoveredDevices = [];

  // Subscriptions
  StreamSubscription? _scanSubscription;

  bool _isScanning = false;
  
  // ============================================================================
  // BACKWARD COMPATIBILITY GETTERS
  // These maintain compatibility with existing code while using the new system
  // ============================================================================
  
  Stream<SensorData> get sensor1DataStream => getSensorDataStream(1);
  Stream<SensorData> get sensor2DataStream => getSensorDataStream(2);
  Stream<SensorData> get sensor3DataStream => getSensorDataStream(3);
  Stream<SensorData> get sensor4DataStream => getSensorDataStream(4);
  Stream<SensorState> get sensor1StateStream => getSensorStateStream(1);
  Stream<SensorState> get sensor2StateStream => getSensorStateStream(2);
  Stream<SensorState> get sensor3StateStream => getSensorStateStream(3);
  Stream<SensorState> get sensor4StateStream => getSensorStateStream(4);
  
  // ============================================================================
  // NEW DYNAMIC API
  // Use these methods for new code - they work with any number of sensors
  // ============================================================================
  
  /// Get all available sensor slots
  List<SensorSlot> get allSensorSlots => _sensorSlots.slots;
  
  /// Get number of configured sensor slots
  int get numberOfSensors => _sensorSlots.slots.length;
  
  /// Get a sensor slot by number (1-based)
  SensorSlot? getSensorSlot(int slotNumber) {
    return _sensorSlots.getSlotByNumber(slotNumber);
  }
  
  /// Get a sensor slot by ID (e.g., 'sensor1')
  SensorSlot? getSensorSlotById(String slotId) {
    return _sensorSlots.getSlotById(slotId);
  }
  
  /// Get data stream for a specific sensor slot
  Stream<SensorData> getSensorDataStream(int slotNumber) {
    final slot = getSensorSlot(slotNumber);
    if (slot == null) {
      return const Stream.empty();
    }
    return slot.dataStream;
  }
  
  /// Get state stream for a specific sensor slot
  Stream<SensorState> getSensorStateStream(int slotNumber) {
    final slot = getSensorSlot(slotNumber);
    if (slot == null) {
      return const Stream.empty();
    }
    return slot.stateStream;
  }
  
  /// Get all connected sensors
  List<SensorSlot> get connectedSensors => _sensorSlots.connectedSlots;
  
  /// Get number of connected sensors
  int get connectedSensorsCount => _sensorSlots.connectedCount;


  /// Start scanning for Bluetooth devices
  Future<void> startScanning() async {
    if (_isScanning) return;

    _discoveredDevices.clear();
    _discoveredDevicesController.add([]);

    try {
      // Check if Bluetooth is available
      if (!await fbp.FlutterBluePlus.isSupported) {
        debugPrint('Bluetooth not available');
        return;
      }

      // Check if Bluetooth is on
      if (await fbp.FlutterBluePlus.adapterState.first !=
          fbp.BluetoothAdapterState.on) {
        debugPrint('Bluetooth is off');
        return;
      }

      _isScanning = true;
      _isScanningController.add(true);

      // Start scanning
      await fbp.FlutterBluePlus.startScan(
        timeout: Duration(seconds: BLUETOOTH_SCAN_TIMEOUT_SECONDS),
      );

      // Listen to scan results
      _scanSubscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final deviceInfo = BluetoothDeviceInfo.fromScanResult(result);

          // Only show mapped sensors (S1-S5 from SENSOR_MAC_ADDRESS_MAP)
          if (deviceInfo.sensorTag != null) {
            // Check if device already in list
            final existingIndex = _discoveredDevices.indexWhere(
              (d) => d.address == deviceInfo.address,
            );

            if (existingIndex >= 0) {
              _discoveredDevices[existingIndex] = deviceInfo;
            } else {
              _discoveredDevices.add(deviceInfo);
            }

            _discoveredDevicesController.add(List.from(_discoveredDevices));
          }
        }
      });

      // Auto-stop scanning after timeout
      Future.delayed(Duration(seconds: BLUETOOTH_SCAN_TIMEOUT_SECONDS), () {
        if (_isScanning) {
          stopScanning();
        }
      });
    } catch (e) {
      debugPrint('Error starting scan: $e');
      _isScanning = false;
      _isScanningController.add(false);
    }
  }

  /// Stop scanning for Bluetooth devices
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    try {
      await fbp.FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
      _isScanningController.add(false);
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }
  
  // ============================================================================
  // DYNAMIC CONNECTION METHODS - Works with any sensor slot
  // ============================================================================
  
  /// Connect to a sensor at the specified slot number
  Future<bool> connectSensor(int slotNumber, fbp.BluetoothDevice device) async {
    final slot = getSensorSlot(slotNumber);
    if (slot == null) {
      debugPrint('Invalid slot number: $slotNumber');
      return false;
    }
    
    return await _connectSensorToSlot(slot, device);
  }
  
  /// Internal method to connect a device to a sensor slot
  Future<bool> _connectSensorToSlot(
    SensorSlot slot,
    fbp.BluetoothDevice device,
  ) async {
    try {
      slot.updateState(SensorState.connecting());

      await device.connect(
        timeout: Duration(seconds: BLUETOOTH_CONNECTION_TIMEOUT_SECONDS),
      );
      slot.device = device;

      // Discover services
      final services = await device.discoverServices();

      debugPrint('====== ${slot.slotId.toUpperCase()} - Services Found ======');
      debugPrint('Total services: ${services.length}');

      fbp.BluetoothCharacteristic? notifyCharacteristic;

      // Find the data characteristic
      for (var service in services) {
        debugPrint('Service UUID: ${service.uuid}');
        for (var characteristic in service.characteristics) {
          debugPrint('  Characteristic UUID: ${characteristic.uuid}');
          debugPrint(
            '    Properties: notify=${characteristic.properties.notify}, '
            'read=${characteristic.properties.read}, '
            'write=${characteristic.properties.write}',
          );

          final uuidStr = characteristic.uuid.toString().toLowerCase();

          // Look for the specific UUID or any characteristic with notify property
          if (uuidStr.contains(SENSOR_DATA_CHARACTERISTIC_UUID) ||
              (characteristic.properties.notify &&
                  notifyCharacteristic == null)) {
            notifyCharacteristic = characteristic;
            debugPrint(
              '  -> Found potential data characteristic: ${characteristic.uuid}',
            );

            // If it matches our expected UUID, use it immediately
            if (uuidStr.contains(SENSOR_DATA_CHARACTERISTIC_UUID)) {
              break;
            }
          }
        }
        if (notifyCharacteristic != null &&
            notifyCharacteristic.uuid.toString().toLowerCase().contains(
              SENSOR_DATA_CHARACTERISTIC_UUID,
            )) {
          break;
        }
      }

      if (notifyCharacteristic != null) {
        slot.characteristic = notifyCharacteristic;
        debugPrint('Using characteristic: ${notifyCharacteristic.uuid}');

        // Enable notifications
        await notifyCharacteristic.setNotifyValue(true);

        // Listen to data
        slot.subscription = notifyCharacteristic.lastValueStream.listen((
          value,
        ) {
          if (value.isNotEmpty) {
            debugPrint(
              '${slot.slotId} - Received ${value.length} bytes: '
              '${value.take(20).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}',
            );
            final packets = slot.parser.parse(Uint8List.fromList(value));
            for (var data in packets) {
              slot.addData(data);
            }
          }
        });

        slot.updateState(SensorState.connected(device.platformName));

        // Try to read battery level from Battery Service
        _setupBatteryLevelMonitoring(slot, services);

        return true;
      }

      debugPrint('======================================');
      debugPrint('ERROR: No suitable characteristic found!');
      debugPrint('Expected UUID containing: $SENSOR_DATA_CHARACTERISTIC_UUID');
      await device.disconnect();
      slot.updateState(SensorState.disconnected());
      return false;
    } catch (e) {
      debugPrint('Error connecting to ${slot.slotId}: $e');
      slot.updateState(SensorState.disconnected());
      return false;
    }
  }
  
  /// Disconnect a sensor at the specified slot number
  Future<void> disconnectSensor(int slotNumber) async {
    final slot = getSensorSlot(slotNumber);
    if (slot != null) {
      await slot.disconnect();
      slot.parser.clear();
    }
  }
  
  // ============================================================================
  // BACKWARD COMPATIBILITY METHODS
  // These maintain compatibility with existing code
  // ============================================================================
  
  Future<bool> connectSensor1(fbp.BluetoothDevice device) async {
    return await connectSensor(1, device);
  }

  Future<bool> connectSensor2(fbp.BluetoothDevice device) async {
    return await connectSensor(2, device);
  }

  Future<bool> connectSensor3(fbp.BluetoothDevice device) async {
    return await connectSensor(3, device);
  }

  Future<bool> connectSensor4(fbp.BluetoothDevice device) async {
    return await connectSensor(4, device);
  }

  Future<void> disconnectSensor1() async {
    await disconnectSensor(1);
  }

  Future<void> disconnectSensor2() async {
    await disconnectSensor(2);
  }

  Future<void> disconnectSensor3() async {
    await disconnectSensor(3);
  }

  Future<void> disconnectSensor4() async {
    await disconnectSensor(4);
  }

  /// Disconnect all sensors
  Future<void> disconnectAll() async {
    await _sensorSlots.disconnectAll();
  }

  /// Set up battery level monitoring for a connected sensor slot
  void _setupBatteryLevelMonitoring(
    SensorSlot slot,
    List<fbp.BluetoothService> services,
  ) {
    try {
      // First pass: look for standard Battery Service (0x180F)
      bool found = false;
      for (var service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        if (!serviceUuid.contains('180f')) continue;

        for (var characteristic in service.characteristics) {
          final charUuid = characteristic.uuid.toString().toLowerCase();
          if (!charUuid.contains('2a19')) continue;

          _setupBatteryCharacteristic(slot, characteristic);
          found = true;
          break;
        }
        if (found) break;
      }

      // Second pass: look for battery level characteristic (2A19) in any service
      if (!found) {
        for (var service in services) {
          for (var characteristic in service.characteristics) {
            final charUuid = characteristic.uuid.toString().toLowerCase();
            if (charUuid.contains('2a19') && characteristic.properties.read) {
              _setupBatteryCharacteristic(slot, characteristic);
              found = true;
              break;
            }
          }
          if (found) break;
        }
      }

      if (!found) {
        debugPrint(
          '${slot.slotId} - No Battery Service found. '
          'Available services: ${services.map((s) => s.uuid).toList()}',
        );
      }
    } catch (e) {
      debugPrint('Error setting up battery monitoring for ${slot.slotId}: $e');
    }
  }

  void _setupBatteryCharacteristic(
    SensorSlot slot,
    fbp.BluetoothCharacteristic characteristic,
  ) {
    slot.batteryCharacteristic = characteristic;

    // Read initial battery level
    characteristic.read().then((value) {
      if (value.isNotEmpty) {
        final batteryLevel = value[0];
        final currentState = slot.currentState;
        slot.updateState(currentState.copyWith(
          batteryLevel: batteryLevel,
        ));
      }
    });

    // Subscribe to battery level changes if supported
    if (characteristic.properties.notify) {
      characteristic.setNotifyValue(true).then((_) {
        slot.batterySubscription = characteristic.lastValueStream
            .listen((value) {
          if (value.isNotEmpty) {
            final batteryLevel = value[0];
            final currentState = slot.currentState;
            slot.updateState(currentState.copyWith(
              batteryLevel: batteryLevel,
            ));
          }
        });
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _scanSubscription?.cancel();
    _sensorSlots.dispose();
    _discoveredDevicesController.close();
    _isScanningController.close();
  }
}
