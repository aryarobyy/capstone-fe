import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/rpc_client.dart';
import '../../riwayat/models/history_item_model.dart';
import '../../area/services/area_service.dart';
import '../models/home_dashboard_model.dart';

/// ponytail: the server has no dashboard endpoint, so this fans out to the
/// list endpoints (7 small calls). Swap for one call if `/dashboard/summary`
/// ever ships.
class HomeService {
  final RpcClient rpcClient;

  HomeService({required this.rpcClient});

  static const _activeStatuses = ['FATAL', 'CRITICAL', 'WARNING'];

  Future<HomeDashboardModel> getDashboardSummary() async {
    final now = DateTime.now();
    final today = '${now.year}-${_two(now.month)}-${_two(now.day)}';

    final r = await Future.wait<Object>([
      _areaCount(),
      _page(ApiEndpoints.sensorList, {'limit': 1}, (j) => j),
      _history({'date': today, 'limit': 1}),
      _history({'limit': 5}),
      for (final s in _activeStatuses) _history({'status': s, 'limit': 1}),
    ]);

    return HomeDashboardModel(
      totalAreas: r[0] as int,
      totalSensors: (r[1] as PaginatedData).total,
      totalAnomaliesToday: (r[2] as PaginatedData).total,
      recentEvents: (r[3] as PaginatedData<HistoryItemModel>).data,
      activeAnomalies:
          r.skip(4).fold(0, (sum, p) => sum + (p as PaginatedData).total),
    );
  }

  Future<int> _areaCount() async =>
      (await AreaService(rpcClient: rpcClient).getAreaList()).length;

  Future<PaginatedData<HistoryItemModel>> _history(Map<String, dynamic> params) =>
      _page(ApiEndpoints.historyList, params, HistoryItemModel.fromJson);

  Future<PaginatedData<T>> _page<T>(
    String procedure,
    Map<String, dynamic> params,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final res = await rpcClient.call(procedure: procedure, params: params);
    final data = res['data'];
    if (data is! Map<String, dynamic>) {
      throw RpcException(
        statusCode: 0,
        message: 'Respons $procedure tidak valid.',
      );
    }
    return PaginatedData<T>.fromJson(data, fromJson);
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
