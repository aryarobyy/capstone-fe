import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/rpc_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  final RpcClient rpcClient;

  NotificationService({required this.rpcClient});

  /// Newest first, 50 per call. Pass the smallest id seen as [beforeId] for older ones.
  Future<ApiResponse<List<NotificationModel>>> list({int beforeId = 0}) async {
    final map = await rpcClient.call(
      procedure: ApiEndpoints.notificationList,
      params: {'before_id': beforeId},
    );
    return ApiResponse<List<NotificationModel>>.fromJson(
      map,
      (data) => (data as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<ApiResponse<void>> markRead(int id) async {
    final map = await rpcClient.call(
      procedure: ApiEndpoints.notificationRead,
      params: {'id': id},
    );
    return ApiResponse<void>.fromJson(map, null);
  }
}
