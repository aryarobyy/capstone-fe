import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/rpc_client.dart';
import '../models/alert_rule_model.dart';
import '../models/sensor_key_response.dart';
import '../models/sensor_reading_model.dart';

class MonitoringService {
  final RpcClient rpcClient;

  MonitoringService({required this.rpcClient});

  Future<ApiResponse<PaginatedData<SensorReadingModel>>> getSensorReadings({
    required int sensorId,
    String? date,
    int limit = 50,
    int index = 0,
  }) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.sensorReadingList,
      params: {
        'sensor_id': sensorId,
        if (date != null && date.isNotEmpty) 'date': date,
        'limit': limit,
        'index': index,
      },
    );

    return ApiResponse<PaginatedData<SensorReadingModel>>.fromJson(
      responseMap,
      (data) => PaginatedData<SensorReadingModel>.fromJson(
        data as Map<String, dynamic>,
        (item) => SensorReadingModel.fromJson(item),
      ),
    );
  }

  Future<ApiResponse<SensorReadingModel>> getSensorReadingDetail(int id) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.sensorReadingDetail,
      params: {'id': id},
    );

    return ApiResponse<SensorReadingModel>.fromJson(
      responseMap,
      (data) => SensorReadingModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<SensorKeyResponse> generateSensorKey(int sensorId) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.sensorsKey,
      params: {'sensor_id': sensorId},
    );

    return SensorKeyResponse.fromJson(responseMap);
  }

  Future<ApiResponse<List<AlertRuleModel>>> getAlertRules(int sensorId) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.alertRuleList,
      params: {'sensor_id': sensorId},
    );

    return ApiResponse<List<AlertRuleModel>>.fromJson(
      {...responseMap, 'data': responseMap['data'] ?? <dynamic>[]},
      (data) {
        final list = (data is List) ? data : (data['data'] as List? ?? []);
        return list
            .map((item) => AlertRuleModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// BE answers 204 with no body, so the saved rule is the one we sent.
  Future<ApiResponse<AlertRuleModel>> saveAlertRule(AlertRuleModel rule) async {
    await rpcClient.callRaw(
      procedure: ApiEndpoints.alertRuleSave,
      params: rule.toJson(),
    );
    return ApiResponse(success: true, message: '', data: rule);
  }
}
