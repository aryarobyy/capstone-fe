import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/rpc_client.dart';
import '../models/area_model.dart';

/// Accepts both the API response envelope and older bare area responses.
/// BE `/areas/update` only stores `name`; description/location are ignored.
class AreaService {
  final RpcClient rpcClient;

  AreaService({required this.rpcClient});

  Future<List<AreaModel>> getAreaList() async {
    final response = await rpcClient.call(procedure: ApiEndpoints.areaList);

    if (response['success'] != true) {
      throw RpcException(
        statusCode: 0,
        message: response['message'] as String? ?? 'Gagal memuat area.',
      );
    }
    // Empty slices are omitted by the deployed API's JSON envelope.
    final data = response['data'];
    if (data == null) return [];
    if (data is! List || data.any((item) => item is! Map<String, dynamic>)) {
      throw const RpcException(
        statusCode: 0,
        message: 'Format daftar area dari server tidak valid.',
      );
    }
    return data
        .map((item) => AreaModel.fromJson(item as Map<String, dynamic>))
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

    final area = decoded is Map<String, dynamic> &&
            decoded['data'] is Map<String, dynamic>
        ? decoded['data'] as Map<String, dynamic>
        : decoded;
    if (area is Map<String, dynamic> && area['id'] is int) {
      return area['id'] as int;
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
    await rpcClient.callRaw(
      procedure: ApiEndpoints.areaUpdate,
      params: {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
      },
    );
  }

  Future<void> deleteArea(int id) async {
    await rpcClient.callRaw(
      procedure: ApiEndpoints.areaDelete,
      params: {'id': id},
    );
  }
}
