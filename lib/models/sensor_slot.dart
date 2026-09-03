import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'sensor_data.dart';
import '../services/protocol_parser.dart';

/// Represents a dynamic sensor slot that can be connected to a Bluetooth device
class SensorSlot {
  final int slotNumber;
  final String slotId; // e.g., 'sensor1', 'sensor2', etc.
  
  // Stream controllers
  final StreamController<SensorData> _dataController;
  final StreamController<SensorState> _stateController;
  
  // Bluetooth resources
  BluetoothDevice? device;
  BluetoothCharacteristic? characteristic;
  BluetoothCharacteristic? batteryCharacteristic;
  StreamSubscription? subscription;
  StreamSubscription? batterySubscription;
  
  // Protocol parser
  final ProtocolParser parser;
  
  // Public streams
  Stream<SensorData> get dataStream => _dataController.stream;
  Stream<SensorState> get stateStream => _stateController.stream;
  
  // Current state and data
  SensorState _currentState = SensorState.disconnected();
  SensorData? _currentData;
  
  SensorState get currentState => _currentState;
  SensorData? get currentData => _currentData;
  
  SensorSlot({
    required this.slotNumber,
    required this.slotId,
  })  : _dataController = StreamController<SensorData>.broadcast(),
        _stateController = StreamController<SensorState>.broadcast(),
        parser = ProtocolParser() {
    // Listen to own streams to maintain current state
    _stateController.stream.listen((state) {
      _currentState = state;
    });
    _dataController.stream.listen((data) {
      _currentData = data;
    });
  }
  
  /// Update the sensor state
  void updateState(SensorState state) {
    _stateController.add(state);
  }
  
  /// Add sensor data
  void addData(SensorData data) {
    _dataController.add(data);
  }
  
  /// Check if the sensor is connected
  bool get isConnected => _currentState.status == 'Conectado';
  
  /// Check if the sensor is connecting
  bool get isConnecting => _currentState.status == 'Conectando';
  
  /// Disconnect and clean up resources
  Future<void> disconnect() async {
    try {
      await subscription?.cancel();
      subscription = null;
      await batterySubscription?.cancel();
      batterySubscription = null;
      
      if (device != null) {
        await device!.disconnect();
        device = null;
      }
      
      characteristic = null;
      batteryCharacteristic = null;
      updateState(SensorState.disconnected());
    } catch (e) {
      debugPrint('Error disconnecting slot $slotId: $e');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _dataController.close();
    _stateController.close();
    subscription?.cancel();
  }
}

/// Configuration for available sensor slots
class SensorSlotsConfig {
  final List<SensorSlot> slots;
  
  SensorSlotsConfig({required int numberOfSlots})
      : slots = List.generate(
          numberOfSlots,
          (index) => SensorSlot(
            slotNumber: index + 1,
            slotId: 'sensor${index + 1}',
          ),
        );
  
  /// Get a slot by slot number (1-based)
  SensorSlot? getSlotByNumber(int slotNumber) {
    if (slotNumber < 1 || slotNumber > slots.length) return null;
    return slots[slotNumber - 1];
  }
  
  /// Get a slot by slot ID (e.g., 'sensor1')
  SensorSlot? getSlotById(String slotId) {
    try {
      return slots.firstWhere((slot) => slot.slotId == slotId);
    } catch (_) {
      return null;
    }
  }
  
  /// Get all connected slots
  List<SensorSlot> get connectedSlots {
    return slots.where((slot) => slot.isConnected).toList();
  }
  
  /// Get number of connected sensors
  int get connectedCount => connectedSlots.length;
  
  /// Disconnect all sensors
  Future<void> disconnectAll() async {
    for (final slot in slots) {
      await slot.disconnect();
    }
  }
  
  /// Dispose all slots
  void dispose() {
    for (final slot in slots) {
      slot.dispose();
    }
  }
}
