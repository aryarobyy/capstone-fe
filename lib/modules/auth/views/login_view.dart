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
import 'register_view.dart';

/// Login Screen matching the design style of authGuide.md.
/// Utilizes [LoginRequest] from lib/modules/auth/models/auth_model.dart as input data.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  static const String routeName = '/login';

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    // Build the LoginRequest input model
    final loginRequest = LoginRequest(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      loginRequest.email,
      loginRequest.password,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selamat datang kembali, ${authProvider.currentUser?.name.isNotEmpty == true ? authProvider.currentUser!.name : "Petani Hebat"}!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Successfully logged in. Navigate to MainScreen.
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      final message = authProvider.errorMessage ?? 'Gagal masuk. Periksa kembali email dan kata sandi Anda.';
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
                            title: 'Masuk ke Akun',
                            subtitle:
                                'Silakan masuk untuk melanjutkan pemantauan dan pengelolaan pertanian cerdas bersama TaniPintar.',
                            icon: Icons.eco_rounded,
                          ),

                          // 1. Alamat Email Field
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

                          // 2. Kata Sandi Field
                          AppTextField(
                            label: 'Kata Sandi',
                            hintText: 'Masukkan kata sandi Anda',
                            prefixIcon: Icons.lock_outline_rounded,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleLogin(),
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
                          const SizedBox(height: 24.0),

                          // Submit Button: Masuk Sekarang
                          AppButton(
                            text: 'Masuk Sekarang',
                            icon: Icons.login_rounded,
                            isLoading: authProvider.isLoading,
                            onPressed: _handleLogin,
                          ),

                          // Footer: Switch to Register
                          AuthFooter(
                            promptText: 'Belum punya akun? ',
                            actionText: 'Daftar di sini',
                            onActionTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterView()),
                              );
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
