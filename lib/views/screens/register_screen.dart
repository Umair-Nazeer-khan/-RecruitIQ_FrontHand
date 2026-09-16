// lib/views/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_constants.dart';
import '../../utils/toast_helper.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  String? _validate() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty) return 'Please enter your full name';
    if (email.isEmpty) return 'Please enter your email address';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address';
    }
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String _mapServerError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('already') || lower.contains('exist')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('email'))
      return 'Please check your email address and try again.';
    if (lower.contains('password')) return 'Please choose a stronger password.';
    if (lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('connect')) {
      return 'Connection issue. Please check your internet and try again.';
    }
    return raw.replaceAll('Exception:', '').trim();
  }

  Future<void> _onRegister() async {
    final validationError = _validate();
    if (validationError != null) {
      ToastHelper.error(context, validationError);
      return;
    }

    setState(() => _submitting = true);
    final vm = context.read<AuthViewModel>();
    final ok = await vm.register(
        _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ToastHelper.success(context, 'Account created successfully!');
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } else {
      ToastHelper.error(
          context,
          _mapServerError(
              vm.errorMessage ?? 'Registration failed. Please try again.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Stack(children: [
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.12),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.08),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.035),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.09)),
                              ),
                              child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.orange.withOpacity(0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset('assets/icon/image.png',
                                fit: BoxFit.cover),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Join RecruitIQ',
                          textAlign: TextAlign.center,
                          style: AppText.headline(26,
                              color: Colors.white, letterSpacing: -0.5)),
                      const SizedBox(height: 6),
                      Text('Create your recruiter account',
                          textAlign: TextAlign.center,
                          style: AppText.body(13,
                              color: Colors.white.withOpacity(0.45))),
                      const SizedBox(height: 30),
                      _ProField(
                        label: 'Full Name',
                        controller: _nameCtrl,
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _ProField(
                        label: 'Email Address',
                        controller: _emailCtrl,
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _ProField(
                        label: 'Password',
                        controller: _passwordCtrl,
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white38,
                              size: 19),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text('Minimum 6 characters',
                            style: AppText.caption(11,
                                color: Colors.white.withOpacity(0.3))),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _onRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.2))
                              : Text('Create Account',
                                  style:
                                      AppText.title(15, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                              text: TextSpan(children: [
                            TextSpan(
                                text: 'Already have an account? ',
                                style: AppText.body(13,
                                    color: Colors.white.withOpacity(0.35))),
                            TextSpan(
                                text: 'Sign In',
                                style: AppText.label(13,
                                    color: Colors.white.withOpacity(0.75))),
                          ])),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
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
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.55))),
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
                  style: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      color: AppColors.logoAqua,
                      fontWeight: FontWeight.w600),
                  cursorColor: AppColors.orange,
                  selectionControls: materialTextSelectionControls,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: InputBorder.none,
                    hintText: label == 'Email Address'
                        ? 'Enter your email address'
                        : null,
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 14.5,
                      color: Colors.white.withOpacity(0.30),
                    ),
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
