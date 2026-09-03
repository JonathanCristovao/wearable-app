import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as vm;

class IMUQuaternion {
  final double x, y, z, w;

  const IMUQuaternion(this.x, this.y, this.z, this.w);

  factory IMUQuaternion.identity() => const IMUQuaternion(0, 0, 0, 1);

  factory IMUQuaternion.fromEuler(double roll, double pitch, double yaw) {
    final cr = math.cos(roll * 0.5);
    final sr = math.sin(roll * 0.5);
    final cp = math.cos(pitch * 0.5);
    final sp = math.sin(pitch * 0.5);
    final cy = math.cos(yaw * 0.5);
    final sy = math.sin(yaw * 0.5);

    return IMUQuaternion(
      sr * cp * cy - cr * sp * sy,
      cr * sp * cy + sr * cp * sy,
      cr * cp * sy - sr * sp * cy,
      cr * cp * cy + sr * sp * sy,
    );
  }

  factory IMUQuaternion.fromVector(vm.Quaternion q) => IMUQuaternion(q.x, q.y, q.z, q.w);

  factory IMUQuaternion.fromSensorData({
    required double roll,
    required double pitch,
    required double yaw,
    double qw = 1.0,
    double qx = 0.0,
    double qy = 0.0,
    double qz = 0.0,
  }) {
    if (qw != 1.0 || qx != 0.0 || qy != 0.0 || qz != 0.0) {
      return IMUQuaternion(qx, qy, qz, qw).normalize();
    }
    return IMUQuaternion.fromEuler(roll, pitch, yaw);
  }

  IMUQuaternion multiply(IMUQuaternion other) {
    return IMUQuaternion(
      w * other.x + x * other.w + y * other.z - z * other.y,
      w * other.y - x * other.z + y * other.w + z * other.x,
      w * other.z + x * other.y - y * other.x + z * other.w,
      w * other.w - x * other.x - y * other.y - z * other.z,
    );
  }

  IMUQuaternion conjugate() => IMUQuaternion(-x, -y, -z, w);

  IMUQuaternion normalize() {
    final mag = math.sqrt(w * w + x * x + y * y + z * z);
    if (mag < 0.0001) return IMUQuaternion.identity();
    final invMag = 1.0 / mag;
    return IMUQuaternion(x * invMag, y * invMag, z * invMag, w * invMag);
  }

  IMUQuaternion inverse() {
    final mag = w * w + x * x + y * y + z * z;
    return IMUQuaternion(-x / mag, -y / mag, -z / mag, w / mag);
  }

  vm.Quaternion toVectorQuaternion() => vm.Quaternion(x, y, z, w);

  List<double> toColumnMajor() {
    final x2 = x * x, y2 = y * y, z2 = z * z;
    final xy = x * y, xz = x * z, yz = y * z;
    final wx = w * x, wy = w * y, wz = w * z;

    return [
      1 - 2 * (y2 + z2), 2 * (xy + wz), 2 * (xz - wy), 0,
      2 * (xy - wz), 1 - 2 * (x2 + z2), 2 * (yz + wx), 0,
      2 * (xz + wy), 2 * (yz - wx), 1 - 2 * (x2 + y2), 0,
      0, 0, 0, 1,
    ];
  }

  double get roll {
    final sinrCosp = 2 * (w * x + y * z);
    final cosrCosp = 1 - 2 * (x * x + y * y);
    return math.atan2(sinrCosp, cosrCosp);
  }

  double get pitch {
    final sinp = 2 * (w * y - z * x);
    if (sinp.abs() >= 1) {
      return (math.pi / 2) * sinp.sign;
    }
    return math.asin(sinp);
  }

  double get yaw {
    final sinyCosp = 2 * (w * z + x * y);
    final cosyCosp = 1 - 2 * (y * y + z * z);
    return math.atan2(sinyCosp, cosyCosp);
  }

  IMUQuaternion sensorToWorld() => IMUQuaternion(-x, -z, -y, w);
  IMUQuaternion worldToSensor() => IMUQuaternion(-x, -z, -y, w);

  IMUQuaternion applyMountingOffset(IMUQuaternion offset) {
    return offset.multiply(this).multiply(offset.conjugate());
  }

  static IMUQuaternion slerp(IMUQuaternion a, IMUQuaternion b, double t) {
    var cosHalfTheta = a.w * b.w + a.x * b.x + a.y * b.y + a.z * b.z;
    if (cosHalfTheta < 0) {
      b = IMUQuaternion(-b.x, -b.y, -b.z, -b.w);
      cosHalfTheta = -cosHalfTheta;
    }

    double halfTheta;
    double sinHalfTheta;
    if ((1.0 - cosHalfTheta).abs() > 0.001) {
      halfTheta = math.acos(cosHalfTheta);
      sinHalfTheta = math.sin(halfTheta);
    } else {
      return IMUQuaternion(
        a.x * 0.5 + b.x * 0.5,
        a.y * 0.5 + b.y * 0.5,
        a.z * 0.5 + b.z * 0.5,
        a.w * 0.5 + b.w * 0.5,
      ).normalize();
    }

    final ratioA = math.sin((1 - t) * halfTheta) / sinHalfTheta;
    final ratioB = math.sin(t * halfTheta) / sinHalfTheta;

    return IMUQuaternion(
      a.x * ratioA + b.x * ratioB,
      a.y * ratioA + b.y * ratioB,
      a.z * ratioA + b.z * ratioB,
      a.w * ratioA + b.w * ratioB,
    ).normalize();
  }
}

