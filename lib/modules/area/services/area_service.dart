import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/rpc_client.dart';
import '../models/area_model.dart';

/// Area endpoints answer with bare JSON instead of the standard envelope:
/// - `POST /areas/list`   -> `[{"id":1,"name":"Area Uji"}]`
/// - `POST /areas/create` -> `{"id":1}` (201)
///
/// ponytail: no detail endpoint here, `/areas/detail` still returns 404.
/// `updateArea`/`deleteArea` post to the real routes but those answer 404 as
/// well today, so a 404 is translated into a clear "belum tersedia" message
/// instead of a generic server error.
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

  Future<void> updateArea({
    required int id,
    required String name,
    String? description,
    String? location,
  }) async {
    try {
      await rpcClient.callRaw(
        procedure: ApiEndpoints.areaUpdate,
        params: {
          'id': id,
          'name': name,
          if (description != null) 'description': description,
          if (location != null) 'location': location,
        },
      );
    } on RpcException catch (e) {
      throw _notDeployed(e, 'Ubah area belum tersedia di server.');
    }
  }

  Future<void> deleteArea(int id) async {
    try {
      await rpcClient.callRaw(
        procedure: ApiEndpoints.areaDelete,
        params: {'id': id},
      );
    } on RpcException catch (e) {
      throw _notDeployed(e, 'Hapus area belum tersedia di server.');
    }
  }

  RpcException _notDeployed(RpcException e, String message) =>
      e.statusCode == 404 ? RpcException(statusCode: 404, message: message) : e;
}
