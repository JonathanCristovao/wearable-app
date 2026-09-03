class UserProfile {
  final String id;
  final String name;
  final int? age;
  final double? weight; // kg
  final double? height; // cm
  final String? injury;
  final String? activityFrequency;
  final String? disease;

  UserProfile({
    required this.id,
    required this.name,
    this.age,
    this.weight,
    this.height,
    this.injury,
    this.activityFrequency,
    this.disease,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    double? weight,
    double? height,
    String? injury,
    String? activityFrequency,
    String? disease,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      injury: injury ?? this.injury,
      activityFrequency: activityFrequency ?? this.activityFrequency,
      disease: disease ?? this.disease,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'injury': injury,
      'activityFrequency': activityFrequency,
      'disease': disease,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      age: map['age'] as int?,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      injury: map['injury'] as String?,
      activityFrequency: map['activityFrequency'] as String?,
      disease: map['disease'] as String?,
    );
  }

  String get summary {
    final parts = <String>[];
    if (age != null) parts.add('$age anos');
    if (weight != null) parts.add('${weight!.toStringAsFixed(1)} kg');
    if (height != null) parts.add('${height!.toStringAsFixed(0)} cm');
    return parts.isEmpty ? 'Sem dados adicionais' : parts.join(' · ');
  }
}
