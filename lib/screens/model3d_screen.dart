import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/sensor_provider.dart';
import '../engine3d/quaternion.dart';
import '../engine3d/camera.dart';
import '../engine3d/humanoid.dart';
import '../engine3d/renderer.dart';

class Model3DScreen extends StatefulWidget {
  const Model3DScreen({super.key});

  @override
  State<Model3DScreen> createState() => _Model3DScreenState();
}

class _Model3DScreenState extends State<Model3DScreen>
    with SingleTickerProviderStateMixin {
  late final Scene3D scene;
  late final HumanoidModel humanoid;
  late final Camera3D camera;
  late AnimationController _anim;

  final Set<int> _activeSensors = {1, 2, 3, 4, 5};

  @override
  void initState() {
    super.initState();
    humanoid = HumanoidModel();
    camera = Camera3D();
    scene = Scene3D(humanoid: humanoid, camera: camera);

    _anim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 16),
        )..addListener(() {
          if (mounted) setState(() {});
        });
    _anim.repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _updateFromProvider(SensorProvider provider) {
    for (int i = 1; i <= provider.numberOfSensors; i++) {
      final state = provider.getSensorState(i);
      if (state.status != 'Conectado') continue;
      final data = provider.getSensorData(i);
      if (data == null) continue;

      final rawQ = Quat.fromEuler(
        data.roll * math.pi / 180,
        data.pitch * math.pi / 180,
        data.yaw * math.pi / 180,
      );
      final offset = SensorToBodyMapper.offset(i);
      final worldQ = rawQ
          .applyMountingOffset(offset)
          .sensorToWorld()
          .normalize();

      final boneName = SensorToBodyMapper.bone(i);
      if (boneName != null) {
        humanoid.skeleton.setBoneQ(boneName, worldQ);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    scene.showGrid = true;
    scene.showAxes = true;
    scene.showSensors = true;
    scene.showMesh = true;
    scene.showLines = true;
    scene.activeSensors = _activeSensors;

    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        _updateFromProvider(provider);
        return Scaffold(
          backgroundColor: const Color(
            0xFF0F141C,
          ), // Fundo escuro idêntico à Imagem 1
          body: Stack(
            children: [
              _build3DView(),
              _buildTopActionBar(),
              _buildSensorCards(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _build3DView() {
    return GestureDetector(
      onScaleStart: (_) {},
      onScaleUpdate: (details) {
        camera.orbit(
          details.focalPointDelta.dx * 0.5,
          details.focalPointDelta.dy * 0.5,
        );
        if (details.pointerCount >= 2) {
          camera.zoom(details.scale);
        }
      },
      child: RepaintBoundary(
        child: CustomPaint(
          painter: ScenePainter(scene: scene),
          size: Size.infinite,
        ),
      ),
    );
  }

  // Barra de ferramentas superior azulada/escura da Imagem 1
  Widget _buildTopActionBar() {
    return Positioned(
      top: 16,
      left: 12,
      right: 12,
      child: Row(
        children: [
          const Spacer(),
          _buildCircularIconBtn(
            Icons.refresh,
            onTap: () => humanoid.skeleton.resetPose(),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIconBtn(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, color: Colors.white70, size: 18),
      ),
    );
  }

  Widget _buildSensorCards(SensorProvider provider) {
    return Positioned(
      bottom: 16,
      left: 12,
      right: 12,
      child: SizedBox(
        height:
            95, // Altura maior para acomodar confortavelmente o design do card
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount:
              5, // Forçando os 5 slots para renderizar o grid como no mockup ideal
          itemBuilder: (context, index) {
            final slot = index + 1;
            final data = provider.getSensorData(slot);
            final color = Color(SensorToBodyMapper.color(slot));
            final name = SensorToBodyMapper.sensorLabel(slot);
            final isConnected =
                provider.getSensorState(slot).status == 'Conectado';

            return Opacity(
              opacity: isConnected
                  ? 1.0
                  : 0.4, // Deixa os desconectados opacos/desabilitados
              child: Container(
                width: 105,
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isConnected
                      ? color.withOpacity(0.06)
                      : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(isConnected ? 0.7 : 0.2),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'R: ${data != null ? data.roll.toStringAsFixed(1) : '0.0'}°',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'P: ${data != null ? data.pitch.toStringAsFixed(1) : '0.0'}°',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Y: ${data != null ? data.yaw.toStringAsFixed(1) : '0.0'}°',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