class Bone {
  final String name;
  final String parentName;
  final double length;
  final double thickness;
  IMUQuaternion localRotation;
  vm.Vector3 localPosition;
  vm.Matrix4 worldMatrix;
  vm.Matrix4 localMatrix;

  Bone({
    required this.name,
    this.parentName = '',
    this.length = 0.3,
    this.thickness = 0.03,
    IMUQuaternion? localRotation,
    vm.Vector3? localPosition,
  })  : localRotation = localRotation ?? IMUQuaternion.identity(),
        localPosition = localPosition ?? vm.Vector3.zero(),
        worldMatrix = vm.Matrix4.identity(),
        localMatrix = vm.Matrix4.identity() {
    _updateLocalMatrix();
  }

  void _updateLocalMatrix() {
    final rotMatrix = localRotation.toColumnMajor();
    localMatrix.setEntry(0, 0, rotMatrix[0]);
    localMatrix.setEntry(0, 1, rotMatrix[1]);
    localMatrix.setEntry(0, 2, rotMatrix[2]);
    localMatrix.setEntry(1, 0, rotMatrix[4]);
    localMatrix.setEntry(1, 1, rotMatrix[5]);
    localMatrix.setEntry(1, 2, rotMatrix[6]);
    localMatrix.setEntry(2, 0, rotMatrix[8]);
    localMatrix.setEntry(2, 1, rotMatrix[9]);
    localMatrix.setEntry(2, 2, rotMatrix[10]);
    localMatrix.setEntry(3, 3, 1);
    localMatrix.setTranslation(localPosition);
  }

  void setLocalRotationFromEuler(double roll, double pitch, double yaw) {
    localRotation = IMUQuaternion.fromEuler(roll, pitch, yaw);
    _updateLocalMatrix();
  }

  void setLocalRotationFromQuaternion(IMUQuaternion q) {
    localRotation = q.normalize();
    _updateLocalMatrix();
  }

  void updateWorldMatrix(vm.Matrix4 parentWorldMatrix) {
    worldMatrix = parentWorldMatrix * localMatrix;
  }

  vm.Vector3 getWorldPosition() {
    return vm.Vector3(worldMatrix.getTranslation().x, worldMatrix.getTranslation().y, worldMatrix.getTranslation().z);
  }

  vm.Vector3 getWorldEndPosition() {
    final endLocal = vm.Vector3(0, length, 0);
    return worldMatrix.transform3(endLocal);
  }
}

class Skeleton {
  final Map<String, Bone> bones = {};
  Bone? rootBone;

  Skeleton() {
    _buildSkeleton();
  }

  void _buildSkeleton() {
    bones['pelvis'] = Bone(name: 'pelvis', length: 0.15, thickness: 0.08);
    rootBone = bones['pelvis'];

    bones['spine'] = Bone(name: 'spine', parentName: 'pelvis', length: 0.25, thickness: 0.07);
    bones['neck'] = Bone(name: 'neck', parentName: 'spine', length: 0.10, thickness: 0.05);
    bones['head'] = Bone(name: 'head', parentName: 'neck', length: 0.20, thickness: 0.10);

    bones['left_shoulder'] = Bone(name: 'left_shoulder', parentName: 'spine', length: 0.15, thickness: 0.04);
    bones['left_upper_arm'] = Bone(name: 'left_upper_arm', parentName: 'left_shoulder', length: 0.25, thickness: 0.035);
    bones['left_forearm'] = Bone(name: 'left_forearm', parentName: 'left_upper_arm', length: 0.25, thickness: 0.03);

    bones['right_shoulder'] = Bone(name: 'right_shoulder', parentName: 'spine', length: 0.15, thickness: 0.04);
    bones['right_upper_arm'] = Bone(name: 'right_upper_arm', parentName: 'right_shoulder', length: 0.25, thickness: 0.035);
    bones['right_forearm'] = Bone(name: 'right_forearm', parentName: 'right_upper_arm', length: 0.25, thickness: 0.03);

    bones['left_hip'] = Bone(name: 'left_hip', parentName: 'pelvis', length: 0.10, thickness: 0.05);
    bones['left_thigh'] = Bone(name: 'left_thigh', parentName: 'left_hip', length: 0.40, thickness: 0.05);
    bones['left_calf'] = Bone(name: 'left_calf', parentName: 'left_thigh', length: 0.40, thickness: 0.04);
    bones['left_foot'] = Bone(name: 'left_foot', parentName: 'left_calf', length: 0.20, thickness: 0.04);

    bones['right_hip'] = Bone(name: 'right_hip', parentName: 'pelvis', length: 0.10, thickness: 0.05);
    bones['right_thigh'] = Bone(name: 'right_thigh', parentName: 'right_hip', length: 0.40, thickness: 0.05);
    bones['right_calf'] = Bone(name: 'right_calf', parentName: 'right_thigh', length: 0.40, thickness: 0.04);
    bones['right_foot'] = Bone(name: 'right_foot', parentName: 'right_calf', length: 0.20, thickness: 0.04);

    _setDefaultPositions();
  }

