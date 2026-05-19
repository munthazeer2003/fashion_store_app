import 'package:flutter/material.dart';
import '../../core/app_routes.dart';
import '../../core/mvvm/view_model_builder.dart';
import '../../view_models/register_view_model.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  static const Color _accent = Color(0xFFF26B3A);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _fieldBorder = Color(0xFFE8E8E8);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<RegisterViewModel>(
      create: (_) => RegisterViewModel(),
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: _textPrimary),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Signup to get started',
                style: TextStyle(color: _textMuted),
              ),
              const SizedBox(height: 24),
              _InputField(
                hintText: 'Full Name',
                icon: Icons.person_outline,
                controller: viewModel.nameController,
              ),
              const SizedBox(height: 12),
              _InputField(
                hintText: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                controller: viewModel.emailController,
              ),
              const SizedBox(height: 12),
              _InputField(
                hintText: 'Password',
                icon: Icons.lock_outline,
                obscureText: !viewModel.passwordVisible,
                controller: viewModel.passwordController,
                suffixIcon: IconButton(
                  onPressed: viewModel.togglePasswordVisibility,
                  icon: Icon(
                    viewModel.passwordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: _textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _InputField(
                hintText: 'Confirm Password',
                icon: Icons.lock_outline,
                obscureText: !viewModel.confirmVisible,
                controller: viewModel.confirmController,
                suffixIcon: IconButton(
                  onPressed: viewModel.toggleConfirmVisibility,
                  icon: Icon(
                    viewModel.confirmVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: _textMuted,
                  ),
                ),
              ),
              if (viewModel.errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: viewModel.isBusy
                      ? null
                      : () async {
                          final success = await viewModel.register();
                          if (!context.mounted) {
                            return;
                          }
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  viewModel.errorMessage ??
                                      'Registration failed. Please try again.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.pushReplacementNamed(context, AppRoutes.home);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: viewModel.isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.hintText,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.controller,
  });

  final String hintText;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: RegisterScreen._textMuted),
        prefixIcon: Icon(icon, color: RegisterScreen._textMuted),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RegisterScreen._fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RegisterScreen._accent),
        ),
      ),
    );
  }
}
