import 'package:flutter/material.dart';
import 'phone_sensor_data.dart';

class ActivityRecord {
  final String id;
  final String type; // 'walking', 'running', 'cycling'
  final String environment; // 'indoor', 'outdoor'
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final List<ActivityDataPoint> dataPoints;
  final String? userId;
  final String? userName;
  final String? emoji;

  ActivityRecord({
    required this.id,
    required this.type,
    required this.environment,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.dataPoints,
    this.userId,
    this.userName,
    this.emoji,
  });

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String get activityName {
    final typeMap = {
      'walking': 'Caminhada',
      'running': 'Corrida',
      'cycling': 'Bicicleta',
    };
    final envMap = {'indoor': 'Indoor', 'outdoor': 'Outdoor'};
    final typeName = typeMap[type] ?? type;
    final envName = envMap[environment];
    return envName != null ? '$typeName ($envName)' : typeName;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'environment': environment,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration.inSeconds,
      'dataPoints': dataPoints.map((dp) => dp.toJson()).toList(),
      if (userId != null) 'userId': userId,
      if (userName != null) 'userName': userName,
      if (emoji != null) 'emoji': emoji,
    };
  }

  factory ActivityRecord.fromJson(Map<String, dynamic> json) {
    return ActivityRecord(
      id: json['id'],
      type: json['type'],
      environment: json['environment'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(seconds: json['duration']),
      dataPoints: (json['dataPoints'] as List)
          .map((dp) => ActivityDataPoint.fromJson(dp))
          .toList(),
      userId: json['userId'] as String?,
      userName: json['userName'] as String?,
      emoji: json['emoji'] as String?,
    );
  }
}

class ActivityDataPoint {
  final DateTime timestamp;
  final Map<String, SensorSnapshot> sensors;
  final PhoneSensorData? phoneSensors;

  /// Fatigue level (0–4) marked by the user when pausing the activity.
  /// Null when not yet marked.
  int? fatigueLevel;

  ActivityDataPoint({
    required this.timestamp,
    required this.sensors,
    this.phoneSensors,
    this.fatigueLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'sensors': sensors.map((key, value) => MapEntry(key, value.toJson())),
      if (phoneSensors != null) 'phoneSensors': phoneSensors!.toJson(),
      if (fatigueLevel != null) 'fatigueLevel': fatigueLevel,
    };
  }

  factory ActivityDataPoint.fromJson(Map<String, dynamic> json) {
    return ActivityDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      sensors: (json['sensors'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, SensorSnapshot.fromJson(value)),
      ),
      phoneSensors: json['phoneSensors'] != null
          ? PhoneSensorData.fromJson(json['phoneSensors'])
          : null,
      fatigueLevel: json['fatigueLevel'] as int?,
    );
  }
}

class SensorSnapshot {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final double roll;
  final double pitch;
  final double yaw;
  final double quaternionW;
  final double quaternionX;
  final double quaternionY;
  final double quaternionZ;

  SensorSnapshot({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.roll,
    required this.pitch,
    required this.yaw,
    this.quaternionW = 1.0,
    this.quaternionX = 0.0,
    this.quaternionY = 0.0,
    this.quaternionZ = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'roll': roll,
      'pitch': pitch,
      'yaw': yaw,
      'quaternionW': quaternionW,
      'quaternionX': quaternionX,
      'quaternionY': quaternionY,
      'quaternionZ': quaternionZ,
    };
  }

  factory SensorSnapshot.fromJson(Map<String, dynamic> json) {
    return SensorSnapshot(
      accelX: json['accelX'],
      accelY: json['accelY'],
      accelZ: json['accelZ'],
      gyroX: json['gyroX'],
      gyroY: json['gyroY'],
      gyroZ: json['gyroZ'],
      roll: json['roll'],
      pitch: json['pitch'],
      yaw: json['yaw'],
      quaternionW: json['quaternionW'] as double? ?? 1.0,
      quaternionX: json['quaternionX'] as double? ?? 0.0,
      quaternionY: json['quaternionY'] as double? ?? 0.0,
      quaternionZ: json['quaternionZ'] as double? ?? 0.0,
    );
  }
}

class ActivityType {
  final String id;
  final String name;
  final String environment;
  final IconData icon;
  final String? emoji;
  final bool isCustom;
  final List<SensorPosition> requiredSensors;

  const ActivityType({
    required this.id,
    required this.name,
    required this.environment,
    required this.icon,
    this.emoji,
    this.isCustom = false,
    required this.requiredSensors,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'environment': environment,
      'emoji': emoji,
      'isCustom': isCustom,
      'requiredSensors': requiredSensors.map((s) => s.toJson()).toList(),
    };
  }

  factory ActivityType.fromJson(Map<String, dynamic> json) {
    return ActivityType(
      id: json['id'] as String,
      name: json['name'] as String,
      environment: json['environment'] as String? ?? 'custom',
      icon: Icons.category,
      emoji: json['emoji'] as String?,
      isCustom: json['isCustom'] as bool? ?? true,
      requiredSensors: (json['requiredSensors'] as List)
          .map((s) => SensorPosition.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SensorPosition {
  final String id;
  final String name;
  final String description;
  final String? sensorDevice;

  const SensorPosition({
    required this.id,
    required this.name,
    required this.description,
    this.sensorDevice,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (sensorDevice != null) 'sensorDevice': sensorDevice,
    };
  }

  factory SensorPosition.fromJson(Map<String, dynamic> json) {
    return SensorPosition(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      sensorDevice: json['sensorDevice'] as String?,
    );
  }
}
