/// Central configuration file for the AI Wearable Sensor app
///
/// This file contains all configurable settings for sensor management.
/// To add more sensors to your app, simply change the NUMBER_OF_SENSORS constant.
library app_config;

/// ============================================================================
/// SENSOR CONFIGURATION
/// ============================================================================
///
/// Configure how many Bluetooth sensors your app should support.
///
/// TO ADD A NEW SENSOR:
/// Simply increase this number. For example:
/// - If you have 5 sensors, set this to 5
/// - If you have 10 sensors, set this to 10
///
/// The app will automatically:
/// - Create sensor slots (sensor1, sensor2, sensor3, ..., sensorN)
/// - Manage connections for all sensors
/// - Display them in the UI
/// - Save their data during activities
///
/// NO CODE CHANGES REQUIRED - just change this number!
/// ============================================================================

const int NUMBER_OF_SENSORS = 5;

/// ============================================================================
/// BLUETOOTH CONFIGURATION
/// ============================================================================

/// Characteristic UUID for WT9011DCL sensor data
/// This UUID may need to be adjusted based on your actual device specifications
const String SENSOR_DATA_CHARACTERISTIC_UUID = 'ffe1';

/// Default scan timeout in seconds
const int BLUETOOTH_SCAN_TIMEOUT_SECONDS = 15;

/// Connection timeout in seconds
const int BLUETOOTH_CONNECTION_TIMEOUT_SECONDS = 10;

/// ============================================================================
/// SENSOR MAC ADDRESS MAPPING
/// ============================================================================

/// Map of sensor MAC addresses to their tags
/// Add or modify sensor mappings here
const Map<String, String> SENSOR_MAC_ADDRESS_MAP = {
  'EB:16:3F:37:5C:27': 's1',
  'C0:89:F5:9F:32:20': 's2',
  'DD:0F:4D:3B:A9:E9': 's3',
  'D4:16:EF:2F:2F:B4': 's4',
  'ED:D6:CC:F4:8C:54': 's5',
};

/// Get sensor tag from MAC address
/// Returns null if MAC address is not mapped
String? getSensorTagFromMac(String macAddress) {
  return SENSOR_MAC_ADDRESS_MAP[macAddress.toUpperCase()];
}

/// ============================================================================
/// DATA COLLECTION CONFIGURATION
/// ============================================================================

/// How often to collect sensor data during activities (in milliseconds)
/// 20ms = 50 Hz, 100ms = 10 Hz
const int DATA_COLLECTION_INTERVAL_MS = 20;

/// ============================================================================
/// UI CONFIGURATION
/// ============================================================================

/// Default sensor names (can be customized by user later)
List<String> getDefaultSensorNames() {
  return List.generate(NUMBER_OF_SENSORS, (index) => 'Sensor ${index + 1}');
}

/// Get sensor emoji/icon for display
String getSensorEmoji(int slotNumber) {
  // You can customize emojis for different sensors
  const emojis = ['📱', '⌚', '👟', '🎒', '🧢', '👕', '🎧', '💪', '🏃', '🚴'];
  if (slotNumber < 1 || slotNumber > emojis.length) {
    return '📡'; // Default
  }
  return emojis[slotNumber - 1];
}

/// ============================================================================
/// LLM / OPENAI CONFIGURATION
/// ============================================================================

/// OpenAI API key — set your key here or load from a secure store at runtime.
const String OPENAI_API_KEY = '';

/// OpenAI model to use for activity analysis
const String OPENAI_MODEL = 'gpt-4o-mini';

/// Get color for sensor slot
int getSensorColor(int slotNumber) {
  const colors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFFFEB3B, // Yellow
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];
  if (slotNumber < 1 || slotNumber > colors.length) {
    return 0xFF9E9E9E; // Grey
  }
  return colors[slotNumber - 1];
}
