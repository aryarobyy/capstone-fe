import 'dart:convert';
import 'package:http/http.dart' as http;

class RpcException implements Exception {
  final int statusCode;
  final String message;
  final List<String> errors;

  const RpcException({
    required this.statusCode,
    required this.message,
    this.errors = const [],
  });

  @override
  String toString() {
    if (errors.isNotEmpty) {
      return '$message: ${errors.join(", ")}';
    }
    return message;
  }
}

class RpcClient {
  final String baseUrl;
  final Future<String?> Function()? getToken;
  final http.Client _httpClient;

  RpcClient({
    required this.baseUrl,
    this.getToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Bearer token attached to every request. Set by `AuthProvider` on login,
  /// cleared on logout. Takes precedence over [getToken].
  String? token;

  /// Refreshes the session on 401; returns the new access token or null.
  Future<String?> Function()? onUnauthorized;

  Future<Map<String, dynamic>> call({
    required String procedure,
    Map<String, dynamic>? params,
    Map<String, String>? extraHeaders,
  }) async {
    final decoded = await callRaw(
      procedure: procedure,
      params: params,
      extraHeaders: extraHeaders,
    );

    if (decoded is Map<String, dynamic>) return decoded;

    // Endpoint answered with a bare array/scalar; wrap it in the envelope.
    return {'success': true, 'message': '', 'data': decoded};
  }

  /// Same as [call] but returns the decoded body as-is. Needed for endpoints
  /// that reply with a bare JSON array or a plain object instead of the
  /// `{success, message, data}` envelope (e.g. `/areas/list`, `/areas/create`).
  Future<dynamic> callRaw({
    required String procedure,
    Map<String, dynamic>? params,
    Map<String, String>? extraHeaders,
  }) =>
      _send(procedure, params, extraHeaders, canRetry: true);

  Future<dynamic> _send(
    String procedure,
    Map<String, dynamic>? params,
    Map<String, String>? extraHeaders, {
    required bool canRetry,
  }) async {
    final bearer = token ?? (getToken != null ? await getToken!() : null);

    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanProcedure = procedure.startsWith('/') ? procedure : '/$procedure';
    final url = Uri.parse('$cleanBase/api$cleanProcedure');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearer != null && bearer.isNotEmpty) 'Authorization': 'Bearer $bearer',
      ...?extraHeaders,
    };

    try {
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(params ?? {}),
      );

      final body = response.body.trim();
      final ok = response.statusCode >= 200 && response.statusCode < 300;

      if (ok) {
        return body.isEmpty ? null : jsonDecode(body);
      }

      // Error bodies are not always JSON (e.g. Go's plain "404 page not found"),
      // so keep the status code instead of failing to decode.
      Map<String, dynamic>? asMap;
      try {
        final decoded = body.isEmpty ? null : jsonDecode(body);
        if (decoded is Map<String, dynamic>) asMap = decoded;
      } on FormatException {
        asMap = null;
      }

      if (response.statusCode == 401 &&
          canRetry &&
          onUnauthorized != null &&
          bearer != null &&
          bearer.isNotEmpty &&
          !procedure.startsWith('/auth/')) {
        final fresh = (token != null && token != bearer)
            ? token
            : await onUnauthorized!();
        if (fresh != null) {
          return await _send(procedure, params, extraHeaders, canRetry: false);
        }
      }

      throw RpcException(
        statusCode: response.statusCode,
        message: asMap?['message'] as String? ??
            asMap?['error'] as String? ??
            'Terjadi kesalahan pada server.',
        errors: asMap?['errors'] is List
            ? List<String>.from(asMap!['errors'] as List)
            : const [],
      );
    } on http.ClientException catch (e) {
      throw RpcException(
        statusCode: 0,
        message: 'Koneksi jaringan terputus: ${e.message}',
      );
    } on FormatException {
      throw const RpcException(
        statusCode: 0,
        message: 'Respons dari server bukan format JSON yang valid.',
      );
    }
  }

  void close() {
    _httpClient.close();
  }
}
