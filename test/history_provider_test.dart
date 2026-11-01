import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/riwayat/providers/history_provider.dart';
import 'package:tanipintar/modules/riwayat/services/history_service.dart';

const _list = '{"success":true,"message":"History retrieved successfully",'
    '"data":{"data":[{"id":5,"sensor_id":8,"parameter":"temperature",'
    '"status":"WARNING","accumulated_duration":300}],'
    '"total":1,"limit":10,"index":0}}';

const _stream = 'event:anomaly\n'
    'data:{"id":6,"sensor_id":9,"parameter":"soil_moisture",'
    '"status":"WARNING","accumulated_duration":300}\n\n'
    ': ping\n\n'
    'event:anomaly\n'
    'data:{"id":5,"sensor_id":8,"parameter":"temperature",'
    '"status":"WARNING","accumulated_duration":300}\n\n';

void main() {
  test('a refresh streams new anomalies on top, resuming after the newest shown', () async {
    final seen = <http.Request>[];
    final client = MockClient((req) async {
      seen.add(req);
      return http.Response(req.url.path.endsWith('/stream') ? _stream : _list, 200);
    });
    final provider = HistoryProvider(
      historyService: HistoryService(
        rpcClient: RpcClient(baseUrl: 'https://example.test', httpClient: client),
      ),
    );

    provider.setStatus('WARNING');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    provider.stopWatching();

    // id 5 is already listed, so the replayed event is skipped.
    expect(provider.histories.map((h) => h.id), [6, 5]);
    expect(provider.total, 2);
    final stream = seen.firstWhere((r) => r.url.path == '/api/history/stream');
    expect(jsonDecode(stream.body), containsPair('after_id', 5));
    expect(jsonDecode(stream.body), containsPair('status', 'WARNING'));
  });
}
