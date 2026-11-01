import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../../../utils/colorScheme.dart';
import '../../area/views/area_screen.dart';
import '../../monitoring/views/dashboard_screen.dart';
import '../../riwayat/views/riwayat_screen.dart';
import '../../profile/views/profile_view.dart';

class MainScreen extends StatefulWidget {
  static const routeName = '/main';

  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PersistentTabController _controller;

  @override
  void initState() {
    super.initState();
    // Default to "Dashboard" tab (index 0)
    _controller = PersistentTabController(initialIndex: 0);
  }

  List<Widget> _buildScreens() {
    return const [
      DashboardScreen(),
      RiwayatScreen(),
      AreaScreen(),
      ProfileView(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        title: ("Dashboard"),
        activeColorPrimary: AppColors.navSelected,
        inactiveColorPrimary: AppColors.navUnselected,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.history),
        title: ("Riwayat"),
        activeColorPrimary: AppColors.navSelected,
        inactiveColorPrimary: AppColors.navUnselected,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.eco_outlined),
        title: ("Area"),
        activeColorPrimary: AppColors.navSelected,
        inactiveColorPrimary: AppColors.navUnselected,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_outline),
        title: ("Profile"),
        activeColorPrimary: AppColors.navSelected,
        inactiveColorPrimary: AppColors.navUnselected,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      padding: const EdgeInsets.only(top: 8),
      backgroundColor: AppColors.bottomNavBg,
      decoration: const NavBarDecoration(
        colorBehindNavBar: AppColors.bottomNavBg,
      ),
      isVisible: true,
      confineToSafeArea: true,
      navBarStyle: NavBarStyle.style6,
    );
  }
}
