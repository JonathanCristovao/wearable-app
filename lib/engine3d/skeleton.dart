import 'quaternion.dart';

class Bone {
  final String name;
  final String parentName;
  double length;
  double thickness;
  Vec3 localPos;
  Quat localRot;
  Mat4 localMatrix;
  Mat4 worldMatrix;
  bool isRoot;

  Bone({
    required this.name,
    this.parentName = '',
    this.length = 0.3,
    this.thickness = 0.03,
    Vec3? localPos,
    Quat? localRot,
  }) : localPos = localPos ?? Vec3.zero(),
       localRot = localRot ?? Quat.identity(),
       localMatrix = Mat4.identity(),
       worldMatrix = Mat4.identity(),
       isRoot = false {
    _updateLocal();
  }

  void _updateLocal() {
    localMatrix = Mat4.translation(
      localPos.x,
      localPos.y,
      localPos.z,
    ).multiply(Mat4.fromQuaternion(localRot));
  }

  void setRotation(Quat q) {
    localRot = q.normalize();
    _updateLocal();
  }

  void updateWorld(Mat4 parentWorld) {
    worldMatrix = parentWorld.multiply(localMatrix);
  }

  Vec3 get worldPos =>
      Vec3(worldMatrix.d[12], worldMatrix.d[13], worldMatrix.d[14]);

  Vec3 get worldEnd {
    return worldMatrix.transformPoint(Vec3(0, length, 0));
  }

  Vec3 get worldDir {
    final e = worldMatrix.transform(Vec3(0, 1, 0));
    final s = worldPos;
    return (e - s).normalize();
  }
}

class Skeleton {
  final Map<String, Bone> bones = {};
  final List<String> _updateOrder = [];

  Skeleton() {
    _build();
  }

  void _add(String name, String parent, double len, double thick, [Vec3? pos]) {
    bones[name] = Bone(
      name: name,
      parentName: parent,
      length: len,
      thickness: thick,
      localPos: pos,
    );
  }

  void _build() {
    // Tronco Central e Cabeça (Mantido original)
    _add('pelvis', '', 0.12, 0.08);
    _add('spine', 'pelvis', 0.22, 0.06, Vec3(0, 0.12, 0));
    _add('chest', 'spine', 0.18, 0.06, Vec3(0, 0.22, 0));
    _add('neck', 'chest', 0.08, 0.04, Vec3(0, 0.18, 0));
    _add('head', 'neck', 0.18, 0.09, Vec3(0, 0.08, 0));

    // BRAÇO ESQUERDO (Diminuído o tamanho e ajustado o encaixe)
    _add('left_clavicle', 'chest', 0.08, 0.04, Vec3(-0.12, 0.14, 0));
    _add('left_upper_arm', 'left_clavicle', 0.18, 0.032, Vec3(-0.08, 0, 0));
    _add('left_forearm', 'left_upper_arm', 0.18, 0.028, Vec3(0, 0.18, 0));
    _add('left_hand', 'left_forearm', 0.08, 0.022, Vec3(0, 0.18, 0));

    // BRAÇO DIREITO (Diminuído o tamanho e ajustado o encaixe)
    _add('right_clavicle', 'chest', 0.08, 0.04, Vec3(0.12, 0.14, 0));
    _add('right_upper_arm', 'right_clavicle', 0.18, 0.032, Vec3(0.08, 0, 0));
    _add('right_forearm', 'right_upper_arm', 0.18, 0.028, Vec3(0, 0.18, 0));
    _add('right_hand', 'right_forearm', 0.08, 0.022, Vec3(0, 0.18, 0));

    // PERNA ESQUERDA (Conectada perfeitamente usando eixos locais)
    _add('left_hip_joint', 'pelvis', 0.06, 0.05, Vec3(-0.10, 0, 0));
    _add('left_thigh', 'left_hip_joint', 0.38, 0.045, Vec3(0, -0.06, 0));
    _add('left_calf', 'left_thigh', 0.38, 0.040, Vec3(0, -0.38, 0));
    _add('left_foot', 'left_calf', 0.14, 0.032, Vec3(0, -0.38, 0.04));

    // PERNA DIREITA (Conectada perfeitamente usando eixos locais)
    _add('right_hip_joint', 'pelvis', 0.06, 0.05, Vec3(0.10, 0, 0));
    _add('right_thigh', 'right_hip_joint', 0.38, 0.045, Vec3(0, -0.06, 0));
    _add('right_calf', 'right_thigh', 0.38, 0.040, Vec3(0, -0.38, 0));
    _add('right_foot', 'right_calf', 0.14, 0.032, Vec3(0, -0.38, 0.04));

    _buildUpdateOrder();
  }

  void _buildUpdateOrder() {
    _updateOrder.clear();
    final queue = <String>[];
    for (final b in bones.values) {
      if (b.parentName.isEmpty) queue.add(b.name);
    }
    while (queue.isNotEmpty) {
      final name = queue.removeAt(0);
      _updateOrder.add(name);
      for (final b in bones.values) {
        if (b.parentName == name) queue.add(b.name);
      }
    }
  }

  void updateWorld() {
    for (final name in _updateOrder) {
      final b = bones[name];
      if (b == null) continue;
      if (b.parentName.isEmpty) {
        b.updateWorld(Mat4.translation(0, 0.9, 0));
      } else {
        final p = bones[b.parentName];
        if (p != null) b.updateWorld(p.worldMatrix);
      }
    }
  }

  Bone? operator [](String name) => bones[name];

  void setBoneQ(String name, Quat q) {
    final b = bones[name];
    if (b != null) b.setRotation(q);
  }

  Vec3 getBoneWorldPos(String name) => bones[name]?.worldPos ?? Vec3.zero();
  Vec3 getBoneWorldEnd(String name) => bones[name]?.worldEnd ?? Vec3.zero();

  List<Bone> get allBones => _updateOrder.map((n) => bones[n]!).toList();

  void resetPose() {
    for (final b in bones.values) {
      b.setRotation(Quat.identity());
    }
    updateWorld();
  }
}
