import 'dart:math' as math;
import 'quaternion.dart';
import 'skeleton.dart';
import 'camera.dart';

class RenderTri {
  final Vec3 p0, p1, p2;
  final double d0, d1, d2;
  final int color;
  final double alpha;
  RenderTri(this.p0, this.p1, this.p2, this.d0, this.d1, this.d2, this.color, this.alpha);
  double get avgDepth => (d0 + d1 + d2) / 3;
}

class RenderLine {
  final Vec3 start, end;
  final double depth;
  final int color;
  final double thickness;
  RenderLine(this.start, this.end, this.depth, this.color, this.thickness);
}

class HumanoidModel {
  final Skeleton skeleton;
  final List<RenderTri> triangles = [];
  final List<RenderLine> lines = [];

  HumanoidModel() : skeleton = Skeleton();

  void updateSkeleton() => skeleton.updateWorld();

  void render(Camera3D cam, double sw, double sh) {
    triangles.clear();
    lines.clear();

    for (final bone in skeleton.allBones) {
      if (bone.length < 0.01) continue;
      final start = bone.worldPos;
      final end = bone.worldEnd;
      _addCylinderMesh(start, end, bone.thickness, 0xFFDDDDDD, cam, sw, sh);
      _addBoneLine(start, end, 0xFFFFFFFF, cam, sw, sh);
    }
    _addJointSpheres(cam, sw, sh);
    _addHeadSphere(cam, sw, sh);
  }

  void _addBoneLine(Vec3 start, Vec3 end, int color, Camera3D cam, double sw, double sh) {
    final mid = Vec3((start.x+end.x)/2, (start.y+end.y)/2, (start.z+end.z)/2);
    final d = cam.project(mid, sw, sh).z;
    lines.add(RenderLine(start, end, d, color, 3.0));
  }

  void _addJointSpheres(Camera3D cam, double sw, double sh) {
    for (final bone in skeleton.allBones) {
      if (bone.parentName.isEmpty) continue;
      if (bone.name == 'neck' || bone.name == 'spine' || bone.name == 'chest') continue;
      final pos = bone.worldPos;
      final r = bone.thickness * 1.3;
      _addSphereMesh(pos, r, 0xFFBBBBBB, 6, cam, sw, sh);
    }
  }

  void _addHeadSphere(Camera3D cam, double sw, double sh) {
    final head = skeleton['head']?.worldEnd ?? Vec3(0, 1.7, 0);
    _addSphereMesh(head, 0.09, 0xFFEEEEEE, 8, cam, sw, sh);
  }

  void _addCylinderMesh(Vec3 start, Vec3 end, double rad, int color, Camera3D cam, double sw, double sh) {
    final d = (end - start);
    final len = d.length;
    if (len < 0.001 || rad < 0.001) return;

    final dir = d.normalize();
    final up = Vec3(0, 1, 0);
    final fwd = Vec3(0, 0, 1);

    Vec3 right;
    if ((dir.x * dir.x + dir.y * dir.y) < 0.01) {
      right = dir.cross(fwd).normalize();
    } else {
      right = dir.cross(up).normalize();
    }
    if (right.length < 0.1) right = Vec3(1, 0, 0);
    right = right.normalize();
    final fw = right.cross(dir).normalize();

    final n = 8;
    for (int i = 0; i < n; i++) {
      final a1 = (i / n) * 2 * math.pi;
      final a2 = ((i + 1) / n) * 2 * math.pi;
      final ca = math.cos(a1), sa = math.sin(a1);
      final cb = math.cos(a2), sb = math.sin(a2);

      final rxa = rad * ca, rya = rad * sa;
      final rxb = rad * cb, ryb = rad * sb;

      final p0 = Vec3(start.x + rxa*right.x + rya*fw.x, start.y + rxa*right.y + rya*fw.y, start.z + rxa*right.z + rya*fw.z);
      final p1 = Vec3(start.x + rxb*right.x + ryb*fw.x, start.y + rxb*right.y + ryb*fw.y, start.z + rxb*right.z + ryb*fw.z);
      final p2 = Vec3(end.x + rxa*right.x + rya*fw.x, end.y + rxa*right.y + rya*fw.y, end.z + rxa*right.z + rya*fw.z);
      final p3 = Vec3(end.x + rxb*right.x + ryb*fw.x, end.y + rxb*right.y + ryb*fw.y, end.z + rxb*right.z + ryb*fw.z);

      triangles.add(RenderTri(p0, p1, p2,
        cam.project(p0, sw, sh).z, cam.project(p1, sw, sh).z, cam.project(p2, sw, sh).z, color, 0.7));
      triangles.add(RenderTri(p1, p3, p2,
        cam.project(p1, sw, sh).z, cam.project(p3, sw, sh).z, cam.project(p2, sw, sh).z, color, 0.7));
    }
  }

  void _addSphereMesh(Vec3 center, double r, int color, int segs, Camera3D cam, double sw, double sh) {
    if (r < 0.001) return;
    for (int i = 0; i < segs; i++) {
      final t1 = (i / segs) * math.pi;
      final t2 = ((i + 1) / segs) * math.pi;
      for (int j = 0; j < segs * 2; j++) {
        final p1 = (j / (segs * 2)) * 2 * math.pi;
        final p2 = ((j + 1) / (segs * 2)) * 2 * math.pi;

        final arr = [
          Vec3(center.x + r*math.sin(t1)*math.cos(p1), center.y + r*math.cos(t1), center.z + r*math.sin(t1)*math.sin(p1)),
          Vec3(center.x + r*math.sin(t1)*math.cos(p2), center.y + r*math.cos(t1), center.z + r*math.sin(t1)*math.sin(p2)),
          Vec3(center.x + r*math.sin(t2)*math.cos(p1), center.y + r*math.cos(t2), center.z + r*math.sin(t2)*math.sin(p1)),
          Vec3(center.x + r*math.sin(t2)*math.cos(p2), center.y + r*math.cos(t2), center.z + r*math.sin(t2)*math.sin(p2)),
        ];

        triangles.add(RenderTri(arr[0], arr[1], arr[2],
          cam.project(arr[0], sw, sh).z, cam.project(arr[1], sw, sh).z, cam.project(arr[2], sw, sh).z, color, 0.8));
        triangles.add(RenderTri(arr[1], arr[3], arr[2],
          cam.project(arr[1], sw, sh).z, cam.project(arr[3], sw, sh).z, cam.project(arr[2], sw, sh).z, color, 0.8));
      }
    }
  }
}