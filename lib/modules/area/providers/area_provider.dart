import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../../core/network/rpc_client.dart';
import '../models/area_model.dart';
import '../models/sensor_activity_model.dart';
import '../models/sensor_model.dart';
import '../services/area_service.dart';
import '../services/sensor_service.dart';

class AreaProvider extends ChangeNotifier {
  final AreaService areaService;
  final SensorService sensorService;

  AreaProvider({
    required this.areaService,
    required this.sensorService,
  });

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  List<AreaModel> _areas = [];
  int _totalAreas = 0;

  List<SensorModel> _sensors = [];
  SensorModel? _selectedSensor;
  int _totalSensors = 0;

  /// `null` means "Semua Area" (no server-side filter).
  int? _sensorAreaFilter;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isDeleting => _isDeleting;
  String? get errorMessage => _errorMessage;

  List<AreaModel> get areas => _areas;
  int get totalAreas => _totalAreas;

  List<SensorModel> get sensors => _sensors;
  SensorModel? get selectedSensor => _selectedSensor;
  int get totalSensors => _totalSensors;
  int? get sensorAreaFilter => _sensorAreaFilter;

  /// Readable area name by id, for the tag on sensor cards.
  String areaNameOf(int areaId) {
    final area = _areas.firstWhere(
      (a) => a.id == areaId,
      orElse: () => AreaModel(id: areaId, name: ''),
    );
    return area.name.isNotEmpty ? area.name : 'Area $areaId';
  }

  /// Sensors loaded for an area. Only complete while no area filter is active,
  /// since the backend paginates sensors per area.
  int sensorCountOf(int areaId) =>
      _sensors.where((s) => s.areaId == areaId).length;

  void selectSensor(SensorModel? sensor) {
    _selectedSensor = sensor;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads areas and sensors together, the state the area screen needs.
  Future<void> loadAll() async {
    if (!await fetchAreas()) return;
    await fetchSensors(areaId: _sensorAreaFilter);
  }

  Future<bool> fetchAreas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _areas = await areaService.getAreaList();
      _totalAreas = _areas.length;
      return true;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal memuat data lahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createArea({
    required String name,
    String? description,
    String? location,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final id = await areaService.createArea(
        name: name,
        description: description,
        location: location,
      );

      // Create only returns the id, so insert locally with what we sent.
      _areas.insert(
        0,
        AreaModel(
          id: id,
          name: name,
          description: description,
          location: location,
        ),
      );
      _totalAreas++;
      return true;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menambahkan lahan: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// `/areas/update` returns no body, so the local area is patched with the
  /// values we just sent once the server accepts them.
  Future<bool> updateArea({
    required int id,
    required String name,
    String? description,
    String? location,
  }) async {
    final idx = _areas.indexWhere((a) => a.id == id);
    if (idx < 0) {
      _errorMessage = 'Area tidak ditemukan.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await areaService.updateArea(
        id: id,
        name: name,
        description: description,
        location: location,
      );

      _areas[idx] = _areas[idx].copyWith(
        name: name,
        description: description,
        location: location,
      );
      return true;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui lahan: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteArea(int id) async {
    if (!_areas.any((a) => a.id == id)) {
      _errorMessage = 'Area tidak ditemukan.';
      notifyListeners();
      return false;
    }

    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await areaService.deleteArea(id);

      _areas.removeWhere((a) => a.id == id);
      _totalAreas = _areas.length;
      // Sensors of a removed area must not stay on screen or in the filter.
      _sensors.removeWhere((s) => s.areaId == id);
      _totalSensors = _sensors.length;
      if (_sensorAreaFilter == id) {
        _sensorAreaFilter = null;
      }
      return true;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menghapus lahan: $e';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> fetchSensors({int? areaId, int limit = 20, int index = 0}) async {
    _sensorAreaFilter = areaId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await sensorService.getSensorList(
        areaId: areaId,
        limit: limit,
        index: index,
      );

      if (response.success && response.data != null) {
        _sensors = response.data!.data;
        _totalSensors = response.data!.total;
      } else {
        _errorMessage = _messageOf(response.message, response.errors);
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
    } catch (e) {
      _errorMessage = 'Gagal memuat sensor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSensor({
    required String name,
    required String code,
    required int areaId,
    String? description,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await sensorService.createSensor(
        name: name,
        code: code,
        areaId: areaId,
        description: description,
      );

      if (response.success && response.data != null) {
        // Respect the active filter: a new sensor outside it stays hidden.
        if (_sensorAreaFilter == null || _sensorAreaFilter == areaId) {
          _sensors.insert(0, response.data!);
          _totalSensors++;
        }
        return true;
      }
      _errorMessage = _messageOf(response.message, response.errors);
      return false;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal mendaftarkan sensor: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateSensor({
    required int id,
    required String name,
    required String code,
    required int areaId,
    String? description,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await sensorService.updateSensor(
        id: id,
        name: name,
        code: code,
        areaId: areaId,
        description: description,
      );

      if (response.success && response.data != null) {
        final idx = _sensors.indexWhere((s) => s.id == id);
        if (idx >= 0) {
          _sensors[idx] = response.data!;
        }
        if (_selectedSensor?.id == id) {
          _selectedSensor = response.data;
        }
        // Moved out of the active filter -> drop it from the visible list.
        if (_sensorAreaFilter != null && _sensorAreaFilter != areaId) {
          _sensors.removeWhere((s) => s.id == id);
        }
        return true;
      }
      _errorMessage = _messageOf(response.message, response.errors);
      return false;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui sensor: $e';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSensor(int id) async {
    _isDeleting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await sensorService.deleteSensor(id);
      if (response.success) {
        _sensors.removeWhere((s) => s.id == id);
        _totalSensors = (_totalSensors - 1).clamp(0, _totalSensors);
        if (_selectedSensor?.id == id) {
          _selectedSensor = null;
        }
        return true;
      }
      _errorMessage = _messageOf(response.message, response.errors);
      return false;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menghapus sensor: $e';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  String _messageOf(String message, List<String> errors) =>
      errors.isEmpty ? message : '$message ${errors.join(", ")}';

  static const _maxActivities = 50;
  List<SensorActivityModel> _activities = [];
  StreamSubscription<SensorActivityModel>? _activitySub;
  Timer? _activityRetry;

  /// Live sensor readings, newest first.
  List<SensorActivityModel> get activities => _activities;

  /// Starts the live feed for [areaId] (null = all areas), replacing any previous one.
  void watchActivity({int? areaId}) {
    stopActivity();
    _activities = [];
    notifyListeners();
    _connectActivity(areaId);
  }

  void _connectActivity(int? areaId) {
    _activitySub = sensorService.watchActivity(areaId: areaId).listen(
      (activity) {
        // A reconnect replays the backlog, so skip readings already shown.
        if (_activities.any((a) => a.id == activity.id)) return;
        _activities = ([activity, ..._activities]
              ..sort((a, b) => b.id.compareTo(a.id)))
            .take(_maxActivities)
            .toList();
        notifyListeners();
      },
      onError: (_) => _retryActivity(areaId),
      onDone: () => _retryActivity(areaId),
      cancelOnError: true,
    );
  }

  void _retryActivity(int? areaId) {
    _activitySub = null;
    _activityRetry = Timer(
      const Duration(seconds: 3),
      () => _connectActivity(areaId),
    );
  }

  void stopActivity() {
    _activityRetry?.cancel();
    _activityRetry = null;
    _activitySub?.cancel();
    _activitySub = null;
  }

  @override
  void dispose() {
    stopActivity();
    super.dispose();
  }
}
