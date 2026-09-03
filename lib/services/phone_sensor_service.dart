import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/phone_sensor_data.dart';

/// Service that reads from the smartphone's built-in sensors.
///
/// Call [start] with a [PhoneSensorSettings] to begin streaming data.
/// Call [stop] to cancel all subscriptions.
/// Listen to [dataStream] for merged snapshots.
class PhoneSensorService {
  final _controller = StreamController<PhoneSensorData>.broadcast();
  Stream<PhoneSensorData> get dataStream => _controller.stream;

  // Internal subscriptions
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<MagnetometerEvent>? _magSub;
  StreamSubscription<BarometerEvent>? _baroSub;
  StreamSubscription<Position>? _gpsSub;

  // Latest values (merged into a single snapshot on every update)
  double? _accelX, _accelY, _accelZ;
  double? _gyroX, _gyroY, _gyroZ;
  double? _magX, _magY, _magZ;
  double? _latitude,
      _longitude,
      _altitude,
      _gpsSpeed,
      _gpsAccuracy,
      _gpsBearing;
  double? _baroPressure;

  bool _running = false;
  bool get isRunning => _running;

  /// Start collecting from the sensors selected in [settings].
  Future<void> start(PhoneSensorSettings settings) async {
    if (_running) await stop();
    _running = true;

    if (settings.accelerometerEnabled) {
      _accelSub = accelerometerEventStream().listen(
        (e) {
          _accelX = e.x;
          _accelY = e.y;
          _accelZ = e.z;
          _emit();
        },
        onError: (e) => debugPrint('Accelerometer error: $e'),
        cancelOnError: false,
      );
    }

    if (settings.gyroscopeEnabled) {
      _gyroSub = gyroscopeEventStream().listen(
        (e) {
          _gyroX = e.x;
          _gyroY = e.y;
          _gyroZ = e.z;
          _emit();
        },
        onError: (e) => debugPrint('Gyroscope error: $e'),
        cancelOnError: false,
      );
    }

    if (settings.magnetometerEnabled) {
      _magSub = magnetometerEventStream().listen(
        (e) {
          _magX = e.x;
          _magY = e.y;
          _magZ = e.z;
          _emit();
        },
        onError: (e) => debugPrint('Magnetometer error: $e'),
        cancelOnError: false,
      );
    }

    if (settings.barometerEnabled) {
      _baroSub = barometerEventStream().listen(
        (e) {
          _baroPressure = e.pressure;
          _emit();
        },
        onError: (e) => debugPrint('Barometer error: $e'),
        cancelOnError: false,
      );
    }

    if (settings.gpsEnabled) {
      final hasPermission = await _checkGpsPermission();
      if (hasPermission) {
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
        _gpsSub =
            Geolocator.getPositionStream(
              locationSettings: locationSettings,
            ).listen(
              (pos) {
                _latitude = pos.latitude;
                _longitude = pos.longitude;
                _altitude = pos.altitude;
                _gpsSpeed = pos.speed;
                _gpsAccuracy = pos.accuracy;
                _gpsBearing = pos.heading;
                _emit();
              },
              onError: (e) => debugPrint('GPS error: $e'),
              cancelOnError: false,
            );
      }
    }
  }

  /// Stop all sensor subscriptions and reset internal state.
  Future<void> stop() async {
    await _accelSub?.cancel();
    await _gyroSub?.cancel();
    await _magSub?.cancel();
    await _baroSub?.cancel();
    await _gpsSub?.cancel();

    _accelSub = null;
    _gyroSub = null;
    _magSub = null;
    _baroSub = null;
    _gpsSub = null;

    _accelX = _accelY = _accelZ = null;
    _gyroX = _gyroY = _gyroZ = null;
    _magX = _magY = _magZ = null;
    _latitude = _longitude = _altitude = null;
    _gpsSpeed = _gpsAccuracy = _gpsBearing = null;
    _baroPressure = null;

    _running = false;
  }

  /// Get the latest one-shot GPS position (useful for manual requests).
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await _checkGpsPermission();
    if (!hasPermission) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(
        PhoneSensorData(
          accelX: _accelX,
          accelY: _accelY,
          accelZ: _accelZ,
          gyroX: _gyroX,
          gyroY: _gyroY,
          gyroZ: _gyroZ,
          magX: _magX,
          magY: _magY,
          magZ: _magZ,
          latitude: _latitude,
          longitude: _longitude,
          altitude: _altitude,
          gpsSpeed: _gpsSpeed,
          gpsAccuracy: _gpsAccuracy,
          gpsBearing: _gpsBearing,
          barometricPressure: _baroPressure,
        ),
      );
    }
  }

  Future<bool> _checkGpsPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission permanently denied');
      return false;
    }

    return true;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
