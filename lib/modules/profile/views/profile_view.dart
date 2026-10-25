import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/colorScheme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/views/login_view.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_header_card.dart';
import 'edit_profile_view.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/logout_button.dart';

class ProfileView extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().currentUser?.id;
      if (userId != null) context.read<ProfileProvider>().fetchProfile(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundCanvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileHeaderCard(
                  userProfile: provider.userProfile,
                  onEditTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileView()),
                  ),
                ),
                const SizedBox(height: 24),
                
                const Text(
                  'Pengaturan Akun',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                MenuItemCard(
                  icon: Icons.notifications_none,
                  label: 'Notifikasi',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                MenuItemCard(
                  icon: Icons.language,
                  label: 'Pilihan Bahasa',
                  trailingText: 'Indonesia',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                MenuItemCard(
                  icon: Icons.lock_outline,
                  label: 'Keamanan',
                  onTap: () {},
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Bantuan',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                MenuItemCard(
                  icon: Icons.help_outline,
                  label: 'Pusat Bantuan',
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                MenuItemCard(
                  icon: Icons.info_outline,
                  label: 'Tentang Kami',
                  onTap: () {},
                ),
                
                const SizedBox(height: 32),
                LogoutButton(
                  onLogout: () async {
                    final nav = Navigator.of(context, rootNavigator: true);
                    await context.read<AuthProvider>().logout();
                    nav.pushNamedAndRemoveUntil(LoginView.routeName, (_) => false);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
