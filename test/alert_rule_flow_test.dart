import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/area/models/sensor_model.dart';
import 'package:tanipintar/modules/monitoring/models/alert_rule_model.dart';
import 'package:tanipintar/modules/monitoring/providers/monitoring_provider.dart';
import 'package:tanipintar/modules/monitoring/services/monitoring_service.dart';
import 'package:tanipintar/modules/monitoring/widgets/alert_rule_dialog.dart';

MonitoringProvider providerFor(Future<http.Response> Function(http.Request) handler) {
  return MonitoringProvider(monitoringService: MonitoringService(rpcClient: RpcClient(
    baseUrl: 'https://example.test', httpClient: MockClient(handler))));
}

void main() {
  test('maximum-only rules retain null minimum and configured gap', () {
    final rule = AlertRuleModel.fromJson({
      'sensor_id': 8, 'parameter': 'temperature', 'min_value': null,
      'max_value': 30, 'duration_seconds': 300, 'cooldown_seconds': 600,
      'max_gap_seconds': 120, 'enabled': true,
    });
    expect(rule.minValue, isNull);
    expect(rule.toJson()['min_value'], isNull);
    expect(rule.toJson()['max_gap_seconds'], 120);
  });

  test('empty rule responses clear rules from the previous sensor', () async {
    final provider = providerFor((req) async {
      final sensor = jsonDecode(req.body)['sensor_id'];
      return http.Response(sensor == 8
        ? '{"success":true,"data":[{"sensor_id":8,"parameter":"temperature","max_value":30}]}'
        : '{"success":true,"message":"Alert rules retrieved successfully"}', 200);
    });
    expect(await provider.fetchAlertRules(8), isTrue);
    expect(provider.alertRules, hasLength(1));
    expect(await provider.fetchAlertRules(9), isTrue);
    expect(provider.alertRules, isEmpty);
  });

  test('rule failures are visible and do not become an empty success', () async {
    final provider = providerFor((_) async => http.Response(
      '{"success":false,"message":"operation failed"}', 500));
    expect(await provider.fetchAlertRules(8), isFalse);
    expect(provider.ruleErrorMessage, 'operation failed');
    expect(provider.isLoadingRules, isFalse);
  });

  testWidgets('form saves one maximum-only rule for the selected sensor', (tester) async {
    Map<String, dynamic>? saved;
    final provider = providerFor((req) async {
      if (req.url.path.endsWith('/save')) {
        saved = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response('', 204);
      }
      return http.Response('{"success":true}', 200);
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: Scaffold(body: Builder(builder: (context) {
        return TextButton(onPressed: () => showDialog<void>(context: context,
          builder: (_) => const AlertRuleDialog(sensor: SensorModel(
            id: 8, areaId: 5, ownerId: 3, name: 'Sensor Cuaca', code: ''))),
          child: const Text('Open'));
      }))),
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '30');
    await tester.ensureVisible(find.text('Simpan Aturan'));
    await tester.tap(find.text('Simpan Aturan'));
    await tester.pumpAndSettle();
    expect(saved?['sensor_id'], 8);
    expect(saved?['parameter'], 'temperature');
    expect(saved?['min_value'], isNull);
    expect(saved?['max_value'], 30);
    expect(saved?['duration_seconds'], 300);
    expect(saved?['max_gap_seconds'], 300);
    expect(provider.alertRules.single.maxValue, 30);
    expect(find.byType(AlertRuleDialog), findsNothing);
  });

  testWidgets('form rejects saving without either bound', (tester) async {
    var saves = 0;
    final provider = providerFor((req) async {
      if (req.url.path.endsWith('/save')) saves++;
      return http.Response('{"success":true}', 200);
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: const MaterialApp(home: Scaffold(body: AlertRuleDialog(sensor:
        SensorModel(id: 9, areaId: 5, ownerId: 3, name: 'Sensor Tanah', code: ''))))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Simpan Aturan'));
    await tester.tap(find.text('Simpan Aturan'));
    await tester.pumpAndSettle();
    expect(saves, 0);
    expect(find.text('Isi minimal satu batas'), findsOneWidget);
  });
}
