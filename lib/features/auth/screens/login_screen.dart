import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../widgets/custom_button.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/header_text.dart';
import '../../../widgets/label_text.dart';
import '../../../widgets/sub_regular_text.dart';
import '../bloc/auth_bloc.dart';
import '../repositories/auth_repository.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(
    text: AuthRepository.defaultAdminEmail,
  );
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    context.read<AuthBloc>().add(
      LoginRequested(_emailController.text, _passwordController.text),
    );
  }

  Future<void> _restoreDefaultAccess() async {
    await AuthRepository().resetDefaultAdminPasskey();
    if (!mounted) return;

    setState(() {
      _emailController.text = AuthRepository.defaultAdminEmail;
      _passwordController.text = AuthRepository.defaultAdminPasskey;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Default admin access restored. You can sign in with the seeded local account now.',
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Access Support'),
        content: const Text(
          'This build uses a local on-device database. If you lose access, use "Forgot Password?" to restore the seeded admin account:\n\nadmin@roservice.com\npassword123',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Area
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF007FFF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.water_drop_outlined,
                            color: Color(0xFF007FFF),
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const HeaderText(
                          text: AppStrings.welcomeBack,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const SubRegularText(
                          text: AppStrings.loginSubtitle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Form Area
                    const LabelText(text: AppStrings.emailAddress),
                    CustomTextField(
                      controller: _emailController,
                      hintText: AppStrings.emailPlaceholder,
                      prefixIcon: const Icon(
                        Icons.mail_outline,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const LabelText(text: AppStrings.password),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: AppStrings.passwordPlaceholder,
                      obscureText: _obscurePassword,
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color(0xFF94A3B8),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _restoreDefaultAccess,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          AppStrings.forgotPassword,
                          style: TextStyle(
                            color: Color(0xFF007FFF),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return CustomButton(
                          text: state is AuthLoading
                              ? "Loading..."
                              : AppStrings.loginButton,
                          icon: state is AuthLoading
                              ? null
                              : const Icon(
                                  Icons.login,
                                  size: 20,
                                  color: Colors.white,
                                ),
                          onPressed: state is AuthLoading ? () {} : _onLogin,
                        );
                      },
                    ),

                    const SizedBox(height: 48),

                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppStrings.noAccess,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: _showSupportDialog,
                          child: const Text(
                            AppStrings.contactAdmin,
                            style: TextStyle(
                              color: Color(0xFF007FFF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
