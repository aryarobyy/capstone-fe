/// The API models an area as `{id, name}` only. [sensorsCount] is derived on
/// the client from the sensor list, never sent by the server.
class AreaModel {
  final int id;
  final String name;
  final int sensorsCount;

  const AreaModel({
    required this.id,
    required this.name,
    this.sensorsCount = 0,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sensorsCount: json['sensors_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  AreaModel copyWith({
    int? id,
    String? name,
    int? sensorsCount,
  }) {
    return AreaModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sensorsCount: sensorsCount ?? this.sensorsCount,
    );
  }
}
