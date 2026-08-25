import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/api_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_bootstrap.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  await AppSession.loadFromStorage();
  
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
  
  // Launch the app immediately!
  runApp(const ProviderScope(child: JobAllocateApp()));
  
  // Initialize Firebase and FCM in the background so it doesn't delay the splash screen / app launch
  Future.microtask(() async {
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
    if (!AppSession.isLoggedIn) return const RoleSelectionScreen();
    final role = AppSession.user?['role']?.toString().trim();
    if (role == 'company') return EmployerHomeScreen(token: AppSession.token);
    if (role == 'job_seeker') return JobSeekerHomeScreen(userId: AppSession.userId, token: AppSession.token);
    return const RoleSelectionScreen();
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'I\'m a Job Seeker',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'I\'m an Employer',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF174A7E),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20, color: Color(0xFF174A7E)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade100, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'or continue with',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade100, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Button: Continue with Google
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Google Sign-In coming soon!')),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFFF8FAFC),
                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                                height: 20,
                                width: 20,
                                errorBuilder: (ctx, err, stack) => const Icon(Icons.g_mobiledata_rounded, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Footer
                        Center(
                          child: Text(
                            'By continuing, you agree to our Terms & Conditions',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
