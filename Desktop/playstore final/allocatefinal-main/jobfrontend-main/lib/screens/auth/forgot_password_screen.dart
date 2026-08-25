import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/brand_dream_job_tagline.dart';
import '../job_seeker/job_seeker_home.dart';
import '../employer/employer_home.dart';
import '../../services/app_session.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.isJobSeeker = true, this.initialPhone = ''});

  final bool isJobSeeker;
  final String initialPhone;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone;
  }

  bool _isLoading = false;
  int _step = 0; // 0 = Phone, 1 = OTP, 2 = New Password
  String? _verificationId;
  int? _resendToken;
  int _secondsRemaining = 60;
  Timer? _timer;

  final ApiService _apiService = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _firebaseIdToken;

  Color get _themeColor => widget.isJobSeeker ? AppColors.primary : AppColors.accent;

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
      final exists = await _apiService.checkAccountExists(
        phone: phone,
        role: widget.isJobSeeker ? 'job_seeker' : 'company',
      );

      if (!exists) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSnackBar('Account does not exist. Please create an account.');
        }
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (mounted) {
            setState(() => _isLoading = true);
          }
          try {
            UserCredential userCredential = await _auth.signInWithCredential(credential);
            String? idToken = await userCredential.user?.getIdToken();
            if (idToken != null) {
              setState(() {
                _firebaseIdToken = idToken;
                _step = 2;
                _isLoading = false;
              });
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
              _step = 1;
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
        setState(() {
          _firebaseIdToken = idToken;
          _step = 2;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to retrieve verification token');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e is FirebaseAuthException ? (e.message ?? e.toString()) : e.toString());
      }
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showSnackBar('Please enter a password');
      return;
    }
    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters long');
      return;
    }
    if (password != confirm) {
      _showSnackBar('Passwords do not match');
      return;
    }

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecial) {
      _showSnackBar('Password must contain uppercase, lowercase, numbers, and special characters');
      return;
    }

    if (_firebaseIdToken == null) {
      _showSnackBar('Authentication session lost. Please restart the process.');
      setState(() => _step = 0);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.resetPasswordWithFirebase(
        idToken: _firebaseIdToken!,
        password: password,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      _showSnackBar('Password reset successful!', isError: false);

      if (widget.isJobSeeker) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => JobSeekerHomeScreen(
              userId: AppSession.userId,
              token: AppSession.token,
            ),
          ),
          (_) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmployerHomeScreen(token: AppSession.token),
          ),
          (_) => false,
        );
      }
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
            if (_step == 2) {
              setState(() => _step = 1);
            } else if (_step == 1) {
              setState(() {
                _step = 0;
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
              const AppLogo(height: 28),
              const SizedBox(height: 8),
              BrandDreamJobTagline(
                crossAxisAlignment: CrossAxisAlignment.start,
                textAlign: TextAlign.start,
                headlineStyle: textTheme.titleSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                taglineStyle: textTheme.titleSmall?.copyWith(
                  color: _themeColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
                spacing: 4,
              ),
              const SizedBox(height: 20),
              Text(
                _step == 0
                    ? 'Forgot Password'
                    : (_step == 1 ? 'Verify Phone' : 'Reset Password'),
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _themeColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _step == 0
                    ? 'Enter your phone number to receive a secure verification code.'
                    : (_step == 1
                        ? 'Enter the 6-digit verification code sent to your phone.'
                        : 'Enter a strong, secure new password for your account.'),
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              if (_step == 0) ...[
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
                  decoration: InputDecoration(
                    hintText: '+91 98765 43210',
                    prefixIcon: Icon(
                      Icons.phone_iphone_rounded,
                      color: _themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Send Verification Code',
                  onPressed: _sendOtp,
                  isLoading: _isLoading,
                  backgroundColor: _themeColor,
                ),
              ] else if (_step == 1) ...[
                Text(
                  'Verification Code',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  onChanged: (v) {
                    if (v.trim().length == 6) {
                      _verifyCode();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Enter 6-digit OTP',
                    counterText: '',
                    prefixIcon: Icon(
                      Icons.lock_person_rounded,
                      color: _themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Verify Code',
                  onPressed: _verifyCode,
                  isLoading: _isLoading,
                  backgroundColor: _themeColor,
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
                          child: Text(
                            'Resend Code',
                            style: TextStyle(fontWeight: FontWeight.w800, color: _themeColor),
                          ),
                        ),
                ),
              ] else ...[
                Text(
                  'New Password',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: _themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirm New Password',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    prefixIcon: Icon(
                      Icons.lock_rounded,
                      color: _themeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Update Password & Login',
                  onPressed: _resetPassword,
                  isLoading: _isLoading,
                  backgroundColor: _themeColor,
                ),
              ],
              const SizedBox(height: 24),
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }
}
