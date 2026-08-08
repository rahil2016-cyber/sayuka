import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/api_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_bootstrap.dart';
import 'services/connectivity_service.dart';
import 'widgets/no_internet_gate.dart';
import 'screens/auth/job_seeker_otp_login.dart';
import 'screens/auth/employer_otp_login.dart';
import 'screens/auth/register_screen.dart';
import 'screens/employer/employer_home.dart';
import 'screens/job_seeker/job_seeker_home.dart';
import 'services/app_session.dart';
import 'services/fcm_flutter_service.dart';
import 'navigation/app_navigator.dart';
import 'utils/app_colors.dart';
import 'utils/app_theme.dart';
import 'widgets/app_logo.dart';
import 'widgets/brand_dream_job_tagline.dart';
import 'widgets/job_deep_link_listener.dart';
import 'screens/splash_screen.dart';

import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  if (kDebugMode) {
    HttpOverrides.global = MyHttpOverrides();
  }
  WidgetsFlutterBinding.ensureInitialized();

  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    }
  };

  // Global platform error handler (async/native errors)
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
    return true;
  };

  // Paint custom splash immediately (do not delay runApp with network checks).
  runApp(const ProviderScope(child: JobAllocateApp()));

  Future.microtask(() async {
    await ConnectivityService.instance.start();
    await tryInitializeFirebase();
    await FcmFlutterService.instance.initialize();
  });
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class JobAllocateApp extends StatefulWidget {
  const JobAllocateApp({super.key});

  @override
  State<JobAllocateApp> createState() => _JobAllocateAppState();
}

class _JobAllocateAppState extends State<JobAllocateApp> {
  @override
  void initState() {
    super.initState();
    NotificationEvents.addListener(_onPushNotification);
  }

  @override
  void dispose() {
    NotificationEvents.removeListener(_onPushNotification);
    super.dispose();
  }

  void _onPushNotification(RemoteMessage message) {
    // We now rely on flutter_local_notifications to show a heads-up notification.
    // If you need custom in-app handling (like a badge refresh), handle it here.
  }

  Widget _getInitialScreen() {
    return const SplashScreen(fallbackScreen: RoleSelectionScreen());
  }

  @override
  Widget build(BuildContext context) {
    return JobDeepLinkListener(
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        title: 'JobAllocate',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _getInitialScreen(),
        builder: (context, child) {
          return NoInternetGate(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Card containing logo and vector tagline
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLogo(height: 56),
                        const SizedBox(height: 14),
                        // Premium vector tagline matching the brand logo design
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 28,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53E3E), // Brand Red
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'RIGHT JOB, RIGHT CANDIDATE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: const Color(0xFF1E293B), // Dark slate
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 2,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF174A7E), // Brand Blue
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Handshake Illustration - sized responsively to prevent overlap
                  Image.asset(
                    'assets/images/handshake_illustration.png',
                    height: screenSize.height > 700 ? 190 : 140,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, stack) => Icon(
                      Icons.handshake_rounded,
                      size: screenSize.height > 700 ? 110 : 90,
                      color: const Color(0xFF174A7E).withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Actions Area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Button: I'm a Job Seeker
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const JobSeekerOtpLoginScreen()),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF174A7E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white70, width: 1.2),
                                ),
                                child: const Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
                              ),
                              Expanded(
                                child: Text(
                                  'I\'m a Job Seeker',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Button: I'm an Employer
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const EmployerOtpLoginScreen()),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF174A7E), width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF174A7E).withOpacity(0.5), width: 1.2),
                                ),
                                child: const Icon(Icons.work_outline_rounded, size: 20, color: Color(0xFF174A7E)),
                              ),
                              Expanded(
                                child: Text(
                                  'I\'m an Employer',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF174A7E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF174A7E)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                        const SizedBox(height: 16),

                        // Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF174A7E)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: 'By continuing, you agree to our ',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Terms & Conditions',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF3B82F6),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
