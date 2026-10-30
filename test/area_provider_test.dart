import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tanipintar/modules/area/views/area_screen.dart';
import 'package:tanipintar/modules/area/widgets/add_sensor_modal.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/area/providers/area_provider.dart';
import 'package:tanipintar/modules/home/services/home_service.dart';
import 'package:tanipintar/modules/area/services/area_service.dart';
import 'package:tanipintar/modules/area/services/sensor_service.dart';
import 'package:tanipintar/modules/monitoring/models/alert_rule_model.dart';
import 'package:tanipintar/modules/monitoring/services/monitoring_service.dart';

/// Real payloads captured from https://arifingaybanget.cipicung.id/api
const _areaList = '{"success":true,"message":"Areas retrieved successfully",'
    '"data":[{"id":1,"name":"Area Uji"}]}';
const _areaCreate = '{"success":true,"message":"Area created successfully",'
    '"data":{"id":7,"name":"Area Baru"}}';
const _areaUpdate = '{"success":true,"message":"Area updated successfully",'
    '"data":{"id":1,"name":"Area Ubah"}}';
const _areaDelete =
    '{"success":true,"message":"Area deleted successfully"}';
const _areaNotFound = '{"success":false,"message":"area not found"}';
const _sensorList = '{"success":true,"message":"Sensors retrieved successfully",'
    '"data":{"data":[{"id":2,"area_id":1,"owner_id":12,"name":"ESP32 Uji",'
    '"code":"ESP32-001","description":"tes",'
    '"created_at":"2026-10-20T17:07:53.673392+07:00",'
    '"updated_at":"2026-10-20T17:07:53.673392+07:00"}],'
    '"total":1,"limit":20,"index":0}}';
/// Areas that do NOT contain the sensor fixture's area_id (1).
const _areaListOther = '{"success":true,"message":"Areas retrieved successfully",'
    '"data":[{"id":9,"name":"Area Lain"}]}';
const _sensorCreate = '{"success":true,"message":"Sensor created successfully",'
    '"data":{"id":11,"area_id":1,"owner_id":12,"name":"Sensor Baru",'
    '"code":"ESP32-999","description":"tes",'
    '"created_at":"2026-10-30T22:37:26.453894+07:00",'
    '"updated_at":"2026-10-30T22:37:26.453894+07:00"}}';
