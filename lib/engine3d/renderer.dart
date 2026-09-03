import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'quaternion.dart';
import 'camera.dart';
import 'humanoid.dart';

class Scene3D {
  final HumanoidModel humanoid;
  final Camera3D camera;
  bool showLines = true;
  bool showMesh = true;
  bool showGrid = true;
  bool showAxes = true;
  bool showSensors = true;
  Set<int> activeSensors = {1, 2, 3, 4, 5};
  bool showNames = true;
  final Map<int, Quat> sensorQ = {};
  final Map<int, Vec3> sensorPos = {};

  Scene3D({required this.humanoid, required this.camera});

  void render(double sw, double sh) {
    camera.aspect = sw / sh;
    humanoid.updateSkeleton();
    humanoid.render(camera, sw, sh);
  }
}

class ScenePainter extends CustomPainter {
  final Scene3D scene;

  ScenePainter({required this.scene});

  double _sw = 0, _sh = 0;

  @override
  void paint(Canvas canvas, Size size) {
    _sw = size.width;
    _sh = size.height;
    scene.render(_sw, _sh);

    if (scene.showGrid) _drawGrid(canvas, _sw, _sh);
    if (scene.showAxes) _draw3DAxes(canvas, _sw, _sh);

    final tris = scene.humanoid.triangles;
    tris.sort((a, b) => a.avgDepth.compareTo(b.avgDepth));
    for (final tri in tris) {
      _drawTri(canvas, tri);
    }

    final lines = scene.humanoid.lines;
    lines.sort((a, b) => a.depth.compareTo(b.depth));
    for (final line in lines) {
      _drawLine(canvas, line);
    }

    if (scene.showSensors) _drawSensors(canvas, _sw, _sh);
    _drawOverlayAxes(canvas, _sw, _sh);
  }

  void _drawLine(Canvas canvas, RenderLine line) {
    final p1 = scene.camera.project(line.start, _sw, _sh);
    final p2 = scene.camera.project(line.end, _sw, _sh);
    canvas.drawLine(
      Offset(p1.x, p1.y),
      Offset(p2.x, p2.y),
      Paint()
        ..color = Color(line.color)
        ..strokeWidth = line.thickness
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTri(Canvas canvas, RenderTri tri) {
    final p0 = scene.camera.project(tri.p0, _sw, _sh);
    final p1 = scene.camera.project(tri.p1, _sw, _sh);
    final p2 = scene.camera.project(tri.p2, _sw, _sh);

    if (p0.z <= 0 || p1.z <= 0 || p2.z <= 0) return;

    final paint = Paint()
      ..color = Color(tri.color).withAlpha((tri.alpha * 255).round())
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(p0.x, p0.y)
      ..lineTo(p1.x, p1.y)
      ..lineTo(p2.x, p2.y)
      ..close();
    canvas.drawPath(path, paint);

    final stroke = Paint()
      ..color = Color(tri.color).withAlpha(120)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, stroke);
  }

  void _drawGrid(Canvas canvas, double sw, double sh) {
    final cam = scene.camera;
    for (int i = -2; i <= 2; i++) {
      for (int j = -2; j <= 2; j++) {
        if (i == 0 && j == 0) continue;
        final isAxis = (i == 0 || j == 0);
        final p1 = cam.project(Vec3(i.toDouble(), 0, j.toDouble()), sw, sh);
        final p2 = cam.project(
          Vec3(i.toDouble(), 0, (j + 1).toDouble()),
          sw,
          sh,
        );
        final p3 = cam.project(
          Vec3((i + 1).toDouble(), 0, j.toDouble()),
          sw,
          sh,
        );

        final paint = Paint()
          ..color = Colors.white.withAlpha(isAxis ? 40 : 18)
          ..strokeWidth = isAxis ? 2.0 : 1.0
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
        canvas.drawLine(Offset(p1.x, p1.y), Offset(p3.x, p3.y), paint);
      }
    }
  }

  void _draw3DAxes(Canvas canvas, double sw, double sh) {
    final cam = scene.camera;
    final o = cam.project(Vec3(0, 0, 0), sw, sh);
    const len = 0.5;
    for (final (end, color) in [
      (Vec3(len, 0, 0), Colors.red),
      (Vec3(0, len, 0), Colors.green),
      (Vec3(0, 0, len), Colors.blue),
    ]) {
      final p = cam.project(end, sw, sh);
      canvas.drawLine(
        Offset(o.x, o.y),
        Offset(p.x, p.y),
        Paint()
          ..color = color
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawSensors(Canvas canvas, double sw, double sh) {
    final cam = scene.camera;
    for (final entry in SensorToBodyMapper.boneMap.entries) {
      final slot = entry.key;
      if (scene.activeSensors.isNotEmpty && !scene.activeSensors.contains(slot)) {
        continue;
      }

      final bone = scene.humanoid.skeleton[entry.value];
      if (bone == null) continue;

      final pos = bone.worldEnd;
      final screen = cam.project(pos, sw, sh);
      if (screen.z <= 0) continue;

      final color = Color(SensorToBodyMapper.color(slot));
      canvas.drawCircle(
        Offset(screen.x, screen.y),
        8,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(screen.x, screen.y),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      if (scene.showNames) {
        final name = SensorToBodyMapper.sensorLabel(slot);
        final tp = TextPainter(
          text: TextSpan(
            text: name,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(screen.x - tp.width / 2, screen.y + 10));
      }
    }
  }

  void _drawOverlayAxes(Canvas canvas, double sw, double sh) {
    final cam = scene.camera;
    final ox = 40.0, oy = sh - 80.0;
    final base2D = Offset(ox, oy);

    final pX = cam.project(cam.target + const Vec3(0.2, 0, 0), sw, sh);
    final pY = cam.project(cam.target + const Vec3(0, 0.2, 0), sw, sh);
    final pZ = cam.project(cam.target + const Vec3(0, 0, 0.2), sw, sh);
    final pCenter = cam.project(cam.target, sw, sh);

    Offset getAxisOffset(Vec3 p) {
      return Offset(p.x - pCenter.x, p.y - pCenter.y);
    }

    final dirX = base2D + getAxisOffset(pX);
    final dirY = base2D + getAxisOffset(pY);
    final dirZ = base2D + getAxisOffset(pZ);

    canvas.drawLine(base2D, dirX, Paint()..color = Colors.red..strokeWidth = 2.5);
    canvas.drawLine(base2D, dirY, Paint()..color = Colors.green..strokeWidth = 2.5);
    canvas.drawLine(base2D, dirZ, Paint()..color = Colors.blue..strokeWidth = 2.5);

    _label(canvas, 'X', dirX + const Offset(4, -4), Colors.red);
    _label(canvas, 'Y', dirY + const Offset(-4, -12), Colors.green);
    _label(canvas, 'Z', dirZ + const Offset(-10, -4), Colors.blue);
  }

  void _label(Canvas c, String t, Offset p, Color clr) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(color: clr, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(c, p);
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) => true;
}
