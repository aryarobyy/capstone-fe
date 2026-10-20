import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/rpc_client.dart';
import '../models/area_model.dart';

/// Area endpoints answer with bare JSON instead of the standard envelope:
/// - `POST /areas/list`   -> `[{"id":1,"name":"Area Uji"}]`
/// - `POST /areas/create` -> `{"id":1}` (201)
///
/// ponytail: no detail/update/delete here because the backend returns 404 for
/// `/areas/detail|update|delete`. Add them once those routes are deployed.
class AreaService {
  final RpcClient rpcClient;

  AreaService({required this.rpcClient});

  Future<List<AreaModel>> getAreaList() async {
    final decoded = await rpcClient.callRaw(procedure: ApiEndpoints.areaList);

    final list = decoded is List ? decoded : const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(AreaModel.fromJson)
        .toList();
  }

  /// Returns the id of the created area.
  Future<int> createArea({
    required String name,
    String? description,
    String? location,
  }) async {
    final decoded = await rpcClient.callRaw(
      procedure: ApiEndpoints.areaCreate,
      params: {
        'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      },
    );

    if (decoded is Map<String, dynamic> && decoded['id'] is int) {
      return decoded['id'] as int;
    }
    throw const RpcException(
      statusCode: 0,
      message: 'Server tidak mengembalikan id area yang dibuat.',
    );
  }
}
