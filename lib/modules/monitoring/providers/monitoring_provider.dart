import 'package:flutter/foundation.dart';
import '../../../core/network/rpc_client.dart';
import '../models/alert_rule_model.dart';
import '../models/sensor_reading_model.dart';
import '../services/monitoring_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final MonitoringService monitoringService;

  MonitoringProvider({required this.monitoringService});

  bool _isLoading = false;
  bool _isGeneratingKey = false;
  bool _isSavingRule = false;
  String? _errorMessage;

  int? _selectedSensorId;
  List<SensorReadingModel> _readings = [];
  String? _generatedSensorKey;
  List<AlertRuleModel> _alertRules = [];

  bool get isLoading => _isLoading;
  bool get isGeneratingKey => _isGeneratingKey;
  bool get isSavingRule => _isSavingRule;
  String? get errorMessage => _errorMessage;

  int? get selectedSensorId => _selectedSensorId;
  List<SensorReadingModel> get readings => _readings;
  SensorReadingModel? get latestReading => _readings.isNotEmpty ? _readings.first : null;
  String? get generatedSensorKey => _generatedSensorKey;
  List<AlertRuleModel> get alertRules => _alertRules;

  void selectSensor(int sensorId) {
    _selectedSensorId = sensorId;
    _readings = [];
    _generatedSensorKey = null;
    notifyListeners();
    fetchReadings(sensorId: sensorId);
    fetchAlertRules(sensorId);
  }

  void clearGeneratedKey() {
    _generatedSensorKey = null;
    notifyListeners();
  }

  Future<void> fetchReadings({
    required int sensorId,
    String? date,
    int limit = 50,
    int index = 0,
  }) async {
    _selectedSensorId = sensorId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await monitoringService.getSensorReadings(
        sensorId: sensorId,
        date: date,
        limit: limit,
        index: index,
      );

      if (response.success && response.data != null) {
        _readings = response.data!.data;
      } else {
        _errorMessage = response.message;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
    } catch (e) {
      _errorMessage = 'Gagal mengambil bacaan sensor: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateKey(int sensorId) async {
    _isGeneratingKey = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await monitoringService.generateSensorKey(sensorId);
      _generatedSensorKey = response.sensorKey;
      _isGeneratingKey = false;
      notifyListeners();
      return response.sensorKey;
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      _isGeneratingKey = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Gagal men-generate sensor key: $e';
      _isGeneratingKey = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchAlertRules(int sensorId) async {
    try {
      final response = await monitoringService.getAlertRules(sensorId);
      if (response.success && response.data != null) {
        _alertRules = response.data!;
        notifyListeners();
      }
    } catch (_) {
    }
  }

  Future<bool> saveAlertRule(AlertRuleModel rule) async {
    _isSavingRule = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await monitoringService.saveAlertRule(rule);
      if (response.success && response.data != null) {
        final idx = _alertRules.indexWhere((r) => r.parameter == rule.parameter);
        if (idx >= 0) {
          _alertRules[idx] = response.data!;
        } else {
          _alertRules.add(response.data!);
        }
        _isSavingRule = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isSavingRule = false;
        notifyListeners();
        return false;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      _isSavingRule = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Gagal menyimpan aturan alarm: $e';
      _isSavingRule = false;
      notifyListeners();
      return false;
    }
  }
}
