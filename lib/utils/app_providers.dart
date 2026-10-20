import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../core/network/rpc_client.dart';
import '../core/notifications/push_service.dart';
import '../modules/area/providers/area_provider.dart';
import '../modules/area/services/area_service.dart';
import '../modules/area/services/sensor_service.dart';
import '../modules/auth/providers/auth_provider.dart';
import '../modules/auth/services/auth_service.dart';
import '../modules/home/providers/home_provider.dart';
import '../modules/home/services/home_service.dart';
import '../modules/monitoring/providers/monitoring_provider.dart';
import '../modules/monitoring/services/monitoring_service.dart';
import '../modules/navigation/providers/navigation_provider.dart';
import '../modules/profile/providers/profile_provider.dart';
import '../modules/profile/services/profile_service.dart';
import '../modules/riwayat/providers/history_provider.dart';
import '../modules/riwayat/services/history_service.dart';

class AppProviders {
  AppProviders._();

  /// Base URL of the TaniPintar API. Override at build time with
  /// `flutter run --dart-define=API_BASE_URL=http://localhost:8000`.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://arifingaybanget.cipicung.id',
  );

  static List<SingleChildWidget> buildProviders({
    String baseUrl = defaultBaseUrl,
    Future<String?> Function()? getToken,
    RpcClient? client,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) {
    final rpcClient = client ??
        RpcClient(
          baseUrl: baseUrl,
          getToken: getToken,
        );

    final authService = AuthService(rpcClient: rpcClient);
    final homeService = HomeService(rpcClient: rpcClient);
    final historyService = HistoryService(rpcClient: rpcClient);
    final monitoringService = MonitoringService(rpcClient: rpcClient);
    final areaService = AreaService(rpcClient: rpcClient);
    final sensorService = SensorService(rpcClient: rpcClient);
    final profileService = ProfileService(rpcClient: rpcClient);

    return [
      Provider<RpcClient>.value(value: rpcClient),
      Provider<AuthService>.value(value: authService),
      Provider<HomeService>.value(value: homeService),
      Provider<HistoryService>.value(value: historyService),
      Provider<MonitoringService>.value(value: monitoringService),
      Provider<AreaService>.value(value: areaService),
      Provider<SensorService>.value(value: sensorService),
      Provider<ProfileService>.value(value: profileService),

      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(
          authService: authService,
          rpcClient: rpcClient,
          deviceRegistration: fetchDeviceRegistration,
          storage: storage,
        ),
      ),
      ChangeNotifierProvider<HomeProvider>(
        create: (_) => HomeProvider(homeService: homeService),
      ),
      ChangeNotifierProvider<HistoryProvider>(
        create: (_) => HistoryProvider(historyService: historyService),
      ),
      ChangeNotifierProvider<MonitoringProvider>(
        create: (_) => MonitoringProvider(monitoringService: monitoringService),
      ),
      ChangeNotifierProvider<AreaProvider>(
        create: (_) => AreaProvider(
          areaService: areaService,
          sensorService: sensorService,
        ),
      ),
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(profileService: profileService),
      ),
    ];
  }
}
