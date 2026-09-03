/// Model representing sensor data from WT9011DCL-BT50 IMU sensor
class SensorData {
  final DateTime timestamp;
  
  // Acceleration (g)
  final double accelerationX;
  final double accelerationY;
  final double accelerationZ;
  
  // Angular Velocity (°/s)
  final double angularVelocityX;
  final double angularVelocityY;
  final double angularVelocityZ;
  
  // Euler Angles (°)
  final double roll;
  final double pitch;
  final double yaw;
  
  // Quaternion (for 3D rotation)
  final double quaternionW;
  final double quaternionX;
  final double quaternionY;
  final double quaternionZ;

  SensorData({
    DateTime? timestamp,
    this.accelerationX = 0.0,
    this.accelerationY = 0.0,
    this.accelerationZ = 0.0,
    this.angularVelocityX = 0.0,
    this.angularVelocityY = 0.0,
    this.angularVelocityZ = 0.0,
    this.roll = 0.0,
    this.pitch = 0.0,
    this.yaw = 0.0,
    this.quaternionW = 1.0,
    this.quaternionX = 0.0,
    this.quaternionY = 0.0,
    this.quaternionZ = 0.0,
  }) : timestamp = timestamp ?? DateTime.now();

  factory SensorData.empty() => SensorData();

  SensorData copyWith({
    DateTime? timestamp,
    double? accelerationX,
    double? accelerationY,
    double? accelerationZ,
    double? angularVelocityX,
    double? angularVelocityY,
    double? angularVelocityZ,
    double? roll,
    double? pitch,
    double? yaw,
    double? quaternionW,
    double? quaternionX,
    double? quaternionY,
    double? quaternionZ,
  }) {
    return SensorData(
      timestamp: timestamp ?? this.timestamp,
      accelerationX: accelerationX ?? this.accelerationX,
      accelerationY: accelerationY ?? this.accelerationY,
      accelerationZ: accelerationZ ?? this.accelerationZ,
      angularVelocityX: angularVelocityX ?? this.angularVelocityX,
      angularVelocityY: angularVelocityY ?? this.angularVelocityY,
      angularVelocityZ: angularVelocityZ ?? this.angularVelocityZ,
      roll: roll ?? this.roll,
      pitch: pitch ?? this.pitch,
      yaw: yaw ?? this.yaw,
      quaternionW: quaternionW ?? this.quaternionW,
      quaternionX: quaternionX ?? this.quaternionX,
      quaternionY: quaternionY ?? this.quaternionY,
      quaternionZ: quaternionZ ?? this.quaternionZ,
    );
  }

  @override
  String toString() {
    return 'SensorData(roll: $roll, pitch: $pitch, yaw: $yaw, '
        'accel: [$accelerationX, $accelerationY, $accelerationZ], '
        'gyro: [$angularVelocityX, $angularVelocityY, $angularVelocityZ])';
  }
}

/// Represents the connection state of a sensor
class SensorState {
  final String status;
  final String? deviceName;
  final String? deviceAddress;
  final int rssi;
  final int? batteryLevel;

  SensorState({
    required this.status,
    this.deviceName,
    this.deviceAddress,
    this.rssi = 0,
    this.batteryLevel,
  });

  factory SensorState.disconnected() => SensorState(status: 'Desconectado');
  
  factory SensorState.connected(String deviceName) => 
      SensorState(status: 'Conectado', deviceName: deviceName);
      
  factory SensorState.connecting() => SensorState(status: 'Conectando...');

  SensorState copyWith({
    String? status,
    String? deviceName,
    String? deviceAddress,
    int? rssi,
    int? batteryLevel,
  }) {
    return SensorState(
      status: status ?? this.status,
      deviceName: deviceName ?? this.deviceName,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      rssi: rssi ?? this.rssi,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }
}
