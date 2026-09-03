import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/bluetooth_device_info.dart';
import '../models/activity_record.dart';
import '../models/phone_sensor_data.dart';
import '../models/user_profile.dart';
import '../models/sensor_slot.dart';
import '../services/bluetooth_service.dart';
import '../services/database_helper.dart';
import '../services/phone_sensor_service.dart';

/// Provider for managing sensor state and Bluetooth connections
/// 
/// Now supports dynamic sensor management!
/// Add more sensors by changing NUMBER_OF_SENSORS in app_config.dart
class SensorProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService = BluetoothService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final PhoneSensorService _phoneSensorService = PhoneSensorService();

  // Dynamic sensor state and data storage
  final Map<int, SensorState> _sensorStates = {};
  final Map<int, SensorData?> _sensorData = {};

  // Phone sensor data and settings
  PhoneSensorData? _phoneSensorData;
  PhoneSensorSettings _phoneSensorSettings = const PhoneSensorSettings(
    accelerometerEnabled: true,
    gyroscopeEnabled: true,
    magnetometerEnabled: true,
  );

  PhoneSensorData? get phoneSensorData => _phoneSensorData;
  PhoneSensorSettings get phoneSensorSettings => _phoneSensorSettings;
  bool get isPhoneSensorRunning => _phoneSensorService.isRunning;
  Stream<PhoneSensorData> get phoneSensorDataStream =>
      _phoneSensorService.dataStream;

  // Discovered devices
  List<BluetoothDeviceInfo> _discoveredDevices = [];

  // Scanning state
  bool _isScanning = false;

  // Activity records
  List<ActivityRecord> _activityRecords = [];

  // Trash (recycle bin)
  List<Map<String, dynamic>> _trashItems = [];

  // User profiles
  List<UserProfile> _users = [];
  UserProfile? _selectedUser;

  // Loading state
  bool _isLoading = true;

  // ============================================================================
  // BACKWARD COMPATIBILITY GETTERS
  // These maintain compatibility with existing code
  // ============================================================================
  
  SensorState get sensor1State => getSensorState(1);
  SensorState get sensor2State => getSensorState(2);
  SensorState get sensor3State => getSensorState(3);
  SensorState get sensor4State => getSensorState(4);
  SensorData? get sensor1Data => getSensorData(1);
  SensorData? get sensor2Data => getSensorData(2);
  SensorData? get sensor3Data => getSensorData(3);
  SensorData? get sensor4Data => getSensorData(4);
  
  // ============================================================================
  // NEW DYNAMIC API
  // Use these methods for new code - they work with any number of sensors
  // ============================================================================
  
  /// Get all available sensor slots
  List<SensorSlot> get allSensorSlots => _bluetoothService.allSensorSlots;
  
  /// Get number of configured sensors
  int get numberOfSensors => _bluetoothService.numberOfSensors;
  
  /// Get sensor state for a specific slot number (1-based)
  SensorState getSensorState(int slotNumber) {
    return _sensorStates[slotNumber] ?? SensorState.disconnected();
  }
  
  /// Get sensor data for a specific slot number (1-based)
  SensorData? getSensorData(int slotNumber) {
    return _sensorData[slotNumber];
  }
  
  /// Get all sensor states as a map
  Map<int, SensorState> get allSensorStates => Map.unmodifiable(_sensorStates);
  
  /// Get all sensor data as a map
  Map<int, SensorData?> get allSensorData => Map.unmodifiable(_sensorData);
  
  /// Check if any sensor is connected
  bool get sensorsConnected {
    for (var state in _sensorStates.values) {
      if (state.status == 'Conectado') return true;
    }
    return false;
  }
  
  /// Get list of connected sensor slot numbers
  List<int> get connectedSensorSlots {
    return _sensorStates.entries
        .where((entry) => entry.value.status == 'Conectado')
        .map((entry) => entry.key)
        .toList();
  }
  
  // Common getters
  List<BluetoothDeviceInfo> get discoveredDevices => _discoveredDevices;
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  List<ActivityRecord> get activityRecords => _activityRecords;
  List<Map<String, dynamic>> get trashItems => _trashItems;
  List<UserProfile> get users => _users;
  UserProfile? get selectedUser => _selectedUser;

  SensorProvider() {
    _initializeListeners();
    _loadActivitiesFromDatabase();
    _loadUsersFromDatabase();
    _loadTrashItems();
    _startPhoneSensorsOnInit();
  }

  /// Load activities from database
  Future<void> _loadActivitiesFromDatabase() async {
    try {
      _activityRecords = await _databaseHelper.getAllActivities();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading activities from database: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load users and selected user from database
  Future<void> _loadUsersFromDatabase() async {
    try {
      _users = await _databaseHelper.getAllUsers();
      final selectedId = await _databaseHelper.getSetting('selectedUserId');
      if (selectedId != null) {
        try {
          _selectedUser = _users.firstWhere((u) => u.id == selectedId);
        } catch (_) {
          _selectedUser = null;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading users from database: $e');
    }
  }

  Future<void> _startPhoneSensorsOnInit() async {
    await _phoneSensorService.start(_phoneSensorSettings);
  }

  void _initializeListeners() {
    // Initialize state and data for all configured sensors
    for (int i = 1; i <= numberOfSensors; i++) {
      _sensorStates[i] = SensorState.disconnected();
      _sensorData[i] = null;
      
      // Listen to sensor state
      _bluetoothService.getSensorStateStream(i).listen((state) {
        _sensorStates[i] = state;
        notifyListeners();
      });
      
      // Listen to sensor data
      _bluetoothService.getSensorDataStream(i).listen((data) {
        _sensorData[i] = data;
        notifyListeners();
      });
    }

    // Listen to discovered devices
    _bluetoothService.discoveredDevicesStream.listen((devices) {
      _discoveredDevices = devices;
      notifyListeners();
    });

    // Listen to scanning state
    _bluetoothService.isScanningStream.listen((scanning) {
      _isScanning = scanning;
      notifyListeners();
    });

    // Listen to phone sensor data
    _phoneSensorService.dataStream.listen((data) {
      _phoneSensorData = data;
      notifyListeners();
    });
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScanning() async {
    await _bluetoothService.startScanning();
  }

  /// Stop scanning for Bluetooth devices
  Future<void> stopScanning() async {
    await _bluetoothService.stopScanning();
  }
  
  // ============================================================================
  // DYNAMIC CONNECTION METHODS
  // Use these for new code - they work with any sensor slot
  // ============================================================================
  
  /// Connect to a sensor at the specified slot number
  Future<bool> connectSensor(int slotNumber, BluetoothDeviceInfo deviceInfo) async {
    return await _bluetoothService.connectSensor(slotNumber, deviceInfo.device);
  }
  
  /// Disconnect a sensor at the specified slot number
  Future<void> disconnectSensor(int slotNumber) async {
    await _bluetoothService.disconnectSensor(slotNumber);
  }
  
  // ============================================================================
  // BACKWARD COMPATIBILITY CONNECTION METHODS
  // These maintain compatibility with existing code
  // ============================================================================

  /// Connect to sensor 1
  Future<bool> connectSensor1(BluetoothDeviceInfo deviceInfo) async {
    return await connectSensor(1, deviceInfo);
  }

  /// Connect to sensor 2
  Future<bool> connectSensor2(BluetoothDeviceInfo deviceInfo) async {
    return await connectSensor(2, deviceInfo);
  }

  /// Connect to sensor 3
  Future<bool> connectSensor3(BluetoothDeviceInfo deviceInfo) async {
    return await connectSensor(3, deviceInfo);
  }

  /// Connect to sensor 4
  Future<bool> connectSensor4(BluetoothDeviceInfo deviceInfo) async {
    return await connectSensor(4, deviceInfo);
  }

  /// Disconnect sensor 1
  Future<void> disconnectSensor1() async {
    await disconnectSensor(1);
  }

  /// Disconnect sensor 2
  Future<void> disconnectSensor2() async {
    await disconnectSensor(2);
  }

  /// Disconnect sensor 3
  Future<void> disconnectSensor3() async {
    await disconnectSensor(3);
  }

  /// Disconnect sensor 4
  Future<void> disconnectSensor4() async {
    await disconnectSensor(4);
  }

  /// Disconnect all sensors
  Future<void> disconnectAll() async {
    await _bluetoothService.disconnectAll();
  }

  /// Save activity record
  Future<void> saveActivityRecord(ActivityRecord record) async {
    try {
      // Attach the currently selected user if not already set
      final recordWithUser = _selectedUser != null && record.userId == null
          ? ActivityRecord(
              id: record.id,
              type: record.type,
              environment: record.environment,
              startTime: record.startTime,
              endTime: record.endTime,
              duration: record.duration,
              dataPoints: record.dataPoints,
              userId: _selectedUser!.id,
              userName: _selectedUser!.name,
              emoji: record.emoji,
            )
          : record;
      await _databaseHelper.saveActivity(recordWithUser);
      _activityRecords.insert(0, recordWithUser);
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving activity: $e');
      rethrow;
    }
  }

  /// Move an activity to the trash (soft delete)
  Future<void> deleteActivityRecord(String id) async {
    try {
      final record = _activityRecords.firstWhere((r) => r.id == id);
      await _databaseHelper.moveToTrash(record);
      _activityRecords.removeWhere((r) => r.id == id);
      await _loadTrashItems();
      notifyListeners();
    } catch (e) {
      debugPrint('Error moving activity to trash: $e');
      rethrow;
    }
  }

  /// Load trash items from database
  Future<void> _loadTrashItems() async {
    try {
      _trashItems = await _databaseHelper.getTrashItems();
    } catch (e) {
      debugPrint('Error loading trash items: $e');
    }
  }

  /// Restore an activity from trash back to the main list
  Future<void> restoreFromTrash(String id) async {
    try {
      await _databaseHelper.restoreFromTrash(id);
      _trashItems.removeWhere((item) => item['id'] == id);
      _activityRecords = await _databaseHelper.getAllActivities();
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring from trash: $e');
      rethrow;
    }
  }

  /// Permanently delete a single item from trash
  Future<void> permanentlyDeleteFromTrash(String id) async {
    try {
      await _databaseHelper.permanentlyDeleteFromTrash(id);
      _trashItems.removeWhere((item) => item['id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error permanently deleting from trash: $e');
      rethrow;
    }
  }

  /// Clear all items from trash
  Future<void> clearTrash() async {
    try {
      await _databaseHelper.clearTrash();
      _trashItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing trash: $e');
      rethrow;
    }
  }

  /// Clear all activity records
  Future<void> clearActivityRecords() async {
    try {
      await _databaseHelper.clearAllData();
      _activityRecords.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing activities: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _phoneSensorService.dispose();
    _bluetoothService.dispose();
    super.dispose();
  }

  // ---- User Profile methods ----

  /// Save (create or update) a user profile
  Future<void> saveUser(UserProfile user) async {
    try {
      await _databaseHelper.saveUser(user);
      final existingIndex = _users.indexWhere((u) => u.id == user.id);
      if (existingIndex >= 0) {
        _users[existingIndex] = user;
        if (_selectedUser?.id == user.id) {
          _selectedUser = user;
        }
      } else {
        _users.add(user);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user: $e');
      rethrow;
    }
  }

  /// Delete a user profile
  Future<void> deleteUser(String id) async {
    try {
      await _databaseHelper.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      if (_selectedUser?.id == id) {
        _selectedUser = null;
        await _databaseHelper.deleteSetting('selectedUserId');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  /// Select a user as the active user (or deselect if already selected)
  Future<void> selectUser(String id) async {
    try {
      if (_selectedUser?.id == id) {
        _selectedUser = null;
        await _databaseHelper.deleteSetting('selectedUserId');
      } else {
        try {
          _selectedUser = _users.firstWhere((u) => u.id == id);
        } catch (_) {
          _selectedUser = null;
        }
        if (_selectedUser != null) {
          await _databaseHelper.setSetting('selectedUserId', id);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error selecting user: $e');
    }
  }

  // ---- Phone sensor methods ----

  /// Update settings and restart the phone sensor service.
  Future<void> updatePhoneSensorSettings(PhoneSensorSettings settings) async {
    _phoneSensorSettings = settings;
    notifyListeners();
    if (settings.anyEnabled) {
      await _phoneSensorService.start(settings);
    } else {
      await _phoneSensorService.stop();
    }
  }

  /// Start phone sensors with current settings (called when an activity starts).
  Future<void> startPhoneSensors() async {
    if (_phoneSensorSettings.anyEnabled) {
      await _phoneSensorService.start(_phoneSensorSettings);
    }
  }

  /// Start phone sensors for an activity that requires smartphone data.
  /// Uses current settings if any sensors are enabled; otherwise falls back to
  /// accelerometer + gyroscope so that smartphone-based activities always have data.
  Future<void> startPhoneSensorsForActivity() async {
    final settings = _phoneSensorSettings.anyEnabled
        ? _phoneSensorSettings
        : const PhoneSensorSettings(
            accelerometerEnabled: true,
            gyroscopeEnabled: true,
          );
    await _phoneSensorService.start(settings);
  }

  /// Stop phone sensor collection.
  Future<void> stopPhoneSensors() async {
    await _phoneSensorService.stop();
  }
}
