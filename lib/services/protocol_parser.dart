import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';

/// Parser for WT9011DCL-BT50 Communication Protocol
///
/// Supports two packet formats emitted by the sensor:
///
/// 1) Combined 20-byte packet (type 0x61):
///    55 61 [accel X Y Z] [gyro X Y Z] [angle X Y Z]  – 3×2 bytes each, no checksum
///
/// 2) Individual 11-byte packets (default factory output):
///    55 51 [ax ay az T] CS  – acceleration
///    55 52 [wx wy wz T] CS  – angular velocity
///    55 53 [rx ry rz T] CS  – Euler angles (roll/pitch/yaw)
///    Each value is 2 bytes little-endian; CS = (sum of bytes 0-9) & 0xFF
///
/// Conversion factors (WT9011DCL defaults):
///   Acceleration : ±16 g   → ×(16/32768)
///   Angular vel  : ±2000°/s → ×(2000/32768)
///   Angle        : ±180°    → ×(180/32768)
class ProtocolParser {
  static const int _header = 0x55;

  // Packet types
  static const int _typeCombined = 0x61;
  static const int _typeAccel = 0x51;
  static const int _typeGyro = 0x52;
  static const int _typeAngle = 0x53;

  // Packet sizes
  static const int _packetSizeCombined = 20;
  static const int _packetSize11 = 11;

  // All known 11-byte types (skip them cleanly even if we don't parse them)
  static const Set<int> _knownTypes11 = {
    0x51, 0x52, 0x53, // accel / gyro / angle
    0x54,             // magnetic field
    0x57, 0x58, 0x59, // barometer / GPS / quaternion (some firmware variants)
  };

  // Conversion factors
  static const double _accelScale = 16.0 / 32768.0;
  static const double _gyroScale = 2000.0 / 32768.0;
  static const double _angleScale = 180.0 / 32768.0;

  final List<int> _buffer = [];

  // Partial accumulation for 11-byte packet mode (0x51 → 0x52 → 0x53 sequence)
  double _partialAccelX = 0, _partialAccelY = 0, _partialAccelZ = 0;
  double _partialGyroX = 0, _partialGyroY = 0, _partialGyroZ = 0;
  bool _hasAccel = false, _hasGyro = false;

  /// Parse incoming bytes and return list of complete SensorData packets
  List<SensorData> parse(Uint8List data) {
    final List<SensorData> results = [];

    _buffer.addAll(data);

    while (_buffer.length >= 2) {
      // Locate the next header byte
      final headerIndex = _buffer.indexOf(_header);
      if (headerIndex == -1) {
        if (_buffer.length > 1) _buffer.removeRange(0, _buffer.length - 1);
        break;
      }
      if (headerIndex > 0) _buffer.removeRange(0, headerIndex);
      if (_buffer.length < 2) break;

      final type = _buffer[1];

      if (type == _typeCombined) {
        // ── 20-byte combined packet ──────────────────────────────────────────
        if (_buffer.length < _packetSizeCombined) break;
        final packet =
            Uint8List.fromList(_buffer.sublist(0, _packetSizeCombined));
        final sd = _parseCombinedPacket(packet);
        if (sd != null) results.add(sd);
        _buffer.removeRange(0, _packetSizeCombined);
      } else if (_knownTypes11.contains(type)) {
        // ── 11-byte individual packet ────────────────────────────────────────
        if (_buffer.length < _packetSize11) break;
        final packet = Uint8List.fromList(_buffer.sublist(0, _packetSize11));
        final sd = _parse11BytePacket(packet);
        if (sd != null) results.add(sd);
        _buffer.removeRange(0, _packetSize11);
      } else {
        // Unknown type – remove only the header byte and retry
        _buffer.removeAt(0);
      }
    }

    if (_buffer.length > 200) _buffer.clear();
    return results;
  }

  // ── 20-byte combined packet (0x61) ────────────────────────────────────────

