import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/auth/providers/auth_provider.dart';
import 'modules/auth/views/login_view.dart';
import 'modules/auth/views/register_view.dart';
import 'modules/auth/views/splash_view.dart';
import 'modules/navigation/views/main_screen.dart';
import 'utils/app_providers.dart';
import 'utils/colorScheme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

final _navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  final String baseUrl;

  const MyApp({
    super.key,
    this.baseUrl = AppProviders.defaultBaseUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: AppProviders.buildProviders(
        baseUrl: baseUrl,
      ),
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        builder: (context, child) {
          context.read<AuthProvider>().onSessionExpired = () => _navigatorKey
              .currentState
              ?.pushNamedAndRemoveUntil(LoginView.routeName, (_) => false);
          return child!;
        },
        title: 'TaniPintar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: SplashView.routeName,
        routes: {
          SplashView.routeName: (_) => const SplashView(),
          LoginView.routeName: (_) => const LoginView(),
          RegisterView.routeName: (_) => const RegisterView(),
          '/main': (_) => const MainScreen(),
        },
      ),
    );
  }
}
