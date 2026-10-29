class AlertRuleModel {
  final int? id;
  final int sensorId;
  final String parameter;
  final double minValue;
  final double maxValue;
  final int durationSeconds;
  final int cooldownSeconds;
  final bool enabled;

  const AlertRuleModel({
    this.id,
    required this.sensorId,
    required this.parameter,
    required this.minValue,
    required this.maxValue,
    this.durationSeconds = 300,
    this.cooldownSeconds = 600,
    this.enabled = true,
  });

  factory AlertRuleModel.fromJson(Map<String, dynamic> json) {
    return AlertRuleModel(
      id: json['id'] as int?,
      sensorId: json['sensor_id'] as int? ?? 0,
      parameter: json['parameter'] as String? ?? '',
      minValue: (json['min_value'] as num?)?.toDouble() ?? 0.0,
      maxValue: (json['max_value'] as num?)?.toDouble() ?? 100.0,
      durationSeconds: json['duration_seconds'] as int? ?? 300,
      cooldownSeconds: json['cooldown_seconds'] as int? ?? 600,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'sensor_id': sensorId,
      'parameter': parameter,
      'min_value': minValue,
      'max_value': maxValue,
      'duration_seconds': durationSeconds,
      'cooldown_seconds': cooldownSeconds,
      'enabled': enabled,
    };
  }

  AlertRuleModel copyWith({
    int? id,
    int? sensorId,
    String? parameter,
    double? minValue,
    double? maxValue,
    int? durationSeconds,
    int? cooldownSeconds,
    bool? enabled,
  }) {
    return AlertRuleModel(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      parameter: parameter ?? this.parameter,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      enabled: enabled ?? this.enabled,
    );
  }
}
