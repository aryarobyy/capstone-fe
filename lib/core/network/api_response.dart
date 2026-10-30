class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<String> errors;

  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors = const [],
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: _parseErrors(json['errors']),
    );
  }

  /// `errors` is a list of strings on some endpoints and a plain string on
  /// others (sensors, areas), so accept either instead of hard-casting.
  static List<String> _parseErrors(dynamic errors) {
    if (errors == null) return const [];
    if (errors is List) return errors.map((e) => '$e').toList();
    if (errors is Map) return errors.values.map((e) => '$e').toList();
    return ['$errors'];
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T value)? toJsonT) {
    return {
      'success': success,
      'message': message,
      if (data != null)
        'data': toJsonT != null ? toJsonT(data as T) : data,
      if (errors.isNotEmpty) 'errors': errors,
    };
  }
}

class PaginatedData<T> {
  final List<T> data;
  final int total;
  final int limit;
  final int index;

  const PaginatedData({
    required this.data,
    required this.total,
    required this.limit,
    required this.index,
  });

  factory PaginatedData.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> itemJson) fromJsonT,
  ) {
    final rawList = json['data'] as List? ?? [];
    return PaginatedData<T>(
      data: rawList
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      limit: json['limit'] as int? ?? 0,
      index: json['index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T item) toJsonT) {
    return {
      'data': data.map((item) => toJsonT(item)).toList(),
      'total': total,
      'limit': limit,
      'index': index,
    };
  }
}
