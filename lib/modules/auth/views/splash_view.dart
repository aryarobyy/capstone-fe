import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../providers/auth_provider.dart';
import 'login_view.dart';

/// Entry route: restores a persisted session, then redirects to either
/// the main shell or the login screen.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  static const String routeName = '/';

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decideNextRoute());
  }

  Future<void> _decideNextRoute() async {
    bool restored = false;
    try {
      restored = await context.read<AuthProvider>().restoreSession();
    } catch (_) {
      // A broken/expired stored session must not trap the user on the splash
      // screen; fall through to login.
      restored = false;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      restored ? '/main' : LoginView.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.eco, size: 44, color: AppColors.primary),
            ),
            SizedBox(height: 20),
            Text(
              'TaniPintar',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
