import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../job_seeker/job_seeker_home.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/brand_dream_job_tagline.dart';
import 'register_screen.dart';

class JobSeekerOtpLoginScreen extends StatefulWidget {
  const JobSeekerOtpLoginScreen({super.key});

  @override
  State<JobSeekerOtpLoginScreen> createState() => _JobSeekerOtpLoginScreenState();
}

class _JobSeekerOtpLoginScreenState extends State<JobSeekerOtpLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _codeSent = false;
  String? _verificationId;
  int? _resendToken;
  
  int _secondsRemaining = 60;
  Timer? _timer;
  
  final ApiService _apiService = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _startResendTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Please enter your phone number');
      return;
    }

    // Auto prepend +91 (India) if user enters standard 10 digit number
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      } else {
        _showSnackBar('Please enter phone number with country code (e.g. +91...)');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto retrieval succeeded
          if (mounted) {
            setState(() => _isLoading = true);
          }
          try {
            UserCredential userCredential = await _auth.signInWithCredential(credential);
            String? idToken = await userCredential.user?.getIdToken();
            if (idToken != null) {
              await _loginToBackend(idToken);
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              _showSnackBar(e.toString());
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _showSnackBar(e.message ?? 'Verification failed.');
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _resendToken = resendToken;
              _codeSent = true;
              _isLoading = false;
            });
            _startResendTimer();
            _showSnackBar('Verification code sent to $phone', isError: false);
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            _verificationId = verificationId;
          }
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString());
      }
    }
  }

  Future<void> _verifyCode() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      _showSnackBar('Please enter the 6-digit verification code');
      return;
    }
    if (_verificationId == null) {
      _showSnackBar('Session expired. Please request OTP again.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      String? idToken = await userCredential.user?.getIdToken();
      if (idToken != null) {
        await _loginToBackend(idToken);
      } else {
        throw Exception('Failed to retrieve ID token from Firebase');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e is FirebaseAuthException ? (e.message ?? e.toString()) : e.toString());
      }
    }
  }

  Future<void> _loginToBackend(String idToken) async {
    try {
      await _apiService.authenticateWithFirebaseToken(
        idToken: idToken,
        role: 'job_seeker',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          settings: const RouteSettings(name: JobSeekerHomeScreen.routeName),
          pageBuilder: (context, animation, secondaryAnimation) => JobSeekerHomeScreen(
            userId: AppSession.userId,
            token: AppSession.token,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(ApiService.messageFromException(e));
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_codeSent) {
              setState(() {
                _codeSent = false;
                _otpController.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Row(
                children: [
                   AppLogo(height: 28),
                ],
              ),
              const SizedBox(height: 8),
              BrandDreamJobTagline(
                crossAxisAlignment: CrossAxisAlignment.start,
                textAlign: TextAlign.start,
                headlineStyle: textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                taglineStyle: textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                spacing: 4,
              ),
              const SizedBox(height: 12),
              Text(
                _codeSent ? 'Verify Code' : 'Welcome Back!',
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _codeSent
                    ? 'Enter the 6-digit code we sent to your phone number.'
                    : 'Login using secure Firebase Phone OTP verification.',
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              if (!_codeSent) ...[
                Text(
                  'Phone Number',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(
                      Icons.phone_iphone_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Send Verification Code',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                ),
              ] else ...[
                Text(
                  'Verification Code',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OtpInputField(
                    controller: _otpController,
                    onCompleted: (_) => _verifyCode(),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Verify & Login',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          'Resend code in $_secondsRemaining seconds',
                          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                        )
                      : TextButton(
                          onPressed: _isLoading ? null : _sendOtp,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ),
                ),
              ],

              const SizedBox(height: 24),
              if (!_codeSent)
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        'New to JobAllocate? ',
                        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: const Text(
                          'Create account',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}