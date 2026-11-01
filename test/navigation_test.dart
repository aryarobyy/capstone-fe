import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:tanipintar/core/network/rpc_client.dart';
import 'package:tanipintar/modules/area/views/area_screen.dart';
import 'package:tanipintar/modules/monitoring/views/dashboard_screen.dart';
import 'package:tanipintar/modules/navigation/providers/navigation_provider.dart';
import 'package:tanipintar/modules/navigation/views/main_screen.dart';
import 'package:tanipintar/modules/profile/views/profile_view.dart';
import 'package:tanipintar/modules/riwayat/views/riwayat_screen.dart';
import 'package:tanipintar/utils/app_providers.dart';

Widget _buildTestApp({RpcClient? client}) {
  final mockClient = client ??
      RpcClient(
        baseUrl: 'https://example.test',
        httpClient: MockClient((request) async {
          return http.Response('{"success":true,"data":[]}', 200);
        }),
      );

  return MultiProvider(
    providers: AppProviders.buildProviders(client: mockClient),
    child: const MaterialApp(
      home: MainScreen(),
    ),
  );
}

void main() {
  group('MainScreen Navigation Tests', () {
    testWidgets('renders 4 navigation tabs and defaults to Dashboard', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Verify the 4 nav items are rendered
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Area'), findsWidgets);
      expect(find.text('Profile'), findsOneWidget);

      // Verify no "Home" dummy screen or tab item
      expect(find.text('Home'), findsNothing);

      // Verify the initial screen is DashboardScreen
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('can navigate between the 4 tabs', (tester) async {
      await tester.pumpWidget(_buildTestApp());
      await tester.pumpAndSettle();

      // Initially on Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Switch to Riwayat
      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.byType(RiwayatScreen), findsOneWidget);

      // Switch to Area
      await tester.tap(find.text('Area'));
      await tester.pumpAndSettle();
      expect(find.byType(AreaScreen), findsOneWidget);

      // Switch to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileView), findsOneWidget);

      // Switch back to Dashboard (tap the first Dashboard text in nav bar)
      await tester.tap(find.text('Dashboard').last);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });

  group('NavigationProvider Tests', () {
    test('updates index correctly for 4-button layout', () {
      final navProvider = NavigationProvider();
      expect(navProvider.currentIndex, 0);

      navProvider.navigateToRiwayat();
      expect(navProvider.currentIndex, 1);

      navProvider.navigateToHistory();
      expect(navProvider.currentIndex, 1);

      navProvider.navigateToArea();
      expect(navProvider.currentIndex, 2);

      navProvider.navigateToProfile();
      expect(navProvider.currentIndex, 3);

      navProvider.navigateToDashboard();
      expect(navProvider.currentIndex, 0);

      navProvider.navigateToHome();
      expect(navProvider.currentIndex, 0);

      navProvider.navigateToMonitoring();
      expect(navProvider.currentIndex, 0);
    });
  });
}
