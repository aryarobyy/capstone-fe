import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/colorScheme.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../models/auth_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_card.dart';
import '../widgets/auth_footer.dart';
import '../widgets/auth_header.dart';
import 'login_view.dart';

/// Register Screen following UI Design Specification Guidelines (authGuide.md).
/// Utilizes [RegisterRequest] from lib/modules/auth/models/auth_model.dart as input data.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  static const String routeName = '/register';

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _msisdnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _msisdnController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Build the RegisterRequest input model
    final registerRequest = RegisterRequest(
      name: _nameController.text.trim(),
      // BE matched email case-sensitively; keyboards auto-capitalise the first letter.
      email: _emailController.text.trim().toLowerCase(),
      msisdn: _msisdnController.text.trim(),
      password: _passwordController.text,
    );

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      registerRequest.name,
      registerRequest.email,
      registerRequest.msisdn,
      registerRequest.password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan masuk dengan akun Anda.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to LoginView or previous screen
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
        );
      }
    } else {
      final message = authProvider.errorMessage ?? 'Pendaftaran gagal. Silakan coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.backgroundCanvas,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            AuthTopNav(
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                }
              },
            ),

            // Scrollable Form Card Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Center(
                  child: AuthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Centered Header Badge, Title & Subtitle
                          const AuthHeader(
                            title: 'Daftar Akun Baru',
                            subtitle:
                                'Mari bergabung bersama TaniPintar untuk memantau dan mengoptimalkan hasil pertanian Anda.',
                            icon: Icons.eco_rounded,
                          ),

                          // 1. Nama Lengkap Field
                          AppTextField(
                            label: 'Nama Lengkap',
                            hintText: 'Masukkan nama Anda',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              if (value.trim().length < 3) {
                                return 'Nama minimal 3 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // 2. Alamat Email Field
                          AppTextField(
                            label: 'Alamat Email',
                            hintText: 'nama@email.com',
                            prefixIcon: Icons.mail_outline_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Alamat email wajib diisi';
                              }
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(value.trim())) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // 3. Nomor HP / WhatsApp Field (msisdn, wajib oleh API)
                          AppTextField(
                            label: 'Nomor HP / WhatsApp',
                            hintText: '08...',
                            prefixIcon: Icons.phone_android_rounded,
                            controller: _msisdnController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final msisdn = value?.trim() ?? '';
                              if (msisdn.isEmpty) {
                                return 'Nomor HP wajib diisi';
                              }
                              if (!RegExp(r'^(\+62|62|0)8[0-9]{7,12}$').hasMatch(msisdn)) {
                                return 'Format nomor HP tidak valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // 4. Kata Sandi Field
                          AppTextField(
                            label: 'Kata Sandi',
                            hintText: 'Minimal 6 karakter',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (value.length < 6) {
                                return 'Kata sandi minimal 6 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16.0),

                          // 5. Konfirmasi Kata Sandi Field
                          AppTextField(
                            label: 'Konfirmasi Kata Sandi',
                            hintText: 'Ulangi kata sandi Anda',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleRegister(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (value != _passwordController.text) {
                                return 'Kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24.0),

                          // Submit Button: Daftar Sekarang
                          AppButton(
                            text: 'Daftar Sekarang',
                            icon: Icons.person_add_alt_1_rounded,
                            isLoading: authProvider.isLoading,
                            onPressed: _handleRegister,
                          ),

                          // Footer: Switch to Login
                          AuthFooter(
                            promptText: 'Sudah punya akun? ',
                            actionText: 'Masuk di sini',
                            onActionTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginView()),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
