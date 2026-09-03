import 'dart:math' as math;

class Quat {
  final double x, y, z, w;

  const Quat(this.x, this.y, this.z, this.w);
  factory Quat.identity() => const Quat(0, 0, 0, 1);

  factory Quat.fromEuler(double roll, double pitch, double yaw) {
    final cr = math.cos(roll * 0.5), sr = math.sin(roll * 0.5);
    final cp = math.cos(pitch * 0.5), sp = math.sin(pitch * 0.5);
    final cy = math.cos(yaw * 0.5), sy = math.sin(yaw * 0.5);
    return Quat(
      sr * cp * cy - cr * sp * sy,
      cr * sp * cy + sr * cp * sy,
      cr * cp * sy - sr * sp * cy,
      cr * cp * cy + sr * sp * sy,
    );
  }

  factory Quat.fromAxisAngle(double ax, double ay, double az, double angle) {
    final half = angle * 0.5;
    final s = math.sin(half);
    return Quat(ax * s, ay * s, az * s, math.cos(half));
  }

  Quat multiply(Quat o) => Quat(
    w * o.x + x * o.w + y * o.z - z * o.y,
    w * o.y - x * o.z + y * o.w + z * o.x,
    w * o.z + x * o.y - y * o.x + z * o.w,
    w * o.w - x * o.x - y * o.y - z * o.z,
  );

  Quat conjugate() => Quat(-x, -y, -z, w);
  Quat inverse() { final m = w*w+x*x+y*y+z*z; return Quat(-x/m, -y/m, -z/m, w/m); }

  Quat normalize() {
    final m = math.sqrt(w*w + x*x + y*y + z*z);
    if (m < 1e-10) return Quat.identity();
    return Quat(x/m, y/m, z/m, w/m);
  }

  double get roll {
    final sinr = 2*(w*x + y*z), cosr = 1 - 2*(x*x + y*y);
    return math.atan2(sinr, cosr);
  }
  double get pitch {
    final sinp = 2*(w*y - z*x);
    if (sinp.abs() >= 1) return (math.pi/2) * sinp.sign;
    return math.asin(sinp);
  }
  double get yaw {
    final siny = 2*(w*z + x*y), cosy = 1 - 2*(y*y + z*z);
    return math.atan2(siny, cosy);
  }

  List<double> get rotationMatrix {
    final x2=x*x, y2=y*y, z2=z*z;
    final xy=x*y, xz=x*z, yz=y*z;
    final wx=w*x, wy=w*y, wz=w*z;
    return [
      1-2*(y2+z2), 2*(xy-wz), 2*(xz+wy), 0,
      2*(xy+wz), 1-2*(x2+z2), 2*(yz-wx), 0,
      2*(xz-wy), 2*(yz+wx), 1-2*(x2+y2), 0,
      0, 0, 0, 1,
    ];
  }

  List<double> get transposeRotationMatrix {
    final x2=x*x, y2=y*y, z2=z*z;
    final xy=x*y, xz=x*z, yz=y*z;
    final wx=w*x, wy=w*y, wz=w*z;
    return [
      1-2*(y2+z2), 2*(xy+wz), 2*(xz-wy), 0,
      2*(xy-wz), 1-2*(x2+z2), 2*(yz+wx), 0,
      2*(xz+wy), 2*(yz-wx), 1-2*(x2+y2), 0,
      0, 0, 0, 1,
    ];
  }

  Vec3 apply(Vec3 v) {
    final tx = 2*(y*v.z - z*v.y);
    final ty = 2*(z*v.x - x*v.z);
    final tz = 2*(x*v.y - y*v.x);
    return Vec3(
      v.x + w*tx + y*tz - z*ty,
      v.y + w*ty + z*tx - x*tz,
      v.z + w*tz + x*ty - y*tx,
    );
  }

  Quat sensorToWorld() => Quat(-x, -z, -y, w).normalize();
  Quat worldToSensor() => Quat(-x, -z, -y, w).normalize();
  Quat applyMountingOffset(Quat offset) =>
    offset.multiply(this).multiply(offset.conjugate());

  static Quat slerp(Quat a, Quat b, double t) {
    var dot = a.w*b.w + a.x*b.x + a.y*b.y + a.z*b.z;
    if (dot < 0) { b = Quat(-b.x, -b.y, -b.z, -b.w); dot = -dot; }
    if ((1-dot).abs() < 1e-6) return a;
    final theta = math.acos(dot.clamp(-1, 1));
    final sinT = math.sin(theta);
    final ra = math.sin((1-t)*theta)/sinT;
    final rb = math.sin(t*theta)/sinT;
    return Quat(a.x*ra+b.x*rb, a.y*ra+b.y*rb, a.z*ra+b.z*rb, a.w*ra+b.w*rb).normalize();
  }
}

class Vec3 {
  final double x, y, z;
  const Vec3(this.x, this.y, this.z);
  factory Vec3.zero() => const Vec3(0, 0, 0);

  Vec3 operator +(Vec3 o) => Vec3(x+o.x, y+o.y, z+o.z);
  Vec3 operator -(Vec3 o) => Vec3(x-o.x, y-o.y, z-o.z);
  Vec3 operator *(double s) => Vec3(x*s, y*s, z*s);
  Vec3 operator /(double s) => Vec3(x/s, y/s, z/s);
  Vec3 negate() => Vec3(-x, -y, -z);
  double dot(Vec3 o) => x*o.x + y*o.y + z*o.z;
  Vec3 cross(Vec3 o) => Vec3(y*o.z-z*o.y, z*o.x-x*o.z, x*o.y-y*o.x);
  double get length => math.sqrt(x*x + y*y + z*z);
  Vec3 normalize() { final l = length; return l > 1e-10 ? Vec3(x/l, y/l, z/l) : Vec3.zero(); }
  Vec3 lerp(Vec3 o, double t) => Vec3(x+(o.x-x)*t, y+(o.y-y)*t, z+(o.z-z)*t);
}

