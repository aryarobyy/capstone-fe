import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/rpc_client.dart';
import '../models/history_filter_params.dart';
import '../models/history_item_model.dart';

class HistoryService {
  final RpcClient rpcClient;

  HistoryService({required this.rpcClient});

  /// Anomalies matching [params] recorded after [afterId]; 0 means from now.
  Stream<HistoryItemModel> watchNew(HistoryFilterParams params, {int afterId = 0}) =>
      rpcClient
          .stream(
            procedure: ApiEndpoints.historyStream,
            params: {...params.toJson(), 'after_id': afterId},
          )
          .map(HistoryItemModel.fromJson);

  Future<ApiResponse<PaginatedData<HistoryItemModel>>> getHistoryList(
    HistoryFilterParams params,
  ) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.historyList,
      params: params.toJson(),
    );

    return ApiResponse<PaginatedData<HistoryItemModel>>.fromJson(
      responseMap,
      (data) => PaginatedData<HistoryItemModel>.fromJson(
        data as Map<String, dynamic>,
        (item) => HistoryItemModel.fromJson(item),
      ),
    );
  }

  Future<ApiResponse<HistoryItemModel>> getHistoryDetail(int id) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.historyDetail,
      params: {'id': id},
    );

    return ApiResponse<HistoryItemModel>.fromJson(
      responseMap,
      (data) => HistoryItemModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<void>> deleteHistory(int id) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.historyDelete,
      params: {'id': id},
    );

    return ApiResponse<void>.fromJson(responseMap, null);
  }
}
