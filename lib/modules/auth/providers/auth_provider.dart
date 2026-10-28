import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/rpc_client.dart';
import '../../../core/notifications/push_service.dart';
import '../models/auth_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  /// BE access token lives 15 min.
  static const defaultRefreshInterval = Duration(minutes: 14, seconds: 59);
  static const _retryDelay = Duration(seconds: 30);
  static const _kRefresh = 'refresh_token';
  static const _kUser = 'user';
  // Per-install, not per-user: survives logout on purpose.
  static const _kInstallation = 'installation_id';

  final AuthService authService;
  final RpcClient rpcClient;

  final Future<DeviceRegistration?> Function()? deviceRegistration;
  final FlutterSecureStorage? storage;
  final Duration refreshInterval;

  Timer? _timer;
  bool _restoring = false;

  AuthProvider({
    required this.authService,
    required this.rpcClient,
    this.deviceRegistration,
    this.storage,
    this.refreshInterval = defaultRefreshInterval,
  }) {
    rpcClient.onUnauthorized = _refreshSession;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleRefresh([Duration? after]) {
    _timer?.cancel();
    _timer = Timer(after ?? refreshInterval, _refreshSession);
  }

  Future<void> _persist() async {
    final s = storage;
    final refresh = _refreshToken;
    final user = _currentUser;
    if (s == null || refresh == null || user == null) return;
    try {
      await s.write(key: _kRefresh, value: refresh);
      await s.write(key: _kUser, value: jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _clearStored() async {
    try {
      await storage?.delete(key: _kRefresh);
      await storage?.delete(key: _kUser);
    } catch (_) {}
  }

  Future<bool> restoreSession() async {
    final s = storage;
    if (s == null) return false;
    String? refresh;
    UserAuthModel? user;
    try {
      refresh = await s.read(key: _kRefresh);
      final raw = await s.read(key: _kUser);
      if (raw != null) {
        user = UserAuthModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      return false;
    }
    if (refresh == null || refresh.isEmpty || user == null) return false;

    _refreshToken = refresh;
    _currentUser = user;
    _restoring = true;
    try {
      if (await _refreshSession() != null) return true;
    } finally {
      _restoring = false;
    }

    _timer?.cancel();
    _refreshToken = null;
    _currentUser = null;
    notifyListeners();
    return false;
  }

  VoidCallback? onSessionExpired;

  // Refresh tokens are single-use: concurrent callers share one request.
  Future<String?>? _refreshing;

  Future<String?> _refreshSession() =>
      _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _doRefresh() async {
    final current = _refreshToken;
    if (current == null || current.isEmpty) {
      if (_accessToken != null) _expireSession();
      return null;
    }
    try {
      final next = await authService.refresh(current);
      if (_refreshToken != current) return null;
      _accessToken = next.accessToken;
      _refreshToken = next.refreshToken;
      rpcClient.token = next.accessToken;
      await _persist();
      _scheduleRefresh();
      notifyListeners();
      return next.accessToken;
    } on RpcException catch (e) {
      if (_refreshToken != current) return null;
      if (e.statusCode >= 400 && e.statusCode < 500) {
        _expireSession();
      } else {
        _scheduleRefresh(_retryDelay);
      }
      return null;
    } catch (_) {
      if (_refreshToken == current) _scheduleRefresh(_retryDelay);
      return null;
    }
  }

  void _expireSession() {
    _timer?.cancel();
    unawaited(_clearStored());
    _accessToken = null;
    _refreshToken = null;
    rpcClient.token = null;
    _currentUser = null;
    notifyListeners();
    if (!_restoring) onSessionExpired?.call();
  }

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

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      DeviceRegistration? device;
      try {
        device = await deviceRegistration?.call();
      } catch (_) {
      }
      String? installationId;
      try {
        installationId = await storage?.read(key: _kInstallation);
      } catch (_) {}
      final response = await authService.login(
        LoginRequest(
          email: email,
          password: password,
          deviceToken: device?.token,
          deviceType: device?.type,
          installationId: installationId,
        ),
      );

      if (response.success && response.data != null) {
        final newInstallation = response.data!.installationId;
        if (newInstallation != null && newInstallation != installationId) {
          try {
            await storage?.write(key: _kInstallation, value: newInstallation);
          } catch (_) {}
        }
        if (!response.data!.deviceTokenRegistered) {
          debugPrint('Login OK but device not registered for push '
              '(token sent: ${device != null}).');
        }
        _accessToken = response.data!.accessToken;
        _refreshToken = response.data!.refreshToken;
        rpcClient.token = _accessToken;
        _currentUser = response.data!.user;
        _isLoading = false;
        await _persist();
        _scheduleRefresh();
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
      _timer?.cancel();
      await _clearStored();
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
