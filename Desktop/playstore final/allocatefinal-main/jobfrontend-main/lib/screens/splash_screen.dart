import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/api_config.dart';
import '../services/app_session.dart';
import '../services/fcm_flutter_service.dart';
import '../widgets/app_logo.dart';
import 'employer/employer_home.dart';
import 'job_seeker/job_seeker_home.dart';

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
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Keep custom splash visible while bootstrapping; enforce a short brand beat.
    final minDisplay = Future<void>.delayed(const Duration(milliseconds: 1200));
    await Future.wait<void>([
      ApiConfig.initialize(),
      AppSession.loadFromStorage(),
      minDisplay,
    ]);

    if (AppSession.isLoggedIn) {
      // Ensure device is registered for system tray / notification center pushes.
      // FCM init may still be racing; ignore failures.
      // ignore: unawaited_futures
      FcmFlutterService.instance.registerTokenAfterLogin();
    }

    if (!mounted) return;

    late final Widget next;
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
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SplashBackgroundPainter(),
            ),
          ),
          Center(
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.04),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIconGroup(),
                  const SizedBox(height: 12),
                  const AppLogo(height: 34),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'RIGHT JOB, RIGHT CANDIDATE',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFF174A7E),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(2),
                            bottomLeft: Radius.circular(2),
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF174A7E),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(2),
                            bottomRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Connecting Opportunities...',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconGroup() {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            top: 15,
            left: 10,
            child: Icon(Icons.star, size: 8, color: Color(0xFFEF4444)),
          ),
          const Positioned(
            top: 25,
            right: 15,
            child: Icon(Icons.star_border, size: 8, color: Color(0xFFEF4444)),
          ),
          const Positioned(
            bottom: 25,
            left: 15,
            child: Icon(Icons.circle_outlined, size: 6, color: Color(0xFF3B82F6)),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF174A7E).withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.work_rounded,
              size: 36,
              color: Color(0xFF174A7E),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = const Color(0xFFEFF6FF);
    final topWave = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.22)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.30,
        size.width * 0.45,
        size.height * 0.20,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.12,
        0,
        size.height * 0.18,
      )
      ..close();
    canvas.drawPath(topWave, paint);

    paint.color = const Color(0xFFFEF2F2);
    final bottomWave = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.65,
        size.height * 0.70,
        size.width * 0.35,
        size.height * 0.80,
      )
      ..quadraticBezierTo(
        size.width * 0.15,
        size.height * 0.86,
        0,
        size.height * 0.82,
      )
      ..close();
    canvas.drawPath(bottomWave, paint);

    final dotPaint = Paint()..color = const Color(0xFF93C5FD).withOpacity(0.35);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.35), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.40), 3, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.65), 5, dotPaint);
    final redDot = Paint()..color = const Color(0xFFFCA5A5).withOpacity(0.4);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.62), 3, redDot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