class Mat4 {
  final List<double> d;
  Mat4(this.d);
  factory Mat4.identity() => Mat4([
    1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1
  ]);
  factory Mat4.fromRows(List<double> data) => Mat4(List.from(data));

  static Mat4 perspective(double fovY, double aspect, double near, double far) {
    final f = 1.0 / math.tan(fovY * 0.5);
    final nf = 1.0 / (near - far);
    return Mat4([
      f/aspect, 0, 0, 0,
      0, f, 0, 0,
      0, 0, (far+near)*nf, -1,
      0, 0, 2*far*near*nf, 0,
    ]);
  }

  static Mat4 lookAt(Vec3 eye, Vec3 target, Vec3 up) {
    final f = (target - eye).normalize();
    final s = f.cross(up).normalize();
    final u = s.cross(f);
    return Mat4([
      s.x, u.x, -f.x, 0,
      s.y, u.y, -f.y, 0,
      s.z, u.z, -f.z, 0,
      -s.dot(eye), -u.dot(eye), f.dot(eye), 1,
    ]);
  }

  static Mat4 translation(double x, double y, double z) => Mat4([
    1,0,0,0, 0,1,0,0, 0,0,1,0, x,y,z,1,
  ]);

  static Mat4 fromQuaternion(Quat q) => Mat4(q.rotationMatrix);

  Mat4 multiply(Mat4 o) {
    final a = d, b = o.d;
    return Mat4([
      a[0]*b[0]+a[4]*b[1]+a[8]*b[2]+a[12]*b[3],
      a[1]*b[0]+a[5]*b[1]+a[9]*b[2]+a[13]*b[3],
      a[2]*b[0]+a[6]*b[1]+a[10]*b[2]+a[14]*b[3],
      a[3]*b[0]+a[7]*b[1]+a[11]*b[2]+a[15]*b[3],
      a[0]*b[4]+a[4]*b[5]+a[8]*b[6]+a[12]*b[7],
      a[1]*b[4]+a[5]*b[5]+a[9]*b[6]+a[13]*b[7],
      a[2]*b[4]+a[6]*b[5]+a[10]*b[6]+a[14]*b[7],
      a[3]*b[4]+a[7]*b[5]+a[11]*b[6]+a[15]*b[7],
      a[0]*b[8]+a[4]*b[9]+a[8]*b[10]+a[12]*b[11],
      a[1]*b[8]+a[5]*b[9]+a[9]*b[10]+a[13]*b[11],
      a[2]*b[8]+a[6]*b[9]+a[10]*b[10]+a[14]*b[11],
      a[3]*b[8]+a[7]*b[9]+a[11]*b[10]+a[15]*b[11],
      a[0]*b[12]+a[4]*b[13]+a[8]*b[14]+a[12]*b[15],
      a[1]*b[12]+a[5]*b[13]+a[9]*b[14]+a[13]*b[15],
      a[2]*b[12]+a[6]*b[13]+a[10]*b[14]+a[14]*b[15],
      a[3]*b[12]+a[7]*b[13]+a[11]*b[14]+a[15]*b[15],
    ]);
  }

  Vec3 transform(Vec3 v) {
    final x=v.x, y=v.y, z=v.z;
    return Vec3(
      d[0]*x + d[4]*y + d[8]*z + d[12],
      d[1]*x + d[5]*y + d[9]*z + d[13],
      d[2]*x + d[6]*y + d[10]*z + d[14],
    );
  }

  Vec3 transformPoint(Vec3 v) {
    final x=v.x, y=v.y, z=v.z;
    final w = d[3]*x + d[7]*y + d[11]*z + d[15];
    return Vec3(
      (d[0]*x + d[4]*y + d[8]*z + d[12])/w,
      (d[1]*x + d[5]*y + d[9]*z + d[13])/w,
      (d[2]*x + d[6]*y + d[10]*z + d[14])/w,
    );
  }
}

class SensorToBodyMapper {
  static const Map<int, String> boneMap = {
    1: 'left_thigh', 2: 'right_thigh',
    3: 'left_calf', 4: 'right_calf',
    5: 'right_foot',
  };
  static const Map<int, List<double>> mountOffsets = {
    1: [0, 0, 90], 2: [0, 0, -90],
    3: [0, 0, 90], 4: [0, 0, -90],
    5: [0, 0, -90],
  };
  static const Map<int, int> colors = {
    1: 0xFF2196F3, 2: 0xFF4CAF50, 3: 0xFFF44336,
    4: 0xFFFF9800, 5: 0xFF9C27B0,
  };
  static String? bone(int s) => boneMap[s];
  static Quat offset(int s) {
    final o = mountOffsets[s]; if (o == null) return Quat.identity();
    return Quat.fromEuler(o[0]*math.pi/180, o[1]*math.pi/180, o[2]*math.pi/180);
  }
  static int color(int s) => colors[s] ?? 0xFF9E9E9E;
  static String sensorLabel(int s) => {
    1: 'Coxa Esq', 2: 'Coxa Dir', 3: 'Canela Esq',
    4: 'Canela Dir', 5: 'Pé Dir',
  }[s] ?? 'Sensor $s';
}