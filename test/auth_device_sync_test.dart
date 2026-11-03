import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/core/notifications/push_service.dart';
import 'package:tanipintar/modules/auth/providers/auth_provider.dart';
import 'package:tanipintar/modules/auth/services/auth_service.dart';

const _login = '{"success":true,"message":"ok","data":{"id":3,"name":"a",'
    '"email":"a@example.com","msisdn":"1","access_token":"jwt-1",'
    '"refresh_token":"r","installation_id":"i","device_token_registered":false}}';

void main() {
  test('a login that came back unregistered binds the device afterwards', () async {
    final seen = <http.Request>[];
    final client = MockClient((req) async {
      seen.add(req);
      return http.Response(
        req.url.path.endsWith('/login')
            ? _login
            : '{"success":true,"message":"Device token updated"}',
        200,
      );
    });
    final rpc = RpcClient(baseUrl: 'https://example.test', httpClient: client);
    final auth = AuthProvider(
      authService: AuthService(rpcClient: rpc),
      rpcClient: rpc,
      deviceRegistration: () async =>
          const DeviceRegistration(token: 'fcm-token', type: 'android'),
    );

    expect(await auth.login('a@example.com', 'secret'), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    auth.dispose();

    final bind = seen.singleWhere((r) => r.url.path.endsWith('/auth/device-token'));
    expect(bind.headers['Authorization'], 'Bearer jwt-1');
    expect(jsonDecode(bind.body), {'device_token': 'fcm-token', 'device_type': 'android'});
  });
}
