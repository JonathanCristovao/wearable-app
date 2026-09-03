/// Represents a snapshot of all available smartphone sensor readings
class PhoneSensorData {
  final DateTime timestamp;

  // Accelerometer (m/s²)
  final double? accelX;
  final double? accelY;
  final double? accelZ;

  // Gyroscope (rad/s)
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;

  // Magnetometer / Compass (µT)
  final double? magX;
  final double? magY;
  final double? magZ;

  // GPS
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? gpsSpeed; // m/s
  final double? gpsAccuracy; // meters
  final double? gpsBearing; // degrees

  // Barometric pressure (hPa) – via sensors_plus
  final double? barometricPressure;

  PhoneSensorData({
    DateTime? timestamp,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.magX,
    this.magY,
    this.magZ,
    this.latitude,
    this.longitude,
    this.altitude,
    this.gpsSpeed,
    this.gpsAccuracy,
    this.gpsBearing,
    this.barometricPressure,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PhoneSensorData.empty() => PhoneSensorData();

  PhoneSensorData copyWith({
    DateTime? timestamp,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    double? magX,
    double? magY,
    double? magZ,
    double? latitude,
    double? longitude,
    double? altitude,
    double? gpsSpeed,
    double? gpsAccuracy,
    double? gpsBearing,
    double? barometricPressure,
  }) {
    return PhoneSensorData(
      timestamp: timestamp ?? this.timestamp,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      magX: magX ?? this.magX,
      magY: magY ?? this.magY,
      magZ: magZ ?? this.magZ,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      gpsSpeed: gpsSpeed ?? this.gpsSpeed,
      gpsAccuracy: gpsAccuracy ?? this.gpsAccuracy,
      gpsBearing: gpsBearing ?? this.gpsBearing,
      barometricPressure: barometricPressure ?? this.barometricPressure,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      if (accelX != null) 'accelX': accelX,
      if (accelY != null) 'accelY': accelY,
      if (accelZ != null) 'accelZ': accelZ,
      if (gyroX != null) 'gyroX': gyroX,
      if (gyroY != null) 'gyroY': gyroY,
      if (gyroZ != null) 'gyroZ': gyroZ,
      if (magX != null) 'magX': magX,
      if (magY != null) 'magY': magY,
      if (magZ != null) 'magZ': magZ,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (gpsSpeed != null) 'gpsSpeed': gpsSpeed,
      if (gpsAccuracy != null) 'gpsAccuracy': gpsAccuracy,
      if (gpsBearing != null) 'gpsBearing': gpsBearing,
      if (barometricPressure != null) 'barometricPressure': barometricPressure,
    };
  }

  factory PhoneSensorData.fromJson(Map<String, dynamic> json) {
    return PhoneSensorData(
      timestamp: DateTime.parse(json['timestamp']),
      accelX: json['accelX']?.toDouble(),
      accelY: json['accelY']?.toDouble(),
      accelZ: json['accelZ']?.toDouble(),
      gyroX: json['gyroX']?.toDouble(),
      gyroY: json['gyroY']?.toDouble(),
      gyroZ: json['gyroZ']?.toDouble(),
      magX: json['magX']?.toDouble(),
      magY: json['magY']?.toDouble(),
      magZ: json['magZ']?.toDouble(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      gpsSpeed: json['gpsSpeed']?.toDouble(),
      gpsAccuracy: json['gpsAccuracy']?.toDouble(),
      gpsBearing: json['gpsBearing']?.toDouble(),
      barometricPressure: json['barometricPressure']?.toDouble(),
    );
  }
}

/// Settings for which phone sensors are enabled by the user
class PhoneSensorSettings {
  final bool accelerometerEnabled;
  final bool gyroscopeEnabled;
  final bool magnetometerEnabled;
  final bool gpsEnabled;
  final bool barometerEnabled;

  const PhoneSensorSettings({
    this.accelerometerEnabled = false,
    this.gyroscopeEnabled = false,
    this.magnetometerEnabled = false,
    this.gpsEnabled = false,
    this.barometerEnabled = false,
  });

  bool get anyEnabled =>
      accelerometerEnabled ||
      gyroscopeEnabled ||
      magnetometerEnabled ||
      gpsEnabled ||
      barometerEnabled;

  PhoneSensorSettings copyWith({
    bool? accelerometerEnabled,
    bool? gyroscopeEnabled,
    bool? magnetometerEnabled,
    bool? gpsEnabled,
    bool? barometerEnabled,
  }) {
    return PhoneSensorSettings(
      accelerometerEnabled: accelerometerEnabled ?? this.accelerometerEnabled,
      gyroscopeEnabled: gyroscopeEnabled ?? this.gyroscopeEnabled,
      magnetometerEnabled: magnetometerEnabled ?? this.magnetometerEnabled,
      gpsEnabled: gpsEnabled ?? this.gpsEnabled,
      barometerEnabled: barometerEnabled ?? this.barometerEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'accelerometerEnabled': accelerometerEnabled,
    'gyroscopeEnabled': gyroscopeEnabled,
    'magnetometerEnabled': magnetometerEnabled,
    'gpsEnabled': gpsEnabled,
    'barometerEnabled': barometerEnabled,
  };

  factory PhoneSensorSettings.fromJson(Map<String, dynamic> json) =>
      PhoneSensorSettings(
        accelerometerEnabled: json['accelerometerEnabled'] ?? false,
        gyroscopeEnabled: json['gyroscopeEnabled'] ?? false,
        magnetometerEnabled: json['magnetometerEnabled'] ?? false,
        gpsEnabled: json['gpsEnabled'] ?? false,
        barometerEnabled: json['barometerEnabled'] ?? false,
      );
}
