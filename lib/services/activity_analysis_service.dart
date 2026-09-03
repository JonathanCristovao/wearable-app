import 'dart:math';
import '../models/activity_record.dart';

/// Service for analyzing activity data and providing statistics
class ActivityAnalysisService {
  /// Analyzes an activity record and returns comprehensive statistics
  static ActivityAnalysis analyzeActivity(ActivityRecord record) {
    if (record.dataPoints.isEmpty) {
      return ActivityAnalysis.empty(record);
    }

    final sensors = record.dataPoints.first.sensors.keys.toList();
    final sensorAnalyses = <String, SensorAnalysis>{};

    for (var sensorId in sensors) {
      sensorAnalyses[sensorId] = _analyzeSensor(sensorId, record.dataPoints);
    }

    // Check if phone sensors are present
    PhoneSensorAnalysis? phoneSensorAnalysis;
    final hasPhoneData = record.dataPoints.any((dp) => dp.phoneSensors != null);
    if (hasPhoneData) {
      phoneSensorAnalysis = _analyzePhoneSensors(record.dataPoints);
    }

    return ActivityAnalysis(
      record: record,
      sensorAnalyses: sensorAnalyses,
      phoneSensorAnalysis: phoneSensorAnalysis,
      overallMetrics: _calculateOverallMetrics(record, sensorAnalyses),
    );
  }

  /// Analyzes data for a specific sensor
  static SensorAnalysis _analyzeSensor(
    String sensorId,
    List<ActivityDataPoint> dataPoints,
  ) {
    final accelerations = <Vector3>[];
    final gyros = <Vector3>[];
    final orientations = <Vector3>[];

    for (var point in dataPoints) {
      final sensor = point.sensors[sensorId];
      if (sensor != null) {
        accelerations.add(Vector3(sensor.accelX, sensor.accelY, sensor.accelZ));
        gyros.add(Vector3(sensor.gyroX, sensor.gyroY, sensor.gyroZ));
        orientations.add(Vector3(sensor.roll, sensor.pitch, sensor.yaw));
      }
    }

    return SensorAnalysis(
      sensorId: sensorId,
      acceleration: _analyzeVector3List(accelerations, 'g'),
      gyroscope: _analyzeVector3List(gyros, '°/s'),
      orientation: _analyzeVector3List(orientations, '°'),
      movementIntensity: _calculateMovementIntensity(accelerations, gyros),
      peaks: _detectPeaks(accelerations),
      smoothness: _calculateSmoothness(accelerations),
    );
  }

  /// Analyzes a list of 3D vectors
  static Vector3Analysis _analyzeVector3List(
    List<Vector3> vectors,
    String unit,
  ) {
    if (vectors.isEmpty) {
      return Vector3Analysis.empty(unit);
    }

    return Vector3Analysis(
      x: _analyzeAxisData(vectors.map((v) => v.x).toList()),
      y: _analyzeAxisData(vectors.map((v) => v.y).toList()),
      z: _analyzeAxisData(vectors.map((v) => v.z).toList()),
      magnitude: _analyzeAxisData(vectors.map((v) => v.magnitude).toList()),
      unit: unit,
    );
  }

  /// Analyzes single-axis data
  static AxisStatistics _analyzeAxisData(List<double> data) {
    if (data.isEmpty) {
      return AxisStatistics.empty();
    }

    final sorted = List<double>.from(data)..sort();
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance =
        data.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / data.length;
    final stdDev = sqrt(variance);

    return AxisStatistics(
      min: sorted.first,
      max: sorted.last,
      mean: mean,
      median: sorted[sorted.length ~/ 2],
      stdDev: stdDev,
      range: sorted.last - sorted.first,
    );
  }

  /// Calculates movement intensity based on acceleration and gyroscope magnitude
  static double _calculateMovementIntensity(
    List<Vector3> accelerations,
    List<Vector3> gyros,
  ) {
    if (accelerations.isEmpty || gyros.isEmpty) return 0.0;

    final accelIntensity =
        accelerations.map((v) => v.magnitude).reduce((a, b) => a + b) /
        accelerations.length;
    final gyroIntensity =
        gyros.map((v) => v.magnitude).reduce((a, b) => a + b) / gyros.length;

    // Normalize and combine (weighted average)
    return (accelIntensity * 0.6 + gyroIntensity * 0.4);
  }

  /// Detects peaks in acceleration data
  static int _detectPeaks(List<Vector3> accelerations) {
    if (accelerations.length < 3) return 0;

    int peaks = 0;
    final magnitudes = accelerations.map((v) => v.magnitude).toList();
    final threshold =
        _analyzeAxisData(magnitudes).mean + _analyzeAxisData(magnitudes).stdDev;

    for (int i = 1; i < magnitudes.length - 1; i++) {
      if (magnitudes[i] > magnitudes[i - 1] &&
          magnitudes[i] > magnitudes[i + 1] &&
          magnitudes[i] > threshold) {
        peaks++;
      }
    }

    return peaks;
  }

