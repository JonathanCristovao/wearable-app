import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/activity_record.dart';

class LLMService {
  static const String _baseUrl =
      'https://api.openai.com/v1/chat/completions';

  // Maximum data points to send to the LLM (to avoid token limits)
  static const int _maxSamplePoints = 80;

  /// Sends a message to the LLM with the activity context and returns the reply.
  Future<String> chat({
    required ActivityRecord? activity,
    required List<Map<String, String>> history,
    required String userMessage,
    String? selectedSensor,
    bool allSensors = false,
  }) async {
    // When allSensors is true, ignore selectedSensor so all sensors are included
    final systemContent =
        _buildSystemPrompt(activity, allSensors ? null : selectedSensor);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      ...history,
      {'role': 'user', 'content': userMessage},
    ];

    final body = jsonEncode({
      'model': OPENAI_MODEL,
      'messages': messages,
      'max_tokens': 1200,
      'temperature': 0.5,
    });

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $OPENAI_API_KEY',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices'][0]['message']['content'] as String;
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      final msg = err['error']?['message'] ?? 'Erro desconhecido';
      throw Exception('OpenAI ${response.statusCode}: $msg');
    }
  }

  String _buildSystemPrompt(ActivityRecord? activity, String? selectedSensor) {
    final sb = StringBuffer();
    sb.writeln(
      'Você é um especialista em análise de dados de sensores IMU (acelerômetro e giroscópio) '
      'aplicado a atividades físicas. Responda sempre em português brasileiro de forma clara, '
      'objetiva e técnica. Destaque anomalias, padrões relevantes e recomendações práticas. '
      'Quando mencionar valores numéricos, seja específico.',
    );

    if (activity == null) {
      sb.writeln(
        '\nNenhuma atividade selecionada. Oriente o usuário a selecionar uma atividade.',
      );
      return sb.toString();
    }

    // --- Metadata ---
    sb.writeln('\n=== METADADOS DA ATIVIDADE ===');
    sb.writeln('ID: ${activity.id}');
    sb.writeln('Tipo: ${activity.activityName}');
    sb.writeln('Início: ${activity.startTime.toIso8601String()}');
    sb.writeln('Fim: ${activity.endTime.toIso8601String()}');
    sb.writeln('Duração: ${activity.formattedDuration}');
    sb.writeln('Total de amostras: ${activity.dataPoints.length}');

    if (activity.dataPoints.isEmpty) {
      sb.writeln('\nSem dados de sensores disponíveis para esta atividade.');
      return sb.toString();
    }

    // --- Sensor statistics ---
    final sensors = _getSensorKeys(activity, selectedSensor);
    for (final sensorKey in sensors) {
      final stats = _computeStats(activity, sensorKey);
      if (stats == null) continue;

      sb.writeln('\n=== SENSOR: $sensorKey ===');
      sb.writeln('  accelX: min=${_f(stats['accelX_min']!)} max=${_f(stats['accelX_max']!)} avg=${_f(stats['accelX_avg']!)} std=${_f(stats['accelX_std']!)} g');
      sb.writeln('  accelY: min=${_f(stats['accelY_min']!)} max=${_f(stats['accelY_max']!)} avg=${_f(stats['accelY_avg']!)} std=${_f(stats['accelY_std']!)} g');
      sb.writeln('  accelZ: min=${_f(stats['accelZ_min']!)} max=${_f(stats['accelZ_max']!)} avg=${_f(stats['accelZ_avg']!)} std=${_f(stats['accelZ_std']!)} g');
      sb.writeln('  gyroX:  min=${_f(stats['gyroX_min']!)} max=${_f(stats['gyroX_max']!)} avg=${_f(stats['gyroX_avg']!)} std=${_f(stats['gyroX_std']!)} °/s');
      sb.writeln('  gyroY:  min=${_f(stats['gyroY_min']!)} max=${_f(stats['gyroY_max']!)} avg=${_f(stats['gyroY_avg']!)} std=${_f(stats['gyroY_std']!)} °/s');
      sb.writeln('  gyroZ:  min=${_f(stats['gyroZ_min']!)} max=${_f(stats['gyroZ_max']!)} avg=${_f(stats['gyroZ_avg']!)} std=${_f(stats['gyroZ_std']!)} °/s');
      sb.writeln('  roll:   min=${_f(stats['roll_min']!)} max=${_f(stats['roll_max']!)} avg=${_f(stats['roll_avg']!)} std=${_f(stats['roll_std']!)} °');
      sb.writeln('  pitch:  min=${_f(stats['pitch_min']!)} max=${_f(stats['pitch_max']!)} avg=${_f(stats['pitch_avg']!)} std=${_f(stats['pitch_std']!)} °');
      sb.writeln('  yaw:    min=${_f(stats['yaw_min']!)} max=${_f(stats['yaw_max']!)} avg=${_f(stats['yaw_avg']!)} std=${_f(stats['yaw_std']!)} °');

      // --- Sample time-series (sub-sampled) ---
      final sample = _sampleDataForSensor(activity, sensorKey);
      if (sample.isNotEmpty) {
        sb.writeln('\n  Amostra temporal (t_s | accelX | accelY | accelZ | roll | pitch | yaw):');
        for (final row in sample) {
          sb.writeln('  ${row}');
        }
      }
    }

    return sb.toString();
  }

  List<String> _getSensorKeys(ActivityRecord activity, String? selectedSensor) {
    final keys = <String>{};
    for (final dp in activity.dataPoints) {
      keys.addAll(dp.sensors.keys);
    }
    if (selectedSensor != null && keys.contains(selectedSensor)) {
      return [selectedSensor];
    }
    return keys.toList()..sort();
  }

  Map<String, double>? _computeStats(
      ActivityRecord activity, String sensorKey) {
    final fields = ['accelX', 'accelY', 'accelZ', 'gyroX', 'gyroY', 'gyroZ', 'roll', 'pitch', 'yaw'];
    final data = <String, List<double>>{for (final f in fields) f: []};

    for (final dp in activity.dataPoints) {
      final snap = dp.sensors[sensorKey];
      if (snap == null) continue;
      data['accelX']!.add(snap.accelX);
      data['accelY']!.add(snap.accelY);
      data['accelZ']!.add(snap.accelZ);
      data['gyroX']!.add(snap.gyroX);
      data['gyroY']!.add(snap.gyroY);
      data['gyroZ']!.add(snap.gyroZ);
      data['roll']!.add(snap.roll);
      data['pitch']!.add(snap.pitch);
      data['yaw']!.add(snap.yaw);
    }

    if (data['accelX']!.isEmpty) return null;

    final stats = <String, double>{};
    for (final field in fields) {
      final vals = data[field]!;
      final mn = vals.reduce(math.min);
      final mx = vals.reduce(math.max);
      final avg = vals.reduce((a, b) => a + b) / vals.length;
      final variance =
          vals.map((v) => (v - avg) * (v - avg)).reduce((a, b) => a + b) /
              vals.length;
      final std = math.sqrt(variance);
      stats['${field}_min'] = mn;
      stats['${field}_max'] = mx;
      stats['${field}_avg'] = avg;
      stats['${field}_std'] = std;
    }
    return stats;
  }

  List<String> _sampleDataForSensor(
      ActivityRecord activity, String sensorKey) {
    final relevant = activity.dataPoints
        .where((dp) => dp.sensors.containsKey(sensorKey))
        .toList();

    if (relevant.isEmpty) return [];

    final step =
        (relevant.length / _maxSamplePoints).ceil().clamp(1, 99999);
    final rows = <String>[];
    final t0 = relevant.first.timestamp;

    for (int i = 0; i < relevant.length; i += step) {
      final dp = relevant[i];
      final snap = dp.sensors[sensorKey]!;
      final t = dp.timestamp.difference(t0).inMilliseconds / 1000.0;
      rows.add(
        '${t.toStringAsFixed(2)} | ${_f(snap.accelX)} | ${_f(snap.accelY)} | ${_f(snap.accelZ)} | ${_f(snap.roll)} | ${_f(snap.pitch)} | ${_f(snap.yaw)}',
      );
    }
    return rows;
  }

  /// Extract chart data for a specific metric and sensor.
  List<({double t, double value})> extractTimeSeries(
    ActivityRecord activity,
    String sensorKey,
    String metric,
  ) {
    final relevant = activity.dataPoints
        .where((dp) => dp.sensors.containsKey(sensorKey))
        .toList();

    if (relevant.isEmpty) return [];

    final t0 = relevant.first.timestamp;
    return relevant.map((dp) {
      final snap = dp.sensors[sensorKey]!;
      final t = dp.timestamp.difference(t0).inMilliseconds / 1000.0;
      return (t: t, value: _snapValue(snap, metric));
    }).toList();
  }

  double _snapValue(dynamic snap, String metric) {
    switch (metric) {
      case 'accelX': return snap.accelX as double;
      case 'accelY': return snap.accelY as double;
      case 'accelZ': return snap.accelZ as double;
      case 'gyroX':  return snap.gyroX as double;
      case 'gyroY':  return snap.gyroY as double;
      case 'gyroZ':  return snap.gyroZ as double;
      case 'roll':   return snap.roll as double;
      case 'pitch':  return snap.pitch as double;
      case 'yaw':    return snap.yaw as double;
      default:       return 0.0;
    }
  }

  String _f(double v) => v.toStringAsFixed(3);
}
