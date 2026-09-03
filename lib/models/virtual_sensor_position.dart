import 'dart:math' as math;
import 'sensor_data.dart';

class MotionState {
  double x;
  double y;
  double z;
  double vx;
  double vy;
  double vz;
  double ax;
  double ay;
  double az;

  MotionState({
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.vx = 0,
    this.vy = 0,
    this.vz = 0,
    this.ax = 0,
    this.ay = 0,
    this.az = 0,
  });

  void reset() {
    x = y = z = 0;
    vx = vy = vz = 0;
    ax = ay = az = 0;
  }
}

class MotionIntegrator {
  final MotionState world = MotionState();
  static const double _gravity = 9.81;

  void update(SensorData data, double dt) {
    final rawAx = data.accelerationX * _gravity;
    final rawAy = data.accelerationY * _gravity;
    final rawAz = data.accelerationZ * _gravity;

    final yawRad = data.yaw * math.pi / 180;
    final pitchRad = data.pitch * math.pi / 180;
    final rollRad = data.roll * math.pi / 180;

    final cy = math.cos(yawRad);
    final sy = math.sin(yawRad);
    final cp = math.cos(pitchRad);
    final sp = math.sin(pitchRad);
    final cr = math.cos(rollRad);
    final sr = math.sin(rollRad);

    world.ax = rawAx * cp * cr + rawAy * (sr * sp * cr - cy * sr) + rawAz * (cp * sr * cr + sp * sy);
    world.ay = rawAx * cp * sr + rawAy * (cy * cr + sr * sp * sr) + rawAz * (cr * sp * sr - cp * sy);
    world.az = -rawAx * sp + rawAy * (cp * sy) + rawAz * (cp * cy);

    world.vx += world.ax * dt;
    world.vy += world.ay * dt;
    world.vz += world.az * dt;

    world.vx *= 0.98;
    world.vy *= 0.98;
    world.vz *= 0.98;

    world.x += world.vx * dt;
    world.y += world.vy * dt;
    world.z += world.vz * dt;
  }

  double get positionX => world.x;
  double get positionY => world.y;
  double get positionZ => world.z;
  double get velocityX => world.vx;
  double get velocityY => world.vy;
  double get velocityZ => world.vz;
}

class VirtualSensorPosition {
  final int sensorSlotNumber;
  final String name;
  final double x;
  final double y;
  final double z;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final int colorValue;
  final bool isSelected;
  final bool isVisible;
  final SensorData? lastData;

  const VirtualSensorPosition({
    required this.sensorSlotNumber,
    required this.name,
    this.x = 0.0,
    this.y = 0.0,
    this.z = 0.0,
    this.rotationX = 0.0,
    this.rotationY = 0.0,
    this.rotationZ = 0.0,
    required this.colorValue,
    this.isSelected = false,
    this.isVisible = true,
    this.lastData,
  });

  VirtualSensorPosition copyWith({
    int? sensorSlotNumber,
    String? name,
    double? x,
    double? y,
    double? z,
    double? rotationX,
    double? rotationY,
    double? rotationZ,
    int? colorValue,
    bool? isSelected,
    bool? isVisible,
    SensorData? lastData,
  }) {
    return VirtualSensorPosition(
      sensorSlotNumber: sensorSlotNumber ?? this.sensorSlotNumber,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      rotationX: rotationX ?? this.rotationX,
      rotationY: rotationY ?? this.rotationY,
      rotationZ: rotationZ ?? this.rotationZ,
      colorValue: colorValue ?? this.colorValue,
      isSelected: isSelected ?? this.isSelected,
      isVisible: isVisible ?? this.isVisible,
      lastData: lastData ?? this.lastData,
    );
  }

  double get roll => lastData?.roll ?? rotationX;
  double get pitch => lastData?.pitch ?? rotationY;
  double get yaw => lastData?.yaw ?? rotationZ;

  double get rollRad => roll * math.pi / 180.0;
  double get pitchRad => pitch * math.pi / 180.0;
  double get yawRad => yaw * math.pi / 180.0;
}

class SensorPlacementPreset {
  final String id;
  final String name;
  final String description;
  final Map<int, Position3D> positions;

  const SensorPlacementPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.positions,
  });
}

class Position3D {
  final double x;
  final double y;
  final double z;
  final double rotX;
  final double rotY;
  final double rotZ;

  const Position3D({
    required this.x,
    required this.y,
    required this.z,
    this.rotX = 0,
    this.rotY = 0,
    this.rotZ = 0,
  });
}

class PlacementPresets {
  static const humanBody = SensorPlacementPreset(
    id: 'human_body',
    name: 'Corpo Humano',
    description: 'Posicionamento típico em corpo humano',
    positions: {
      1: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      2: Position3D(x: 0, y: 1.5, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      3: Position3D(x: -0.5, y: 1.0, z: 0, rotX: 0, rotY: 90, rotZ: 0),
      4: Position3D(x: 0.5, y: 1.0, z: 0, rotX: 0, rotY: -90, rotZ: 0),
      5: Position3D(x: 0, y: 0.5, z: -0.3, rotX: 0, rotY: 0, rotZ: 0),
    },
  );

  static const wearable = SensorPlacementPreset(
    id: 'wearable',
    name: 'Wearable',
    description: 'Dispositivo vestível (relógio, pulseira)',
    positions: {
      1: Position3D(x: 0, y: -1, z: 0, rotX: 0, rotY: 0, rotZ: 90),
      2: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      3: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      4: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      5: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
    },
  );

  static const robotics = SensorPlacementPreset(
    id: 'robotics',
    name: 'Robótica',
    description: 'Posicionamento para robôs e drones',
    positions: {
      1: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      2: Position3D(x: 1, y: 0, z: 0, rotX: 0, rotY: 90, rotZ: 0),
      3: Position3D(x: -1, y: 0, z: 0, rotX: 0, rotY: -90, rotZ: 0),
      4: Position3D(x: 0, y: 1, z: 0, rotX: 90, rotY: 0, rotZ: 0),
      5: Position3D(x: 0, y: -1, z: 0, rotX: -90, rotY: 0, rotZ: 0),
    },
  );

  static const custom = SensorPlacementPreset(
    id: 'custom',
    name: 'Personalizado',
    description: 'Posicionamento personalizado',
    positions: {
      1: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      2: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      3: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      4: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
      5: Position3D(x: 0, y: 0, z: 0, rotX: 0, rotY: 0, rotZ: 0),
    },
  );

  static List<SensorPlacementPreset> get all => [humanBody, wearable, robotics, custom];
}