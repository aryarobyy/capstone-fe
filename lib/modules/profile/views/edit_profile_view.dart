import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../utils/colorScheme.dart';
import '../../../../widgets/app_button.dart';
import '../providers/profile_provider.dart';
import '../widgets/edit_profile_form_card.dart';

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize form with current profile data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProfileProvider>();
      final profile = provider.userProfile;
      if (profile != null) {
        _nameController.text = profile.name;
        _emailController.text = profile.email;
      }
      // skipped: phone number mapping, add when backend model supports it.
      _phoneController.text = '081234567890';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final provider = context.read<ProfileProvider>();
    final profile = provider.userProfile;
    if (profile == null) return;

    final success = await provider.updateProfile(
      id: profile.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal memperbarui profil'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chevron_left, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'Kembali',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        title: const Text(
          'Ubah Profil',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            // Assuming a slightly serif or standard bold look as per TaniPintar design
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppColors.border,
            height: 1.0,
          ),
        ),
      ),
      body: Consumer<ProfileProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile Avatar Container
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(4.0),
                  child: const CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Form Container
                EditProfileFormCard(
                  nameController: _nameController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                AppButton(
                  text: 'Simpan Perubahan',
                  icon: Icons.check,
                  isLoading: provider.isUpdating,
                  onPressed: _handleSave,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
