/// One reading pushed by `/sensor-reading/stream`.
class SensorActivityModel {
  final int id;
  final int sensorId;
  final String sensorName;
  final double soilMoisture;
  final double temperature;
  final double humidity;
  final DateTime? recordedAt;

  const SensorActivityModel({
    required this.id,
    required this.sensorId,
    required this.sensorName,
    required this.soilMoisture,
    required this.temperature,
    required this.humidity,
    this.recordedAt,
  });

  factory SensorActivityModel.fromJson(Map<String, dynamic> json) {
    return SensorActivityModel(
      id: json['id'] as int? ?? 0,
      sensorId: json['sensor_id'] as int? ?? 0,
      sensorName: json['sensor_name'] as String? ?? '',
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble() ?? 0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0,
      humidity: (json['humidity'] as num?)?.toDouble() ?? 0,
      recordedAt: json['recorded_at'] != null
          ? DateTime.tryParse(json['recorded_at'] as String)?.toLocal()
          : null,
    );
  }
}
