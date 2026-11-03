class NotificationModel {
  final int id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'];
    return NotificationModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }

  NotificationModel asRead() => NotificationModel(
        id: id,
        title: title,
        body: body,
        isRead: true,
        createdAt: createdAt,
      );
}
