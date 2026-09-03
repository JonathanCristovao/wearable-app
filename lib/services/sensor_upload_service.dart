import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/activity_metadata.dart';
import '../models/phone_sensor_data.dart';
import '../utils/gzip_utils.dart';
import '../utils/json_utils.dart';
import 'storage_service.dart';

/// Buffers [PhoneSensorData] events, compresses them in batches,
/// and uploads GZIP-compressed JSONL files to Firebase Storage.
///
/// Usage:
/// ```dart
/// final svc = SensorUploadService();
/// svc.startSession(activity: 'walking');
/// // … feed data …
/// svc.addData(phoneSensorSnapshot);
/// // … on session end …
/// await svc.endSession();
/// ```
class SensorUploadService {
  static final SensorUploadService _instance = SensorUploadService._internal();
  factory SensorUploadService() => _instance;
  SensorUploadService._internal();

  final StorageService _storage = StorageService();

  // Buffer for in-flight sensor snapshots.
  final List<PhoneSensorData> _buffer = [];
  Timer? _flushTimer;
  bool _isUploading = false;

  // Session state
  String? _currentActivity;
  String? _currentSessionId;
  DateTime? _sessionStart;
  int _samplingRate = _kDefaultSamplingRate;

  static const Duration _flushInterval = Duration(seconds: 10);
  static const int _kDefaultSamplingRate = 20;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Begins a new recording session for [activity] (e.g. 'walking').
  void startSession({
    required String activity,
    int samplingRate = _kDefaultSamplingRate,
  }) {
    _currentActivity = activity;
    _sessionStart = DateTime.now();
    _samplingRate = samplingRate;
    _currentSessionId = _sessionTimestamp(_sessionStart!);
    _buffer.clear();
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushBuffer());
  }

  /// Adds a sensor snapshot to the internal buffer.
  ///
  /// No-op when no session is active.
  void addData(PhoneSensorData data) {
    if (_currentActivity == null) return;
    _buffer.add(data);
  }

  /// Flushes any remaining data, uploads a metadata file, then resets state.
  ///
  /// [device] is embedded in the metadata (default: 'Android').
  Future<void> endSession({String device = 'Android'}) async {
    _flushTimer?.cancel();
    _flushTimer = null;

    if (_buffer.isNotEmpty) await _flushBuffer();
    if (_currentSessionId != null && _sessionStart != null) {
      await _uploadMetadata(device: device);
    }

    _currentActivity = null;
    _currentSessionId = null;
    _sessionStart = null;
    _buffer.clear();
  }

  bool get isSessionActive => _currentActivity != null;

  // -------------------------------------------------------------------------
  // Internals – flush & compress
  // -------------------------------------------------------------------------

  Future<void> _flushBuffer() async {
    if (_buffer.isEmpty || _isUploading) return;
    if (_currentActivity == null || _currentSessionId == null) return;

    _isUploading = true;
    final snapshot = List<PhoneSensorData>.from(_buffer);
    _buffer.clear();

    try {
      await _uploadSensorFiles(snapshot);
    } catch (e) {
      debugPrint('[SensorUploadService] Flush error: $e');
      // Re-insert data so it will be retried on the next flush cycle.
      _buffer.insertAll(0, snapshot);
    } finally {
      _isUploading = false;
    }
  }

  Future<void> _uploadSensorFiles(List<PhoneSensorData> data) async {
    final basePath = 'activities/$_currentActivity/$_currentSessionId';

    await Future.wait([
      _compressAndUpload(
        basePath: basePath,
        fileName: 'accelerometer.json.gz',
        records: data
            .where((d) => d.accelX != null)
            .map(
              (d) => <String, dynamic>{
                'ts': d.timestamp.toIso8601String(),
                'x': d.accelX,
                'y': d.accelY,
                'z': d.accelZ,
              },
            )
            .toList(),
      ),
      _compressAndUpload(
        basePath: basePath,
        fileName: 'gyroscope.json.gz',
        records: data
            .where((d) => d.gyroX != null)
            .map(
              (d) => <String, dynamic>{
                'ts': d.timestamp.toIso8601String(),
                'x': d.gyroX,
                'y': d.gyroY,
                'z': d.gyroZ,
              },
            )
            .toList(),
      ),
      _compressAndUpload(
        basePath: basePath,
        fileName: 'magnetometer.json.gz',
        records: data
            .where((d) => d.magX != null)
            .map(
              (d) => <String, dynamic>{
                'ts': d.timestamp.toIso8601String(),
                'x': d.magX,
                'y': d.magY,
                'z': d.magZ,
              },
            )
            .toList(),
      ),
      _compressAndUpload(
        basePath: basePath,
        fileName: 'gps.json.gz',
        records: data
            .where((d) => d.latitude != null)
            .map(
              (d) => <String, dynamic>{
                'ts': d.timestamp.toIso8601String(),
                'lat': d.latitude,
                'lng': d.longitude,
                'alt': d.altitude,
                'speed': d.gpsSpeed,
                'accuracy': d.gpsAccuracy,
                'bearing': d.gpsBearing,
              },
            )
            .toList(),
      ),
    ]);
  }

  Future<void> _compressAndUpload({
    required String basePath,
    required String fileName,
    required List<Map<String, dynamic>> records,
  }) async {
    if (records.isEmpty) return;

    final jsonlBytes = JsonUtils.toJsonLBytes(records);
    final compressed = GzipUtils.compress(jsonlBytes);

    await _storage.uploadBytes(
      relativePath: '$basePath/$fileName',
      data: compressed,
      contentType: 'application/gzip',
      customMetadata: {'record_count': '${records.length}'},
    );
  }

  Future<void> _uploadMetadata({required String device}) async {
    final durationSeconds = DateTime.now().difference(_sessionStart!).inSeconds;

    final metadata = ActivityMetadata(
      sessionId: _currentSessionId!,
      activity: _currentActivity!,
      createdAt: _sessionStart!,
      durationSeconds: durationSeconds,
      samplingRate: _samplingRate,
      device: device,
      sensors: const ['accelerometer', 'gyroscope', 'magnetometer', 'gps'],
    );

    final jsonBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(metadata.toJson())),
    );

    await _storage.uploadBytes(
      relativePath:
          'activities/$_currentActivity/$_currentSessionId/metadata.json',
      data: jsonBytes,
      contentType: 'application/json',
    );
  }

  /// Formats a [DateTime] as the folder-friendly session timestamp.
  /// Example: 2026-05-16_10-30-22
  String _sessionTimestamp(DateTime dt) {
    String p(int v, [int w = 2]) => v.toString().padLeft(w, '0');
    return '${p(dt.year, 4)}-${p(dt.month)}-${p(dt.day)}'
        '_${p(dt.hour)}-${p(dt.minute)}-${p(dt.second)}';
  }
}
