import 'dart:math' as math;
import 'quaternion.dart';

class Camera3D {
  Vec3 position;
  Vec3 target;
  double fov;
  double near, far;
  double aspect;
  double distance;
  double theta, phi;

  Camera3D({
    Vec3? position,
    Vec3? target,
    this.fov = 50,
    this.near = 0.1,
    this.far = 100,
    this.aspect = 1,
  }) : position = position ?? Vec3(0, 1.2, 3.0),
       target = target ?? Vec3(0, 0.9, 0),
       distance = 3.0,
       theta = 0,
       phi = 25 {
    _updateFromSpherical();
  }

  void _updateFromSpherical() {
    final radPhi = phi * math.pi / 180;
    final radTheta = theta * math.pi / 180;
    final x = distance * math.sin(radPhi) * math.sin(radTheta);
    final y = distance * math.cos(radPhi);
    final z = distance * math.sin(radPhi) * math.cos(radTheta);
    position = Vec3(target.x + x, target.y + y, target.z + z);
  }

  void orbit(double dx, double dy) {
    theta += dx;
    phi = (phi + dy).clamp(1, 89);
    _updateFromSpherical();
  }

  void zoom(double factor) {
    distance = (distance * factor).clamp(0.5, 10);
    _updateFromSpherical();
  }

  void pan(double dx, double dy) {
    final radPhi = phi * math.pi / 180;
    final radTheta = theta * math.pi / 180;
    final forward = Vec3(
      math.sin(radPhi) * math.sin(radTheta),
      math.cos(radPhi),
      math.sin(radPhi) * math.cos(radTheta),
    ).normalize();
    final right = forward.cross(Vec3(0, 1, 0)).normalize();
    final up = right.cross(forward);
    final panSpeed = distance * 0.003;
    target = Vec3(
      target.x + right.x * -dx * panSpeed + up.x * dy * panSpeed,
      target.y + right.y * -dx * panSpeed + up.y * dy * panSpeed,
      target.z + right.z * -dx * panSpeed + up.z * dy * panSpeed,
    );
    _updateFromSpherical();
  }

  Mat4 get viewMatrix => Mat4.lookAt(position, target, Vec3(0, 1, 0));
  Mat4 get projectionMatrix => Mat4.perspective(fov * math.pi / 180, aspect, near, far);
  Mat4 get viewProjection => projectionMatrix.multiply(viewMatrix);

  Vec3 project(Vec3 world, double screenW, double screenH) {
    final clip = viewProjection.transformPoint(world);
    return Vec3(
      (clip.x + 1) * 0.5 * screenW,
      (1 - clip.y) * 0.5 * screenH,
      clip.z,
    );
  }
}