  SensorData? _parseCombinedPacket(Uint8List packet) {
    if (packet.length != _packetSizeCombined) return null;
    if (packet[0] != _header || packet[1] != _typeCombined) return null;

    try {
      final ax = _readInt16LE(packet, 2) * _accelScale;
      final ay = _readInt16LE(packet, 4) * _accelScale;
      final az = _readInt16LE(packet, 6) * _accelScale;

      final wx = _readInt16LE(packet, 8) * _gyroScale;
      final wy = _readInt16LE(packet, 10) * _gyroScale;
      final wz = _readInt16LE(packet, 12) * _gyroScale;

      final roll = _readInt16LE(packet, 14) * _angleScale;
      final pitch = _readInt16LE(packet, 16) * _angleScale;
      final yaw = _readInt16LE(packet, 18) * _angleScale;

      final q = _eulerToQuaternion(roll, pitch, yaw);
      return SensorData(
        accelerationX: ax, accelerationY: ay, accelerationZ: az,
        angularVelocityX: wx, angularVelocityY: wy, angularVelocityZ: wz,
        roll: roll, pitch: pitch, yaw: yaw,
        quaternionW: q[0], quaternionX: q[1], quaternionY: q[2], quaternionZ: q[3],
      );
    } catch (e) {
      debugPrint('Error parsing combined packet: $e');
      return null;
    }
  }

  // ── 11-byte individual packets (0x51 / 0x52 / 0x53) ─────────────────────

  /// Accumulates 0x51 and 0x52 packets; emits SensorData on 0x53 (angle).
  SensorData? _parse11BytePacket(Uint8List packet) {
    if (packet.length != _packetSize11) return null;
    if (packet[0] != _header) return null;

    // Validate checksum: (sum of bytes 0–9) & 0xFF must equal byte 10
    int sum = 0;
    for (int i = 0; i < 10; i++) sum += packet[i];
    if ((sum & 0xFF) != packet[10]) return null;

    final type = packet[1];
    final v1 = _readInt16LE(packet, 2);
    final v2 = _readInt16LE(packet, 4);
    final v3 = _readInt16LE(packet, 6);

    switch (type) {
      case _typeAccel: // 0x51
        _partialAccelX = v1 * _accelScale;
        _partialAccelY = v2 * _accelScale;
        _partialAccelZ = v3 * _accelScale;
        _hasAccel = true;
        return null;

      case _typeGyro: // 0x52
        _partialGyroX = v1 * _gyroScale;
        _partialGyroY = v2 * _gyroScale;
        _partialGyroZ = v3 * _gyroScale;
        _hasGyro = true;
        return null;

      case _typeAngle: // 0x53 – emit combined result
        final roll = v1 * _angleScale;
        final pitch = v2 * _angleScale;
        final yaw = v3 * _angleScale;
        final q = _eulerToQuaternion(roll, pitch, yaw);
        final sd = SensorData(
          accelerationX: _hasAccel ? _partialAccelX : 0,
          accelerationY: _hasAccel ? _partialAccelY : 0,
          accelerationZ: _hasAccel ? _partialAccelZ : 0,
          angularVelocityX: _hasGyro ? _partialGyroX : 0,
          angularVelocityY: _hasGyro ? _partialGyroY : 0,
          angularVelocityZ: _hasGyro ? _partialGyroZ : 0,
          roll: roll, pitch: pitch, yaw: yaw,
          quaternionW: q[0], quaternionX: q[1], quaternionY: q[2], quaternionZ: q[3],
        );
        _hasAccel = false;
        _hasGyro = false;
        return sd;

      default:
        return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _readInt16LE(Uint8List data, int offset) {
    final value = (data[offset + 1] << 8) | data[offset];
    return (value & 0x8000) != 0 ? (value - 0x10000).toDouble() : value.toDouble();
  }

  List<double> _eulerToQuaternion(double roll, double pitch, double yaw) {
    final r = roll * math.pi / 180.0;
    final p = pitch * math.pi / 180.0;
    final y = yaw * math.pi / 180.0;

    final cy = math.cos(y * 0.5), sy = math.sin(y * 0.5);
    final cp = math.cos(p * 0.5), sp = math.sin(p * 0.5);
    final cr = math.cos(r * 0.5), sr = math.sin(r * 0.5);

    return [
      cr * cp * cy + sr * sp * sy,
      sr * cp * cy - cr * sp * sy,
      cr * sp * cy + sr * cp * sy,
      cr * cp * sy - sr * sp * cy,
    ];
  }

  void clear() {
    _buffer.clear();
    _hasAccel = false;
    _hasGyro = false;
  }
}