// The deployed API sends `errors` as a plain string, not a list.
const _sensorCreateStringError = '{"success":false,'
    '"message":"The \'name\' field is required.",'
    '"errors":"The \'name\' field is required."}';
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
  test('fetchAreas parses the /areas/list envelope', () async {
    final provider = _providerWith((_) async => http.Response(_areaList, 200));

    await provider.fetchAreas();

    expect(provider.errorMessage, isNull);
    expect(provider.areas.single.id, 1);
    expect(provider.areas.single.name, 'Area Uji');
    expect(provider.totalAreas, 1);
  });

  test('fetchAreas reads the deployed API envelope', () async {
    final provider = _providerWith((_) async => http.Response(
      '{"success":true,"message":"Areas retrieved successfully",'
      '"data":[{"id":4,"name":"p"},{"id":5,"name":"arae 1"}]}', 200));
    await provider.fetchAreas();
    expect(provider.errorMessage, isNull);
    expect(provider.areas.map((a) => a.id), [4, 5]);
    expect(provider.totalAreas, 2);
  });

  test('fetchAreas accepts an empty envelope with omitted data', () async {
    final provider = _providerWith((_) async => http.Response(
      '{"success":true,"message":"Areas retrieved successfully"}', 200));
    await provider.fetchAreas();
    expect(provider.errorMessage, isNull);
    expect(provider.areas, isEmpty);
  });

  test('createArea reads the id inside the deployed API envelope', () async {
    final provider = _providerWith((_) async => http.Response(
      '{"success":true,"message":"Area created successfully",'
      '"data":{"id":7,"name":"Area Baru"}}', 201));
    expect(await provider.createArea(name: 'Area Baru'), isTrue);
    expect(provider.areas.single.id, 7);
  });

  test('dashboard counts areas from the deployed API envelope', () async {
    final rpc = RpcClient(baseUrl: 'https://example.test', httpClient: MockClient((req) async {
      if (req.url.path.endsWith('/areas/list')) {
        return http.Response('{"success":true,"data":[{"id":4,"name":"p"},{"id":5,"name":"arae 1"}]}', 200);
      }
      return http.Response('{"success":true,"data":{"data":[],"total":0,"limit":1,"index":0}}', 200);
    }));
    expect((await HomeService(rpcClient: rpc).getDashboardSummary()).totalAreas, 2);
  });

  test('area errors in a 200 envelope remain visible during loadAll', () async {
    final requests = <http.Request>[];
    final provider = _providerWith((req) async => http.Response(
      req.url.path.endsWith('/areas/list')
        ? '{"success":false,"message":"Area tidak dapat dimuat"}'
        : '{"success":true,"data":{"data":[],"total":0}}', 200), seen: requests);
    await provider.loadAll();
    expect(provider.errorMessage, 'Area tidak dapat dimuat');
    expect(requests.map((r) => r.url.path), ['/api/areas/list']);
  });

  test('malformed area data is reported instead of silently dropped', () async {
    for (final data in ['{}', '[{"id":4,"name":"p"},null]']) {
      final provider = _providerWith((_) async => http.Response(
        '{"success":true,"data":$data}', 200));
      await provider.fetchAreas();
      expect(provider.errorMessage, 'Format daftar area dari server tidak valid.');
    }
  });

  test('reloading areas replaces results from the preceding request', () async {
    var calls = 0;
    final provider = _providerWith((_) async => http.Response(
      ++calls == 1 ? _areaList
        : '{"success":true,"data":[{"id":5,"name":"arae 1"}]}', 200));
    await provider.fetchAreas();
    await provider.fetchAreas();
    expect(provider.areas.single.id, 5);
    expect(provider.totalAreas, 1);
  });

  testWidgets('area screen renders both areas returned by the deployed API', (tester) async {
    final provider = _providerWith((req) async => http.Response(
      req.url.path.endsWith('/areas/list')
        ? '{"success":true,"data":[{"id":4,"name":"p"},{"id":5,"name":"arae 1"}]}'
        : _sensorList, 200));
    await tester.pumpWidget(ChangeNotifierProvider.value(value: provider,
      child: const MaterialApp(home: AreaScreen())));
    await tester.pumpAndSettle();
    expect(find.text('p'), findsOneWidget);
    expect(find.text('arae 1'), findsOneWidget);
    expect(find.text('Belum ada data area.'), findsNothing);
    expect(provider.errorMessage, isNull);
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

  test('createArea inserts the area returned by the server', () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/areas/create')
          ? http.Response(_areaCreate, 201)
          : http.Response(_areaList, 200),
      seen: requests,
    );

    final ok = await provider.createArea(name: 'Area Baru');

    expect(ok, isTrue);
    // Only `name` is accepted; anything else is dropped by the backend.
    expect(jsonDecode(requests.single.body), {'name': 'Area Baru'});
    expect(provider.areas.first.id, 7);
    expect(provider.areas.first.name, 'Area Baru');
    expect(provider.totalAreas, 1);
  });

  test('createSensor surfaces validation errors from the API', () async {
    final provider =
        _providerWith((_) async => http.Response(_sensorCreateError, 400));

    final ok = await provider.createSensor(name: '', code: '', areaId: 1);

    expect(ok, isFalse);
    expect(provider.errorMessage, contains("The 'name' field is required."));
    expect(provider.sensors, isEmpty);
  });

  test('createSensor posts to /sensor/create and stores the 201 response',
      () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/sensor/create')
          ? http.Response(_sensorCreate, 201)
          : http.Response(_areaList, 200),
      seen: requests,
    );

    final ok = await provider.createSensor(
      name: 'Sensor Baru',
      code: 'ESP32-999',
      areaId: 1,
      description: 'tes',
    );

    expect(provider.errorMessage, isNull);
    expect(ok, isTrue);
    expect(requests.single.url.path, endsWith('/sensor/create'));
    expect(jsonDecode(requests.single.body), {
      'name': 'Sensor Baru',
      'code': 'ESP32-999',
      'area_id': 1,
      'description': 'tes',
    });
    expect(provider.sensors.single.id, 11);
    expect(provider.sensors.single.code, 'ESP32-999');
    expect(provider.totalSensors, 1);
  });

  test('createSensor reports a string `errors` field from the API', () async {
    final provider =
        _providerWith((_) async => http.Response(_sensorCreateStringError, 400));

    final ok = await provider.createSensor(name: '', code: '', areaId: 1);

    expect(ok, isFalse);
    expect(provider.errorMessage, "The 'name' field is required.");
    expect(provider.sensors, isEmpty);
  });

  test('createSensor reports a rejected area_id', () async {
    final provider = _providerWith((_) async => http.Response(
      '{"success":false,"message":"The specified area does not exist."}', 400));

    expect(
      await provider.createSensor(name: 'N', code: 'X-2', areaId: 99999),
      isFalse,
    );
    expect(provider.errorMessage, 'The specified area does not exist.');
  });

  test('updateArea posts to /areas/update and stores the response', () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/areas/update')
          ? http.Response(_areaUpdate, 200)
          : http.Response(_areaList, 200),
      seen: requests,
    );
    await provider.fetchAreas();

    final ok = await provider.updateArea(id: 1, name: 'Area Ubah');

    expect(ok, isTrue);
    expect(requests.last.url.path, endsWith('/areas/update'));
    expect(jsonDecode(requests.last.body), {'id': 1, 'name': 'Area Ubah'});
    expect(provider.areas.single.id, 1);
    expect(provider.areas.single.name, 'Area Ubah');
  });

  test('updateArea keeps the locally derived sensor count', () async {
    final provider = _providerWith(
      (req) async {
        if (req.url.path.endsWith('/sensor/list')) {
          return http.Response(_sensorList, 200);
        }
        return http.Response(
          req.url.path.endsWith('/areas/update') ? _areaUpdate : _areaList,
          200,
        );
      },
    );
    await provider.loadAll();
    expect(provider.sensorCountOf(1), 1);

    expect(await provider.updateArea(id: 1, name: 'Area Ubah'), isTrue);
    expect(provider.sensorCountOf(1), 1);
  });

  test('a failing envelope on 200 is still treated as an error', () async {
    final provider = _providerWith(
      (req) async => req.url.path.endsWith('/areas/list')
          ? http.Response(_areaList, 200)
          : http.Response(_areaNotFound, 200),
    );
    await provider.fetchAreas();

    expect(await provider.updateArea(id: 1, name: 'Area Ubah'), isFalse);
    expect(provider.errorMessage, 'area not found');
    expect(provider.areas.single.name, 'Area Uji');
  });

  test('deleteArea drops the area, its sensors and the filter', () async {
    final requests = <http.Request>[];
    final provider = _providerWith(
      (req) async {
        if (req.url.path.endsWith('/sensor/list')) {
          return http.Response(_sensorList, 200);
        }
        if (req.url.path.endsWith('/areas/delete')) {
          return http.Response(_areaDelete, 200);
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
          : http.Response(_areaNotFound, 404),
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
    final provider = _providerWith((_) async => http.Response(
      '{"success":true,"message":"Areas retrieved successfully","data":[]}',
      200,
    ));
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

  testWidgets('Tambah Sensor modal saves through the real UI path',
      (tester) async {
    final requests = <http.Request>[];
    final client = MockClient((req) async {
      requests.add(req);
      if (req.url.path.endsWith('/sensor/create')) {
        return http.Response(_sensorCreate, 201);
      }
      if (req.url.path.endsWith('/sensor/list')) {
        return http.Response(_sensorList, 200);
      }
      return http.Response(_areaList, 200);
    });
    final rpc = RpcClient(baseUrl: 'https://example.test', httpClient: client);
    final provider = AreaProvider(
      areaService: AreaService(rpcClient: rpc),
      sensorService: SensorService(rpcClient: rpc),
    );

    // Providers sit above MaterialApp, as in main.dart, so dialog routes can
    // still read them.
    await tester.pumpWidget(ChangeNotifierProvider<AreaProvider>.value(
      value: provider,
      child: const MaterialApp(home: AreaScreen()),
    ));
    await tester.pumpAndSettle();

    // Switch to the Sensor tab, then open the create modal.
    await tester.tap(find.text('Sensor').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Sensor').last);
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contoh: Sensor Suhu 1'),
        'Sensor Baru');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Contoh: ESP32-001'), 'ESP32-999');
    await tester.pumpAndSettle();

    expect(find.byType(AddSensorModal), findsOneWidget,
        reason: 'create modal should be open');
    expect(find.text('Simpan Sensor'), findsOneWidget,
        reason: 'save button should be present');

    // The modal scrolls; the button can sit below the fold on short screens.
    await tester.ensureVisible(find.text('Simpan Sensor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Sensor'));
    await tester.pumpAndSettle();

    expect(provider.errorMessage, isNull);
    expect(
      requests.any((r) => r.url.path.endsWith('/sensor/create')),
      isTrue,
      reason: 'tapping Simpan Sensor must POST /sensor/create; '
          'paths=${requests.map((r) => r.url.path).toList()} '
          'areas=${provider.areas.length} '
          'pickArea=${find.text("Silakan pilih area terlebih dahulu").evaluate().length} '
          'nameErr=${find.text("Nama sensor tidak boleh kosong").evaluate().length} '
          'codeErr=${find.text("Kode sensor tidak boleh kosong").evaluate().length}',
    );
    expect(find.text('Berhasil menambahkan sensor'), findsOneWidget);
  });

  testWidgets('sensor modal survives an area_id missing from the area list',
      (tester) async {
    // A sensor can reference an area the list does not contain (deleted area,
    // or an area outside the loaded page). DropdownButton asserts when its
    // value has no matching item, which would take the whole screen down.
    final client = MockClient((req) async => http.Response(
          req.url.path.endsWith('/sensor/list') ? _sensorList : _areaListOther,
          200,
        ));
    final rpc = RpcClient(baseUrl: 'https://example.test', httpClient: client);
    final provider = AreaProvider(
      areaService: AreaService(rpcClient: rpc),
      sensorService: SensorService(rpcClient: rpc),
    );
    await provider.loadAll();

    await tester.pumpWidget(ChangeNotifierProvider<AreaProvider>.value(
      value: provider,
      child: MaterialApp(
        home: AddSensorModal(sensor: provider.sensors.single),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Edit Sensor'), findsOneWidget);
  });

  test('a success:false sensor envelope on 200 with string errors is handled',
      () async {
    // Guards ApiResponse against `errors` arriving as a string on a 2xx, which
    // would otherwise throw a cast error instead of showing the message.
    final provider = _providerWith((_) async => http.Response(
          '{"success":false,"message":"Sensor not found.",'
          '"errors":"Sensor not found."}',
          200,
        ));

    expect(
      await provider.updateSensor(
          id: 999999, name: 'X', code: 'Y', areaId: 1),
      isFalse,
    );
    expect(provider.errorMessage, 'Sensor not found.');
  });

  test('watchActivity reads SSE events newest first', () async {
    final seen = <http.Request>[];
    final provider = _providerWith(
      (_) async => http.Response(
        'event:reading\n'
        'data:{"id":1,"sensor_id":9,"sensor_name":"Sensor Tanah","soil_moisture":2512,'
        '"temperature":0,"humidity":0,"recorded_at":"2026-10-30T19:08:56+07:00"}\n\n'
        ': ping\n\n'
        'event:reading\n'
        'data:{"id":2,"sensor_id":8,"sensor_name":"Sensor Cuaca","soil_moisture":0,'
        '"temperature":29.1,"humidity":0,"recorded_at":"2026-10-30T19:09:06+07:00"}\n\n',
        200,
      ),
      seen: seen,
    );

    provider.watchActivity(areaId: 5);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    provider.stopActivity();

    expect(provider.activities.map((a) => a.id), [2, 1]);
    expect(provider.activities.first.temperature, 29.1);
    expect(seen.single.url.path, '/api/sensor-reading/stream');
    expect(jsonDecode(seen.single.body), {'area_id': 5});
  });
}
