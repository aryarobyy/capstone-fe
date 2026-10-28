import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/area/providers/area_provider.dart';
import 'package:tanipintar/modules/area/services/area_service.dart';
import 'package:tanipintar/modules/area/services/sensor_service.dart';
import 'package:tanipintar/modules/monitoring/models/alert_rule_model.dart';
import 'package:tanipintar/modules/monitoring/services/monitoring_service.dart';

/// Real payloads captured from https://arifingaybanget.cipicung.id/api
const _areaList = '[{"id":1,"name":"Area Uji"}]';
const _areaCreate = '{"id":7}';
const _sensorList = '{"success":true,"message":"Sensors retrieved successfully",'
    '"data":{"data":[{"id":2,"area_id":1,"owner_id":12,"name":"ESP32 Uji",'
    '"code":"ESP32-001","description":"tes",'
    '"created_at":"2026-10-20T17:07:53.673392+07:00",'
    '"updated_at":"2026-10-20T17:07:53.673392+07:00"}],'
    '"total":1,"limit":20,"index":0}}';
const _sensorCreateError = '{"success":false,'
    '"message":"Validation failed for one or more fields.",'
    '"errors":["The \'name\' field is required."]}';

AreaProvider _providerWith(
  Future<http.Response> Function(http.Request req) handler, {
  List<http.Request>? seen,
}) {
  final client = MockClient((req) async {
    seen?.add(req);
    return handler(req);
  });
  final rpc = RpcClient(baseUrl: 'https://example.test', httpClient: client);
  return AreaProvider(
    areaService: AreaService(rpcClient: rpc),
    sensorService: SensorService(rpcClient: rpc),
  );
}

void main() {
  test('fetchAreas parses the bare JSON array from /areas/list', () async {
    final provider = _providerWith((_) async => http.Response(_areaList, 200));

    await provider.fetchAreas();

    expect(provider.errorMessage, isNull);
    expect(provider.areas.single.id, 1);
    expect(provider.areas.single.name, 'Area Uji');
    expect(provider.totalAreas, 1);
  });

  test('fetchSensors parses the enveloped paginated sensor list', () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (_) async => http.Response(_sensorList, 200),
      seen: requests,
    );

    await provider.fetchSensors(areaId: 1);

    expect(provider.errorMessage, isNull);
    expect(provider.sensors.single.code, 'ESP32-001');
    expect(provider.totalSensors, 1);
    expect(provider.sensorAreaFilter, 1);
    expect(jsonDecode(requests.single.body)['area_id'], 1);
  });

  test('createArea inserts the area locally using the returned id', () async {
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/areas/create')
          ? http.Response(_areaCreate, 201)
          : http.Response(_areaList, 200),
    );

    final ok = await provider.createArea(name: 'Area Baru', location: 'Blok A');

    expect(ok, isTrue);
    expect(provider.areas.first.id, 7);
    expect(provider.areas.first.name, 'Area Baru');
  });

  test('createSensor surfaces validation errors from the API', () async {
    final provider =
        _providerWith((_) async => http.Response(_sensorCreateError, 400));

    final ok = await provider.createSensor(name: '', code: '', areaId: 1);

    expect(ok, isFalse);
    expect(provider.errorMessage, contains("The 'name' field is required."));
    expect(provider.sensors, isEmpty);
  });

  test('updateArea posts to /areas/update and patches the area', () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/areas/update')
          ? http.Response('', 204)
          : http.Response(_areaList, 200),
      seen: requests,
    );
    await provider.fetchAreas();

    final ok = await provider.updateArea(
      id: 1,
      name: 'Area Ubah',
      location: 'Blok B',
    );

    expect(ok, isTrue);
    expect(requests.last.url.path, endsWith('/areas/update'));
    expect(jsonDecode(requests.last.body), {
      'id': 1,
      'name': 'Area Ubah',
      'location': 'Blok B',
    });
    expect(provider.areas.single.name, 'Area Ubah');
    expect(provider.areas.single.location, 'Blok B');
  });

  test('deleteArea drops the area, its sensors and the filter', () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (req) async {
        if (req.url.path.endsWith('/sensor/list')) {
          return http.Response(_sensorList, 200);
        }
        if (req.url.path.endsWith('/areas/delete')) {
          return http.Response('', 204);
        }
        return http.Response(_areaList, 200);
      },
      seen: requests,
    );
    await provider.fetchAreas();
    await provider.fetchSensors(areaId: 1);
    expect(provider.sensors, hasLength(1));

    final ok = await provider.deleteArea(1);

    expect(ok, isTrue);
    expect(requests.last.url.path, endsWith('/areas/delete'));
    expect(jsonDecode(requests.last.body), {'id': 1});
    expect(provider.areas, isEmpty);
    expect(provider.totalAreas, 0);
    expect(provider.sensors, isEmpty);
    expect(provider.totalSensors, 0);
    expect(provider.sensorAreaFilter, isNull);
  });

  test('a 404 on area update/delete keeps the list and shows the BE error', () async {
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/areas/list')
          ? http.Response(_areaList, 200)
          : http.Response('{"error":"area not found"}', 404),
    );
    await provider.fetchAreas();

    expect(await provider.updateArea(id: 1, name: 'Area Ubah'), isFalse);
    expect(provider.errorMessage, 'area not found');
    expect(provider.areas.single.name, 'Area Uji');

    expect(await provider.deleteArea(1), isFalse);
    expect(provider.errorMessage, 'area not found');
    expect(provider.areas, hasLength(1));
  });

  test('alert rule save hits /alerts/rules/save and survives 204', () async {
    final seen = <http.Request>[];
    final rpc = RpcClient(
      baseUrl: 'https://example.test',
      httpClient: MockClient((req) async {
        seen.add(req);
        return http.Response('', 204);
      }),
    );
    const rule = AlertRuleModel(
        sensorId: 2, parameter: 'temperature', minValue: 10, maxValue: 40);
    final res = await MonitoringService(rpcClient: rpc).saveAlertRule(rule);

    expect(res.success, isTrue);
    expect(res.data, same(rule));
    expect(seen.single.url.path, '/api/alerts/rules/save');
    expect(jsonDecode(seen.single.body)['max_gap_seconds'], 300);
  });

  test('area mutations on an unknown id fail loudly', () async {
    final provider = _providerWith((_) async => http.Response('[]', 200));
    await provider.fetchAreas();

    expect(await provider.updateArea(id: 99, name: 'x'), isFalse);
    expect(provider.errorMessage, 'Area tidak ditemukan.');
    expect(await provider.deleteArea(99), isFalse);
    expect(provider.errorMessage, 'Area tidak ditemukan.');
  });

  test('unauthenticated bare-JSON error body is reported', () async {
    final provider = _providerWith(
      (_) async => http.Response('{"error":"valid access token required"}', 401),
    );

    await provider.fetchAreas();

    expect(provider.errorMessage, 'valid access token required');
  });
}
