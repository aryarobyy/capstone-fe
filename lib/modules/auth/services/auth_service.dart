import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/rpc_client.dart';
import '../models/auth_model.dart';

class AuthService {
  final RpcClient rpcClient;

  AuthService({required this.rpcClient});

  Future<ApiResponse<AuthResponseData>> login(LoginRequest request) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.authLogin,
      params: request.toJson(),
    );

    return ApiResponse<AuthResponseData>.fromJson(
      responseMap,
      (data) => AuthResponseData.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Register only creates the account; the backend returns the user
  /// without tokens, so the user still has to log in afterwards.
  Future<ApiResponse<UserAuthModel>> register(RegisterRequest request) async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.authRegister,
      params: request.toJson(),
    );

    return ApiResponse<UserAuthModel>.fromJson(
      responseMap,
      (data) => UserAuthModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<({String accessToken, String refreshToken})> refresh(
    String refreshToken,
  ) async {
    final res = await rpcClient.call(
      procedure: ApiEndpoints.authRefresh,
      params: {'refresh_token': refreshToken},
    );
    final data = res['data'];
    final access = data is Map ? data['access_token'] : null;
    final next = data is Map ? data['refresh_token'] : null;
    if (access is! String || access.isEmpty || next is! String || next.isEmpty) {
      throw const RpcException(
        statusCode: 0,
        message: 'Respons refresh token tidak valid.',
      );
    }
    return (accessToken: access, refreshToken: next);
  }

  Future<ApiResponse<void>> logout() async {
    final responseMap = await rpcClient.call(
      procedure: ApiEndpoints.authLogout,
      params: {},
    );

    return ApiResponse<void>.fromJson(responseMap, null);
  }
}
