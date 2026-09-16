// lib/views/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import 'dashboard_screen.dart';
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
  bool _submitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passwordCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      ToastHelper.error(context, 'Please enter email and password');
      return;
    }

    setState(() => _submitting = true);
    final vm = context.read<AuthViewModel>();
    final ok = await vm.login(email, pass);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ToastHelper.success(context, 'Welcome back!');
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
    } else {
      ToastHelper.error(context, vm.errorMessage ?? 'Login failed. Please check credentials.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(children: [
          // Background Glows
          Positioned(top: -120, left: -80, child: _Glow(color: AppColors.accent, size: 320)),
          Positioned(bottom: -140, right: -100, child: _Glow(color: AppColors.accent, size: 360)),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.035),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
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
                          boxShadow: [
                            BoxShadow(color: AppColors.accent.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset('assets/icon/image.png', fit: BoxFit.cover),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('RecruitIQ', textAlign: TextAlign.center,
                        style: AppText.headline(28, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Sign in to your recruitment dashboard', textAlign: TextAlign.center,
                        style: AppText.body(13, color: Colors.white.withOpacity(0.45))),
                    const SizedBox(height: 36),

                    _ProField(
                      label: 'Email Address',
                      controller: _emailCtrl,
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _ProField(
                      label: 'Password',
                      controller: _passwordCtrl,
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: Colors.white38, size: 19),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    const SizedBox(height: 28),

                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _onLogin,
                        child: _submitting
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: RichText(text: TextSpan(children: [
                          TextSpan(text: 'New to RecruitIQ? ', style: AppText.body(13, color: Colors.white.withOpacity(0.35))),
                          TextSpan(text: 'Create Account', style: AppText.label(13, color: Colors.white.withOpacity(0.75))),
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
  final Color color;
  final double size;
  const _Glow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color.withOpacity(0.12), Colors.transparent])));
}

class _ProField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Widget? suffix;
  final IconData icon;
  final TextInputType? keyboardType;

  const _ProField({
    required this.label,
    required this.controller,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.55))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 18, color: Colors.white.withOpacity(0.35)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: keyboardType,
                  // COMMITTEE FIX: Visible white text
                  style: GoogleFonts.dmSans(fontSize: 14.5, color: Colors.white, fontWeight: FontWeight.w600),
                  cursorColor: AppColors.orange,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false, // COMMITTEE FIX: Overrides global white background theme
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: label == 'Email Address' ? 'name@company.com' : '••••••••',
                    hintStyle: GoogleFonts.dmSans(fontSize: 14.5, color: Colors.white.withOpacity(0.20)),
                  ),
                ),
              ),
              if (suffix != null) suffix!,
              const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }
}
