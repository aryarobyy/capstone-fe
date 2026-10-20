import 'package:flutter/foundation.dart';
import '../../../core/network/rpc_client.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService authService;
  final RpcClient rpcClient;

  AuthProvider({required this.authService, required this.rpcClient});

  bool _isLoading = false;
  String? _errorMessage;
  String? _accessToken;
  String? _refreshToken;
  UserAuthModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  UserAuthModel? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  void setToken(String? token, {String? refreshToken}) {
    _accessToken = token;
    _refreshToken = refreshToken;
    rpcClient.token = token;
    notifyListeners();
  }

  void setCurrentUser(UserAuthModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void devBypassLogin() {
    _accessToken = 'mock_dev_token';
    rpcClient.token = _accessToken;
    _currentUser = const UserAuthModel(
      id: 999,
      name: 'Petani Cerdas (Demo)',
      email: 'demo@tanipintar.com',
    );
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await authService.login(
        LoginRequest(email: email, password: password),
      );

      if (response.success && response.data != null) {
        _accessToken = response.data!.accessToken;
        _refreshToken = response.data!.refreshToken;
        rpcClient.token = _accessToken;
        _currentUser = response.data!.user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.errors.isNotEmpty
            ? '${response.message} ${response.errors.join(", ")}'
            : response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String msisdn,
    String password,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await authService.register(
        RegisterRequest(
          name: name,
          email: email,
          msisdn: msisdn,
          password: password,
        ),
      );

      _isLoading = false;

      if (response.success) {
        // Backend issues no token on register; user logs in separately.
        _currentUser = response.data;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.errors.isNotEmpty
            ? '${response.message} ${response.errors.join(", ")}'
            : response.message;
        notifyListeners();
        return false;
      }
    } on RpcException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan tidak terduga: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.logout();
    } catch (_) {
    } finally {
      _accessToken = null;
      _refreshToken = null;
      rpcClient.token = null;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }

    return true;
  }
}
