import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/rpc_client.dart';
import '../models/area_model.dart';

/// Area endpoints are RPC-over-POST and all answer with the standard
/// `{success, message, data}` envelope. An area carries only `id` and `name`.
class AreaService {
  final RpcClient rpcClient;

  AreaService({required this.rpcClient});

  /// Unwraps the envelope, turning `success: false` into an exception so a
  /// failed write can never be mistaken for a successful one.
  Future<dynamic> _data({
    required String procedure,
    Map<String, dynamic>? params,
    required String onFailure,
  }) async {
    final response = await rpcClient.call(
      procedure: procedure,
      params: params,
    );

    if (response['success'] != true) {
      throw RpcException(
        statusCode: 0,
        message: response['message'] as String? ?? onFailure,
      );
    }
    return response['data'];
  }

  Future<List<AreaModel>> getAreaList() async {
    final data = await _data(
      procedure: ApiEndpoints.areaList,
      onFailure: 'Gagal memuat area.',
    );

    // An empty list is serialised as null by the backend.
    if (data == null) return [];
    // Report a malformed list instead of silently dropping entries.
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

  Future<AreaModel> getAreaDetail(int id) async {
    final data = await _data(
      procedure: ApiEndpoints.areaDetail,
      params: {'id': id},
      onFailure: 'Gagal memuat detail area.',
    );
    return _area(data, 'Detail area dari server tidak valid.');
  }

  Future<AreaModel> createArea({required String name}) async {
    final data = await _data(
      procedure: ApiEndpoints.areaCreate,
      params: {'name': name},
      onFailure: 'Gagal menambahkan area.',
    );
    return _area(data, 'Server tidak mengembalikan area yang dibuat.');
  }

  Future<AreaModel> updateArea({
    required int id,
    required String name,
  }) async {
    final data = await _data(
      procedure: ApiEndpoints.areaUpdate,
      params: {'id': id, 'name': name},
      onFailure: 'Gagal memperbarui area.',
    );
    return _area(data, 'Server tidak mengembalikan area yang diperbarui.');
  }

  /// Delete replies without a `data` field, so there is nothing to return.
  Future<void> deleteArea(int id) async {
    await _data(
      procedure: ApiEndpoints.areaDelete,
      params: {'id': id},
      onFailure: 'Gagal menghapus area.',
    );
  }

  AreaModel _area(dynamic data, String onInvalid) {
    if (data is Map<String, dynamic> && data['id'] is int) {
      return AreaModel.fromJson(data);
    }
    throw RpcException(statusCode: 0, message: onInvalid);
  }
}
