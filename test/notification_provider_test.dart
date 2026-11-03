import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/notifications/providers/notification_provider.dart';
import 'package:tanipintar/modules/notifications/services/notification_service.dart';

const _list = '{"success":true,"message":"ok","data":['
    '{"id":2,"title":"b","body":"x","is_read":false,"created_at":"2026-11-03T17:16:43+07:00"},'
    '{"id":1,"title":"a","body":"y","is_read":true,"created_at":"2026-11-03T10:00:00+07:00"}]}';

NotificationProvider _provider(int readStatus) {
  final client = MockClient((req) async {
    if (req.url.path.endsWith('/read')) {
      return http.Response('{"success":true,"message":"ok"}', readStatus);
    }
    return http.Response(_list, 200);
  });
  return NotificationProvider(
    notificationService: NotificationService(
      rpcClient: RpcClient(baseUrl: 'https://example.test', httpClient: client),
    ),
  );
}

void main() {
  test('markRead clears the unread count and keeps it when the server accepts', () async {
    final p = _provider(200);
    await p.fetch();
    expect(p.unreadCount, 1);

    await p.markRead(2);
    expect(p.items.first.isRead, isTrue);
    expect(p.unreadCount, 0);
  });

  test('markRead rolls back when the server rejects', () async {
    final p = _provider(404);
    await p.fetch();

    await p.markRead(2);
    expect(p.items.first.isRead, isFalse);
    expect(p.unreadCount, 1);
  });
}