  /// Calculates smoothness of movement (lower is smoother)
  static double _calculateSmoothness(List<Vector3> accelerations) {
    if (accelerations.length < 2) return 0.0;

    double totalJerk = 0.0;
    for (int i = 1; i < accelerations.length; i++) {
      final diff = Vector3(
        accelerations[i].x - accelerations[i - 1].x,
        accelerations[i].y - accelerations[i - 1].y,
        accelerations[i].z - accelerations[i - 1].z,
      );
      totalJerk += diff.magnitude;
    }

    return totalJerk / (accelerations.length - 1);
  }

  /// Calculates overall metrics for the activity
  static OverallMetrics _calculateOverallMetrics(
    ActivityRecord record,
    Map<String, SensorAnalysis> sensorAnalyses,
  ) {
    if (sensorAnalyses.isEmpty) {
      return OverallMetrics.empty();
    }

    final avgIntensity =
        sensorAnalyses.values
            .map((s) => s.movementIntensity)
            .reduce((a, b) => a + b) /
        sensorAnalyses.length;

    final totalPeaks = sensorAnalyses.values
        .map((s) => s.peaks)
        .reduce((a, b) => a + b);

    final avgSmoothness =
        sensorAnalyses.values.map((s) => s.smoothness).reduce((a, b) => a + b) /
        sensorAnalyses.length;

    // Calculate activity intensity level
    String intensityLevel;
    if (avgIntensity < 1.5) {
      intensityLevel = 'Baixa';
    } else if (avgIntensity < 3.0) {
      intensityLevel = 'Moderada';
    } else {
      intensityLevel = 'Alta';
    }

    // Calculate movement quality
    String movementQuality;
    if (avgSmoothness < 0.5) {
      movementQuality = 'Muito Suave';
    } else if (avgSmoothness < 1.5) {
      movementQuality = 'Suave';
    } else if (avgSmoothness < 3.0) {
      movementQuality = 'Moderado';
    } else {
      movementQuality = 'Intenso';
    }

    return OverallMetrics(
      averageIntensity: avgIntensity,
      intensityLevel: intensityLevel,
      totalPeaks: totalPeaks,
      averageSmoothness: avgSmoothness,
      movementQuality: movementQuality,
      dataQuality: _assessDataQuality(record),
    );
  }

  /// Analyzes phone sensor data from an activity
  static PhoneSensorAnalysis _analyzePhoneSensors(
    List<ActivityDataPoint> dataPoints,
  ) {
    final phoneData = dataPoints
        .where((dp) => dp.phoneSensors != null)
        .map((dp) => dp.phoneSensors!)
        .toList();

    if (phoneData.isEmpty) {
      return PhoneSensorAnalysis.empty();
    }

    // Accelerometer
    final accelData = phoneData
        .where((p) => p.accelX != null && p.accelY != null && p.accelZ != null)
        .map((p) => Vector3(p.accelX!, p.accelY!, p.accelZ!))
        .toList();

    // Gyroscope
    final gyroData = phoneData
        .where((p) => p.gyroX != null && p.gyroY != null && p.gyroZ != null)
        .map((p) => Vector3(p.gyroX!, p.gyroY!, p.gyroZ!))
        .toList();

    // Magnetometer
    final magData = phoneData
        .where((p) => p.magX != null && p.magY != null && p.magZ != null)
        .map((p) => Vector3(p.magX!, p.magY!, p.magZ!))
        .toList();

    // GPS
    final validGpsPoints = phoneData.where((p) => p.gpsSpeed != null).length;
    final avgSpeed =
        phoneData
            .where((p) => p.gpsSpeed != null)
            .map((p) => p.gpsSpeed!)
            .fold(0.0, (a, b) => a + b) /
        (validGpsPoints > 0 ? validGpsPoints : 1);

    // Barometer
    final validBaroPoints = phoneData
        .where((p) => p.barometricPressure != null)
        .length;
    final avgPressure =
        phoneData
            .where((p) => p.barometricPressure != null)
            .map((p) => p.barometricPressure!)
            .fold(0.0, (a, b) => a + b) /
        (validBaroPoints > 0 ? validBaroPoints : 1);

    return PhoneSensorAnalysis(
      hasAccelerometer: accelData.isNotEmpty,
      accelerometer: accelData.isNotEmpty
          ? _analyzeVector3List(accelData, 'm/s²')
          : null,
      hasGyroscope: gyroData.isNotEmpty,
      gyroscope: gyroData.isNotEmpty
          ? _analyzeVector3List(gyroData, 'rad/s')
          : null,
      hasMagnetometer: magData.isNotEmpty,
      magnetometer: magData.isNotEmpty
          ? _analyzeVector3List(magData, 'µT')
          : null,
      hasGps: validGpsPoints > 0,
      gpsAverageSpeed: avgSpeed,
      hasBarometer: validBaroPoints > 0,
      barometerAveragePressure: avgPressure,
    );
  }

