import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'employer/employer_home.dart';
import 'job_seeker/job_seeker_home.dart';
import '../services/app_session.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final Widget fallbackScreen;

  const SplashScreen({super.key, required this.fallbackScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Fast, simple delay for the splash screen
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Widget next;
      if (!AppSession.isLoggedIn) {
        next = widget.fallbackScreen;
      } else {
        final role = AppSession.user?['role']?.toString().trim();
        if (role == 'company') {
          next = EmployerHomeScreen(token: AppSession.token);
        } else if (role == 'job_seeker') {
          next = JobSeekerHomeScreen(
            userId: AppSession.userId,
            token: AppSession.token,
          );
        } else {
          next = widget.fallbackScreen;
        }
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => next,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final horizontalPadding = screenSize.width > 600 ? 48.0 : 24.0;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Integrated Logo Card to prevent looking like a pasted photo
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
                      // Tagline matching the brand layout perfectly across all displays
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
                const SizedBox(height: 48),
                // Premium loading indicator to show the app is active
                const SpinKitThreeBounce(
                  color: Color(0xFF174A7E),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
