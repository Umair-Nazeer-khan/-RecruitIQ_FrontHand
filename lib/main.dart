import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'utils/app_constants.dart';
import 'utils/network_status.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/job_viewmodel.dart';
import 'views/screens/dashboard_screen.dart';
import 'views/screens/login_screen.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── PREVENT RED SCREEN CRASHES (Professional Fallback) ──────
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: AppColors.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sentiment_very_dissatisfied_rounded, 
                  color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              Text('Application Error', style: AppText.title(18)),
              const SizedBox(height: 8),
              const Text(
                'Something unexpected happened in the UI layout. '
                'Please restart the app or go back.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.ink3),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => rootScaffoldMessengerKey.currentState?.clearSnackBars(),
                child: const Text('Dismiss'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(const RecruitIQApp());
}

class RecruitIQApp extends StatelessWidget {
  const RecruitIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData.light(useMaterial3: true);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => UploadViewModel()),
        ChangeNotifierProvider(create: (_) => CandidatesViewModel()),
        ChangeNotifierProvider(create: (_) => JobViewModel()),
      ],
      child: MaterialApp(
        title: 'RecruitIQ',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        theme: base.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.accent,
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: AppColors.surface,
          textTheme: GoogleFonts.dmSansTextTheme(base.textTheme),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.cardBg,
            foregroundColor: AppColors.ink,
            elevation: 0,
            centerTitle: false,
            titleTextStyle: AppText.title(17),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, color: AppColors.red),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: AppText.title(15),
            ),
          ),
        ),
        builder: (context, child) => NetworkStatusListener(
          child: child ?? const SizedBox.shrink(),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/dashboard': (_) => const DashboardScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final authVm = context.read<AuthViewModel>();
    await authVm.checkAuthState();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, authVm.isLoggedIn ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100, height: 104,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/icon/image.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 32),
              Text('RecruitIQ', style: AppText.headline(32, color: Colors.white)),
              const SizedBox(height: 12),
              Text('AI-POWERED CANDIDATE SCREENING', 
                style: AppText.caption(11, color: Colors.white60).copyWith(letterSpacing: 2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white30)),
            ],
          ),
        ),
      ),
    );
  }
}