  /// Assesses the quality of collected data
  static double _assessDataQuality(ActivityRecord record) {
    if (record.dataPoints.isEmpty) return 0.0;

    // Check for data consistency
    int validPoints = 0;
    for (var point in record.dataPoints) {
      bool hasValidData = false;
      for (var sensor in point.sensors.values) {
        if (sensor.accelX.abs() < 100 &&
            sensor.accelY.abs() < 100 &&
            sensor.accelZ.abs() < 100) {
          hasValidData = true;
          break;
        }
      }
      if (hasValidData) validPoints++;
    }

    return validPoints / record.dataPoints.length;
  }
}

// Data models for analysis results

class ActivityAnalysis {
  final ActivityRecord record;
  final Map<String, SensorAnalysis> sensorAnalyses;
  final PhoneSensorAnalysis? phoneSensorAnalysis;
  final OverallMetrics overallMetrics;

  ActivityAnalysis({
    required this.record,
    required this.sensorAnalyses,
    this.phoneSensorAnalysis,
    required this.overallMetrics,
  });

  factory ActivityAnalysis.empty(ActivityRecord record) {
    return ActivityAnalysis(
      record: record,
      sensorAnalyses: {},
      phoneSensorAnalysis: null,
      overallMetrics: OverallMetrics.empty(),
    );
  }
}

class SensorAnalysis {
  final String sensorId;
  final Vector3Analysis acceleration;
  final Vector3Analysis gyroscope;
  final Vector3Analysis orientation;
  final double movementIntensity;
  final int peaks;
  final double smoothness;

  SensorAnalysis({
    required this.sensorId,
    required this.acceleration,
    required this.gyroscope,
    required this.orientation,
    required this.movementIntensity,
    required this.peaks,
    required this.smoothness,
  });
}

class Vector3Analysis {
  final AxisStatistics x;
  final AxisStatistics y;
  final AxisStatistics z;
  final AxisStatistics magnitude;
  final String unit;

  Vector3Analysis({
    required this.x,
    required this.y,
    required this.z,
    required this.magnitude,
    required this.unit,
  });

  factory Vector3Analysis.empty(String unit) {
    final empty = AxisStatistics.empty();
    return Vector3Analysis(
      x: empty,
      y: empty,
      z: empty,
      magnitude: empty,
      unit: unit,
    );
  }
}

class AxisStatistics {
  final double min;
  final double max;
  final double mean;
  final double median;
  final double stdDev;
  final double range;

  AxisStatistics({
    required this.min,
    required this.max,
    required this.mean,
    required this.median,
    required this.stdDev,
    required this.range,
  });

  factory AxisStatistics.empty() {
    return AxisStatistics(
      min: 0.0,
      max: 0.0,
      mean: 0.0,
      median: 0.0,
      stdDev: 0.0,
      range: 0.0,
    );
  }
}

class OverallMetrics {
  final double averageIntensity;
  final String intensityLevel;
  final int totalPeaks;
  final double averageSmoothness;
  final String movementQuality;
  final double dataQuality;

  OverallMetrics({
    required this.averageIntensity,
    required this.intensityLevel,
    required this.totalPeaks,
    required this.averageSmoothness,
    required this.movementQuality,
    required this.dataQuality,
  });

  factory OverallMetrics.empty() {
    return OverallMetrics(
      averageIntensity: 0.0,
      intensityLevel: 'N/A',
      totalPeaks: 0,
      averageSmoothness: 0.0,
      movementQuality: 'N/A',
      dataQuality: 0.0,
    );
  }
}

/// Represents phone sensor data analysis
class PhoneSensorAnalysis {
  final bool hasAccelerometer;
  final Vector3Analysis? accelerometer;
  final bool hasGyroscope;
  final Vector3Analysis? gyroscope;
  final bool hasMagnetometer;
  final Vector3Analysis? magnetometer;
  final bool hasGps;
  final double gpsAverageSpeed;
  final bool hasBarometer;
  final double barometerAveragePressure;

  PhoneSensorAnalysis({
    required this.hasAccelerometer,
    this.accelerometer,
    required this.hasGyroscope,
    this.gyroscope,
    required this.hasMagnetometer,
    this.magnetometer,
    required this.hasGps,
    required this.gpsAverageSpeed,
    required this.hasBarometer,
    required this.barometerAveragePressure,
  });

  factory PhoneSensorAnalysis.empty() {
    return PhoneSensorAnalysis(
      hasAccelerometer: false,
      hasGyroscope: false,
      hasMagnetometer: false,
      hasGps: false,
      gpsAverageSpeed: 0.0,
      hasBarometer: false,
      barometerAveragePressure: 0.0,
    );
  }
}

// Helper class for 3D vectors
class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);

  double get magnitude => sqrt(x * x + y * y + z * z);
}
