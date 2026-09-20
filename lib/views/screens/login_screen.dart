// lib/views/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final vm = context.read<AuthViewModel>();
    final success = await vm.login(_emailCtrl.text, _passwordCtrl.text);
    
    if (!mounted) return;

    if (success) {
      ToastHelper.success(context, 'Welcome back!');
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else if (vm.errorMessage != null) {
      ToastHelper.error(context, vm.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(children: [
          Positioned(top: -120, left: -80, child: _Glow(color: AppColors.accent, size: 320)),
          Positioned(bottom: -140, right: -100, child: _Glow(color: AppColors.accent, size: 360)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset('assets/icon/image.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('RecruitIQ', textAlign: TextAlign.center, style: AppText.headline(28, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Sign in to continue', textAlign: TextAlign.center, style: AppText.body(13, color: Colors.white54)),
                    const SizedBox(height: 36),

                    _ProField(
                      label: 'Email Address',
                      controller: _emailCtrl,
                      icon: Icons.mail_outline_rounded,
                      errorText: authVm.fieldErrors['email'],
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _ProField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      icon: Icons.lock_outline_rounded,
                      errorText: authVm.fieldErrors['password'],
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: authVm.isLoading ? null : _onLogin,
                      child: authVm.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 22),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          authVm.clearError();
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: RichText(text: TextSpan(children: [
                          TextSpan(text: 'New to RecruitIQ? ', style: AppText.body(13, color: Colors.white38)),
                          TextSpan(text: 'Create Account', style: AppText.label(13, color: Colors.white70)),
                        ])),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color; final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withValues(alpha: 0.1), Colors.transparent])));
}

class _ProField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final String? errorText;
  final Widget? suffix;
  final IconData icon;
  final TextInputType? keyboardType;

  const _ProField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.errorText,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white54)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: hasError ? AppColors.red.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 18, color: hasError ? AppColors.red.withValues(alpha: 0.6) : Colors.white38),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14.5, color: Colors.white),
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (suffix != null) suffix!,
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(errorText!, style: const TextStyle(color: AppColors.red, fontSize: 11)),
          ),
      ],
    );
  }
}