  void _setDefaultPositions() {
    bones['spine']!.localPosition = vm.Vector3(0, 0.15, 0);
    bones['neck']!.localPosition = vm.Vector3(0, 0.25, 0);
    bones['head']!.localPosition = vm.Vector3(0, 0.10, 0);

    bones['left_shoulder']!.localPosition = vm.Vector3(-0.15, 0.20, 0);
    bones['left_upper_arm']!.localPosition = vm.Vector3(0, 0.15, 0);
    bones['left_forearm']!.localPosition = vm.Vector3(0, 0.25, 0);

    bones['right_shoulder']!.localPosition = vm.Vector3(0.15, 0.20, 0);
    bones['right_upper_arm']!.localPosition = vm.Vector3(0, 0.15, 0);
    bones['right_forearm']!.localPosition = vm.Vector3(0, 0.25, 0);

    bones['left_hip']!.localPosition = vm.Vector3(-0.08, 0, 0);
    bones['left_thigh']!.localPosition = vm.Vector3(0, 0.10, 0);
    bones['left_calf']!.localPosition = vm.Vector3(0, 0.40, 0);
    bones['left_foot']!.localPosition = vm.Vector3(0, 0.40, 0);

    bones['right_hip']!.localPosition = vm.Vector3(0.08, 0, 0);
    bones['right_thigh']!.localPosition = vm.Vector3(0, 0.10, 0);
    bones['right_calf']!.localPosition = vm.Vector3(0, 0.40, 0);
    bones['right_foot']!.localPosition = vm.Vector3(0, 0.40, 0);

    for (final bone in bones.values) {
      bone._updateLocalMatrix();
    }
  }

  void updateBones() {
    if (rootBone == null) return;
    rootBone!.updateWorldMatrix(vm.Matrix4.identity());

    for (final entry in bones.entries) {
      final bone = entry.value;
      if (bone.parentName.isEmpty) continue;
      final parent = bones[bone.parentName];
      if (parent != null) {
        bone.updateWorldMatrix(parent.worldMatrix);
      }
    }
  }

  void setBoneRotation(String boneName, double roll, double pitch, double yaw) {
    final bone = bones[boneName];
    if (bone != null) {
      bone.setLocalRotationFromEuler(roll, pitch, yaw);
    }
  }

  void setBoneRotationQuaternion(String boneName, IMUQuaternion q) {
    final bone = bones[boneName];
    if (bone != null) {
      bone.setLocalRotationFromQuaternion(q);
    }
  }

  List<Bone> get allBones => bones.values.toList();
}

class SensorMapper {
  static const Map<int, String> sensorToBone = {
    1: 'left_thigh',
    2: 'right_thigh',
    3: 'left_calf',
    4: 'right_calf',
    5: 'right_foot',
  };

  static const Map<int, List<double>> mountingOffsets = {
    1: [0, 0, 90],
    2: [0, 0, -90],
    3: [0, 0, 90],
    4: [0, 0, -90],
    5: [0, 0, -90],
  };

  static const Map<int, int> sensorColors = {
    1: 0xFF2196F3,
    2: 0xFF4CAF50,
    3: 0xFFF44336,
    4: 0xFFFF9800,
    5: 0xFF9C27B0,
  };

  static String? getBoneName(int sensorSlot) => sensorToBone[sensorSlot];

  static IMUQuaternion getMountingOffset(int sensorSlot) {
    final offsets = mountingOffsets[sensorSlot];
    if (offsets == null) return IMUQuaternion.identity();
    return IMUQuaternion.fromEuler(
      offsets[0] * math.pi / 180,
      offsets[1] * math.pi / 180,
      offsets[2] * math.pi / 180,
    );
  }

  static int getSensorColor(int sensorSlot) => sensorColors[sensorSlot] ?? 0xFF9E9E9E;
}

class IMUData {
  final int sensorSlot;
  final IMUQuaternion rotation;
  final double roll;
  final double pitch;
  final double yaw;
  final bool isConnected;

  IMUData({
    required this.sensorSlot,
    required this.rotation,
    required this.roll,
    required this.pitch,
    required this.yaw,
    this.isConnected = false,
  });
}