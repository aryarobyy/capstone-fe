import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tanipintar/core/network/api_response.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/auth/models/auth_model.dart';
import 'package:tanipintar/modules/auth/providers/auth_provider.dart';
import 'package:tanipintar/modules/auth/services/auth_service.dart';
import 'package:tanipintar/modules/auth/views/login_view.dart';
import 'package:tanipintar/modules/auth/views/register_view.dart';
import 'package:tanipintar/utils/colorScheme.dart';

class MockAuthService extends AuthService {
  MockAuthService() : super(rpcClient: RpcClient(baseUrl: 'http://mock'));

  bool shouldSucceed = true;
  String? mockErrorMessage;

  @override
  Future<ApiResponse<AuthResponseData>> login(LoginRequest request) async {
    if (shouldSucceed) {
      return ApiResponse<AuthResponseData>(
        success: true,
        message: 'Berhasil masuk',
        data: AuthResponseData(
          accessToken: 'mock_token',
          user: UserAuthModel(id: 1, name: 'Petani Uji', email: request.email),
        ),
      );
    } else {
      return ApiResponse<AuthResponseData>(
        success: false,
        message: mockErrorMessage ?? 'Email atau kata sandi salah',
      );
    }
  }

  @override
  Future<ApiResponse<UserAuthModel>> register(RegisterRequest request) async {
    if (shouldSucceed) {
      return ApiResponse<UserAuthModel>(
        success: true,
        message: 'Registrasi berhasil',
        data: UserAuthModel(
          id: 1,
          name: request.name,
          email: request.email,
          msisdn: request.msisdn,
        ),
      );
    } else {
      return ApiResponse<UserAuthModel>(
        success: false,
        message: mockErrorMessage ?? 'Email sudah terdaftar',
      );
    }
  }
}

void main() {
  late MockAuthService mockAuthService;
  late AuthProvider authProvider;

  setUp(() {
    mockAuthService = MockAuthService();
    authProvider = AuthProvider(
      authService: mockAuthService,
      rpcClient: mockAuthService.rpcClient,
    );
  });

  Widget buildTestApp(Widget child) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
        // Login/register redirect here on success; stub it so the harness
        // doesn't need the real MainScreen.
        routes: {'/main': (_) => const Scaffold()},
      ),
    );
  }

  group('RegisterView Tests', () {
    testWidgets('Renders all required elements per authGuide.md', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const RegisterView()));
      await tester.pumpAndSettle();

      // Top nav
      expect(find.text('Kembali'), findsOneWidget);

      // Header badge and title
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      expect(find.text('Daftar Akun Baru'), findsOneWidget);

      // Form labels
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Nomor HP / WhatsApp'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);

      // Button and footer
      expect(find.text('Daftar Sekarang'), findsOneWidget);
      expect(find.text('Sudah punya akun? '), findsOneWidget);
      expect(find.text('Masuk di sini'), findsOneWidget);
    });

    testWidgets('Validates required fields when submitted empty', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const RegisterView()));
      await tester.pumpAndSettle();

      // Tap submit button without inputting data
      await tester.ensureVisible(find.text('Daftar Sekarang'));
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Nama lengkap wajib diisi'), findsOneWidget);
      expect(find.text('Alamat email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('Submits registration with RegisterRequest data', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const RegisterView()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(5));

      // Fill in fields
      await tester.enterText(textFields.at(0), 'Pak Tani');
      await tester.enterText(textFields.at(1), 'paktani@gmail.com');
      await tester.enterText(textFields.at(2), '081234567890');
      await tester.enterText(textFields.at(3), 'password123');
      await tester.enterText(textFields.at(4), 'password123');

      await tester.ensureVisible(find.text('Daftar Sekarang'));
      await tester.tap(find.text('Daftar Sekarang'));
      await tester.pumpAndSettle();

      // Register issues no token, so the user is not authenticated yet.
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser?.name, 'Pak Tani');
      expect(authProvider.currentUser?.msisdn, '081234567890');
    });
  });

  group('LoginView Tests', () {
    testWidgets('Renders all required elements per design spec', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      // Top nav
      expect(find.text('Kembali'), findsOneWidget);

      // Header badge and title
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
      expect(find.text('Masuk ke Akun'), findsOneWidget);

      // Form labels
      expect(find.text('Alamat Email'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);

      // Button and footer
      expect(find.text('Masuk Sekarang'), findsOneWidget);
      expect(find.text('Belum punya akun? '), findsOneWidget);
      expect(find.text('Daftar di sini'), findsOneWidget);
    });

    testWidgets('Validates required fields when submitted empty', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Masuk Sekarang'));
      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(find.text('Alamat email wajib diisi'), findsOneWidget);
      expect(find.text('Kata sandi wajib diisi'), findsOneWidget);
    });

    testWidgets('Submits login with LoginRequest data', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));

      // Fill email and password
      await tester.enterText(textFields.at(0), 'user@tanipintar.id');
      await tester.enterText(textFields.at(1), 'rahasia123');

      await tester.ensureVisible(find.text('Masuk Sekarang'));
      await tester.tap(find.text('Masuk Sekarang'));
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.accessToken, 'mock_token');
      authProvider.dispose();
    });
  });
}
