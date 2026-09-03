/// Metadata describing one recorded sensor session.
///
/// Serializes to the `metadata.json` uploaded alongside each session's
/// compressed sensor files.
class ActivityMetadata {
  final String sessionId;
  final String activity;
  final DateTime createdAt;
  final int durationSeconds;
  final int samplingRate;
  final String device;
  final List<String> sensors;

  const ActivityMetadata({
    required this.sessionId,
    required this.activity,
    required this.createdAt,
    required this.durationSeconds,
    required this.samplingRate,
    required this.device,
    required this.sensors,
  });

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'activity': activity,
        'created_at': createdAt.toIso8601String(),
        'duration_seconds': durationSeconds,
        'sampling_rate': samplingRate,
        'device': device,
        'sensors': sensors,
      };

  factory ActivityMetadata.fromJson(Map<String, dynamic> json) =>
      ActivityMetadata(
        sessionId: json['session_id'] as String,
        activity: json['activity'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        durationSeconds: json['duration_seconds'] as int,
        samplingRate: json['sampling_rate'] as int,
        device: json['device'] as String,
        sensors: List<String>.from(json['sensors'] as List),
      );
}
