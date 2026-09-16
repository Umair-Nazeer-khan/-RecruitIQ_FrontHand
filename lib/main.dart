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

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Do not lock web. On phones we keep portrait as the default,
  // while the responsive UI also works when orientation changes.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
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
        // Required by Job Requirements + Match Results.
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
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
              TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(),
            },
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.cardBg,
            foregroundColor: AppColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            titleTextStyle: AppText.title(17),
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.cardBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: AppColors.border2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide(color: AppColors.border2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: AppColors.orange,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: AppColors.red, width: 1.5),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: AppText.title(14, color: Colors.white),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              minimumSize: const Size(0, 48),
              side: BorderSide(color: AppColors.border2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
          chipTheme: base.chipTheme.copyWith(
            backgroundColor: AppColors.logoAqua,
            side: BorderSide(color: AppColors.border2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            labelStyle: AppText.label(12),
          ),
          dividerTheme: const DividerThemeData(
            color: AppColors.divider,
            thickness: 1,
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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: .82, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final authVm = context.read<AuthViewModel>();
    await authVm.checkAuthState();

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      authVm.isLoggedIn ? '/dashboard' : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withOpacity(.35),
                            blurRadius: 34,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/icon/image.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'RecruitIQ',
                      style: AppText.headline(28, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-POWERED CANDIDATE SCREENING',
                      textAlign: TextAlign.center,
                      style: AppText.caption(
                        10,
                        color: Colors.white.withOpacity(.48),
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: .13,
                      ),
                    ),
                    const SizedBox(height: 42),
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentLight.withOpacity(.8),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Preparing your recruitment workspace…',
                      style: AppText.caption(
                        10,
                        color: Colors.white.withOpacity(.30),
                      ),
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
