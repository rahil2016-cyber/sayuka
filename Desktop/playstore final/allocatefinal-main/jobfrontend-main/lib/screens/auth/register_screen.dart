import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';
import '../../services/location_service.dart';
import '../../services/refer_earn_api_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_input_field.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/brand_dream_job_tagline.dart';
import '../job_seeker/job_seeker_home.dart';
import '../job_seeker/job_seeker_onboarding_screen.dart';
import '../employer/employer_home.dart';
import 'job_seeker_otp_login.dart';
import 'employer_otp_login.dart';

/// Registration: collect profile details, then OTP (same API as login with [intent]: register).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.showJobSeeker = true});

  final bool showJobSeeker;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// 0 = details form, 1 = OTP, 2 = password setup
  int _step = 0;

  bool _isPhone = true;
  bool _isLoading = false;

  // Job seeker
  final TextEditingController _seekerNameController = TextEditingController();
  final TextEditingController _seekerContactController = TextEditingController();
  final TextEditingController _seekerEmailController = TextEditingController();
  final TextEditingController _seekerCityController = TextEditingController();
  final TextEditingController _seekerHeadlineController = TextEditingController();

  // Location selection (Full India)
  String? _seekerState;
  String? _seekerDistrict;
  List<String> _seekerDistricts = [];

  // Company
  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _companyCityController = TextEditingController();

  final TextEditingController _gstController = TextEditingController();
  final TextEditingController _hiringController = TextEditingController();

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _referralCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final ApiService _apiService = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  int? _resendToken;
  int _secondsRemaining = 60;
  Timer? _timer;

  bool _referralValidating = false;
  bool? _referralValid;
  String? _referralMessage;
  bool _loadingLocations = false;
  List<String> _states = [];

  bool _hideHiringCompany = false;

  String? _companyState;
  String? _companyDistrict;
  List<String> _companyDistricts = [];

  bool get _isJobSeeker => widget.showJobSeeker;
  bool get _isCompany => !widget.showJobSeeker && _tabController.index == 0;
  bool get _isConsultancy => !widget.showJobSeeker && _tabController.index == 1;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.showJobSeeker ? 1 : 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_step == 0) {
        setState(() {
          _referralValid = null;
          _referralMessage = null;
        });
      }
    });

    _loadLocations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _seekerNameController.dispose();
    _seekerContactController.dispose();
    _seekerEmailController.dispose();
    _seekerCityController.dispose();
    _seekerHeadlineController.dispose();
    _adminNameController.dispose();
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _companyPhoneController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    _companyCityController.dispose();
    _gstController.dispose();
    _hiringController.dispose();
    _otpController.dispose();
    _referralCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() => _loadingLocations = true);
    try {
      final s = await LocationService.instance.getStates();
      if (!mounted) return;
      setState(() {
        _states = s;
        _loadingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocations = false);
    }
  }

  Future<void> _setSeekerState(String? state) async {
    setState(() {
      _seekerState = state;
      _seekerDistrict = null;
      _seekerDistricts = [];
    });
    if (state == null || state.trim().isEmpty) return;

    final districts = await LocationService.instance.getDistricts(state);
    if (!mounted) return;
    setState(() => _seekerDistricts = districts);
  }

  Future<void> _setCompanyState(String? state) async {
    setState(() {
      _companyState = state;
      _companyDistrict = null;
      _companyDistricts = [];
    });
    if (state == null || state.trim().isEmpty) return;

    final districts = await LocationService.instance.getDistricts(state);
    if (!mounted) return;
    setState(() => _companyDistricts = districts);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final w = MediaQuery.of(context).size.width;
    final hPad = w > 600 ? 48.0 : 24.0;
    final maxContent = w > 560 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (_step == 2) {
              setState(() {
                _step = 1;
              });
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContent),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        AppLogo(),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                      spacing: 6,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _step == 0
                          ? 'Create account'
                          : (_step == 1 ? 'Verify your contact' : 'Create Password'),
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _isJobSeeker || _step == 1 ? AppColors.primary : AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _step == 0
                          ? 'Tell us a bit about you. OTP verification option is included.'
                          : (_step == 1
                              ? 'Enter the 6-digit code we sent. Companies are reviewed before full verification.'
                              : 'Choose a secure password to access your account anytime.'),
                      style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    if (_step == 0) ...[
                      if (!widget.showJobSeeker) ...[
                        _buildRoleTabs(),
                        const SizedBox(height: 24),
                      ],
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        child: _isJobSeeker
                            ? _buildJobSeekerForm(textTheme)
                            : _buildCompanyForm(textTheme,
                                isConsultancy: _isConsultancy),
                      ),
                      const SizedBox(height: 28),
                      CustomButton(
                        text: 'Send verification code',
                        onPressed: _sendRegistrationOtp,
                        isLoading: _isLoading,
                        backgroundColor: _isJobSeeker ? AppColors.primary : AppColors.accent,
                      ),
                    ] else if (_step == 1) ...[
                      _buildOtpStep(textTheme, hPad),
                    ] else ...[
                      _buildPasswordStep(textTheme),
                    ],
                    const SizedBox(height: 28),
                    if (_step == 0) _buildFooter(textTheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoleTabs() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (_isJobSeeker ? AppColors.primary : AppColors.accent).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: [
          if (widget.showJobSeeker) const Tab(text: 'Job seeker'),
          const Tab(text: 'Company'),
          const Tab(text: 'Consultancy'),
        ],
      ),
    );
  }

  Widget _buildJobSeekerForm(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Full name', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'As on your ID / resume',
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        _label('Phone number', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerContactController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+91 98765 43210',
            prefixIcon: Icon(
              Icons.phone_iphone_rounded,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('Email', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'e.g. you@example.com',
            prefixIcon: Icon(
              Icons.email_outlined,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('State', textTheme),
        const SizedBox(height: 8),
        _loadingLocations
            ? const LinearProgressIndicator(minHeight: 6)
            : DropdownButtonFormField<String>(
                value: _seekerState,
                items: _states
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  hintText: 'Select state',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _setSeekerState(v),
              ),
        const SizedBox(height: 16),
        _label('District', textTheme),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _seekerDistrict,
          items: _seekerDistricts
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d),
                  ))
              .toList(),
          decoration: const InputDecoration(
            hintText: 'Select district',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _seekerDistrict = v),
        ),
        const SizedBox(height: 16),
        _label('City (writeable)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerCityController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Bengaluru',
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppColors.primary),
              onPressed: () async {
                final loc = await LocationService.instance.getCurrentLocation();
                if (loc != null) setState(() => _seekerCityController.text = loc);
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('Professional headline (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _seekerHeadlineController,
          decoration: const InputDecoration(
            hintText: 'e.g. Flutter developer · 3 yrs exp',
            prefixIcon: Icon(Icons.work_outline_rounded, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 18),
        _buildReferralCodeField(textTheme, accent: AppColors.primary),
      ],
    );
  }

  Widget _buildCompanyForm(TextTheme textTheme, {bool isConsultancy = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _verificationInfoCard(),
        const SizedBox(height: 20),
        _label('Your name', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _adminNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Primary contact person',
            prefixIcon: Icon(Icons.person_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label(isConsultancy ? 'Consultancy name' : 'Company name', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _companyNameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: isConsultancy ? 'Consultancy name' : 'Registered business name',
            prefixIcon: Icon(Icons.business_rounded, color: AppColors.accent),
          ),
        ),
        if (isConsultancy) ...[
          const SizedBox(height: 18),
          _label('Company you usually hire for', textTheme),
          const SizedBox(height: 8),
          TextField(
            controller: _hiringController,
            decoration: const InputDecoration(
              hintText: 'e.g. Google, Amazon',
              prefixIcon: Icon(Icons.handshake_outlined, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _hideHiringCompany,
                onChanged: (v) =>
                    setState(() => _hideHiringCompany = v ?? false),
                activeColor: AppColors.accent,
              ),
              const Expanded(
                child: Text(
                  "Don't show this information to candidate",
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        _label('Business email', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _companyEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            hintText: 'hr@company.com',
            prefixIcon: Icon(Icons.alternate_email_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('Business phone number', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _companyPhoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+91 98765 43210',
            prefixIcon: Icon(
              Icons.phone_iphone_rounded,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('Industry (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _industryController,
          decoration: const InputDecoration(
            hintText: 'e.g. IT Services, Healthcare',
            prefixIcon: Icon(Icons.category_outlined, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('Website (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _websiteController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            hintText: 'https://',
            prefixIcon: Icon(Icons.language_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('GST number (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _gstController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'e.g. 27ABCDE1234F1Z5',
            prefixIcon: Icon(Icons.receipt_long_rounded, color: AppColors.accent),
          ),
        ),
        const SizedBox(height: 18),
        _label('State', textTheme),
        const SizedBox(height: 8),
        _loadingLocations
            ? const LinearProgressIndicator(minHeight: 6)
            : DropdownButtonFormField<String>(
                value: _companyState,
                items: _states
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  hintText: 'Select state',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => _setCompanyState(v),
              ),
        const SizedBox(height: 16),
        _label('District', textTheme),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _companyDistrict,
          items: _companyDistricts
              .map((d) => DropdownMenuItem(
                    value: d,
                    child: Text(d),
                  ))
              .toList(),
          decoration: const InputDecoration(
            hintText: 'Select district',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => setState(() => _companyDistrict = v),
        ),
        const SizedBox(height: 16),
        _label('City (writeable)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _companyCityController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Pune',
            prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.accent),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location_rounded, color: AppColors.accent),
              onPressed: () async {
                final loc = await LocationService.instance.getCurrentLocation();
                if (loc != null) setState(() => _companyCityController.text = loc);
              },
            ),
          ),
        ),
      ],
    );
  }

  String get _registrationAudience =>
      _isJobSeeker ? 'job_seeker' : 'company';

  Widget _buildReferralCodeField(TextTheme textTheme, {required Color accent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Referral / promo code (optional)', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _referralCodeController,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) {
            setState(() {
              _referralValid = null;
              _referralMessage = null;
            });
          },
          onSubmitted: (_) => _validateReferralCode(),
          decoration: InputDecoration(
            hintText: 'Enter code if you have one',
            prefixIcon: Icon(Icons.card_giftcard_outlined, color: accent),
            suffixIcon: _referralValidating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : (_referralValid == true
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
                    : (_referralValid == false
                        ? const Icon(Icons.error_outline_rounded, color: AppColors.error)
                        : IconButton(
                            icon: Icon(Icons.verified_outlined, color: accent),
                            onPressed: _validateReferralCode,
                            tooltip: 'Check code',
                          ))),
          ),
        ),
        if (_referralMessage != null) ...[
          const SizedBox(height: 6),
          Text(
            _referralMessage!,
            style: TextStyle(
              fontSize: 12,
              color: _referralValid == true ? AppColors.success : AppColors.error,
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          _isJobSeeker
              ? 'Job seeker codes only. Employer subscription coupons are not valid here.'
              : 'Employer referral codes only. Subscription coupons are used after signup under Subscriptions.',
          style: TextStyle(fontSize: 11, color: AppColors.textHint, height: 1.3),
        ),
      ],
    );
  }

  Future<void> _validateReferralCode() async {
    final code = _referralCodeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _referralValid = null;
        _referralMessage = null;
      });
      return;
    }

    setState(() {
      _referralValidating = true;
      _referralValid = null;
      _referralMessage = null;
    });

    try {
      final result = await ReferEarnApiService.instance.validateReferralCode(
        code: code,
        audience: _registrationAudience,
      );
      if (!mounted) return;
      final valid = result['valid'] == true;
      setState(() {
        _referralValidating = false;
        _referralValid = valid;
        _referralMessage = result['message']?.toString() ??
            (valid ? 'Code is valid.' : 'Invalid code.');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _referralValidating = false;
        _referralValid = false;
        _referralMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _verificationInfoCard() {
    return Material(
      color: AppColors.accentLight.withOpacity(0.5),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.verified_user_outlined, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your company is not verified immediately. '
                'After signup you can post jobs; unverified companies may need admin approval before listings go live.',
                style: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.9),
                  height: 1.4,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneEmailToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleChip(
              title: 'Phone',
              selected: _isPhone,
              onTap: () => setState(() => _isPhone = true),
            ),
          ),
          Expanded(
            child: _toggleChip(
              title: 'Email',
              selected: !_isPhone,
              onTap: () => setState(() => _isPhone = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _label(String text, TextTheme textTheme) {
    return Text(
      text,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildOtpStep(TextTheme textTheme, double hPad) {
    final contact = _isJobSeeker
        ? _seekerContactController.text.trim()
        : _companyPhoneController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code sent to phone $contact',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        Text(
          'Enter the 6-digit verification code.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Center(
          child: OtpInputField(
            controller: _otpController,
            onCompleted: (_) => _verifyRegistration(),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Verify & create account',
          onPressed: _verifyRegistration,
          isLoading: _isLoading,
          backgroundColor: _isJobSeeker ? AppColors.primary : AppColors.accent,
        ),
        const SizedBox(height: 24),
        Center(
          child: _secondsRemaining > 0
              ? Text(
                  'Resend code in $_secondsRemaining seconds',
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _sendRegistrationOtp,
                  child: Text(
                    'Resend Code',
                    style: TextStyle(
                      color: _isJobSeeker ? AppColors.primary : AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Choose a Password', textTheme),
        const SizedBox(height: 8),
        Text(
          'Password must be at least 8 characters long and include a mix of capital letters, small letters, numbers, and special characters.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter password',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: _isJobSeeker ? AppColors.primary : AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _label('Confirm Password', textTheme),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Confirm password',
            prefixIcon: Icon(
              Icons.lock_rounded,
              color: _isJobSeeker ? AppColors.primary : AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 28),
        CustomButton(
          text: 'Complete Signup',
          isLoading: _isLoading,
          onPressed: _completeSignupWithPassword,
          backgroundColor: _isJobSeeker ? AppColors.primary : AppColors.accent,
        ),
      ],
    );
  }

  Future<void> _completeSignupWithPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      _snack('Please enter a password');
      return;
    }
    if (password.length < 8) {
      _snack('Password must be at least 8 characters long');
      return;
    }
    if (password != confirm) {
      _snack('Passwords do not match');
      return;
    }

    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasLowercase || !hasDigits || !hasSpecial) {
      _snack('Password must contain uppercase, lowercase, numbers, and special characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.setPassword(password);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (_isJobSeeker) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const JobSeekerOnboardingScreen(),
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
        _snack(ApiService.messageFromException(e));
      }
    }
  }

  Widget _buildFooter(TextTheme textTheme) {
    return Column(
      children: [
        const Divider(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            Text('Already registered? ', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            TextButton(
              onPressed: () {
                if (_isJobSeeker) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const JobSeekerOtpLoginScreen()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const EmployerOtpLoginScreen()),
                  );
                }
              },
              child: const Text('Log in'),
            ),
          ],
        ),
      ],
    );
  }

  bool _validateSeeker() {
    if (_seekerNameController.text.trim().isEmpty) {
      _snack('Please enter your full name');
      return false;
    }
    if (_seekerState == null || _seekerState!.trim().isEmpty) {
      _snack('Please select your state');
      return false;
    }
    if (_seekerDistrict == null || _seekerDistrict!.trim().isEmpty) {
      _snack('Please select your district');
      return false;
    }
    final c = _seekerContactController.text.trim();
    if (c.isEmpty) {
      _snack('Please enter your phone number');
      return false;
    }
    final digits = RegExp(r'\d').allMatches(c).length;
    if (digits < 10) {
      _snack('Please enter a valid phone number');
      return false;
    }
    final em = _seekerEmailController.text.trim();
    if (em.isEmpty) {
      _snack('Please enter your email address');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(em)) {
      _snack('Please enter a valid email address');
      return false;
    }
    return true;
  }

  bool _validateCompany() {
    if (_adminNameController.text.trim().isEmpty) {
      _snack('Please enter your name');
      return false;
    }
    if (_companyState == null || _companyState!.trim().isEmpty) {
      _snack('Please select your state');
      return false;
    }
    if (_companyDistrict == null || _companyDistrict!.trim().isEmpty) {
      _snack('Please select your district');
      return false;
    }
    if (_companyNameController.text.trim().isEmpty) {
      _snack(_isConsultancy ? 'Please enter consultancy name' : 'Please enter company name');
      return false;
    }
    final email = _companyEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Please enter a valid business email');
      return false;
    }
    final phone = _companyPhoneController.text.trim();
    if (phone.isEmpty) {
      _snack('Please enter your phone number');
      return false;
    }
    final digits = RegExp(r'\d').allMatches(phone).length;
    if (digits < 10) {
      _snack('Please enter a valid phone number');
      return false;
    }
    return true;
  }

  Future<void> _sendRegistrationOtp() async {
    if (_step == 0) {
      if (_isJobSeeker) {
        if (!_validateSeeker()) return;
      } else {
        if (!_validateCompany()) return;
      }
    }

    String phone = _isJobSeeker
        ? _seekerContactController.text.trim()
        : _companyPhoneController.text.trim();

    // Auto prepend +91 (India) if user enters standard 10 digit number
    if (!phone.startsWith('+')) {
      if (phone.length == 10) {
        phone = '+91$phone';
      } else {
        _snack('Please enter phone number with country code (e.g. +91...)');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
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
              await _registerToBackend(idToken);
            }
          } catch (e) {
            if (mounted) {
              setState(() => _isLoading = false);
              _snack(e.toString());
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            setState(() => _isLoading = false);
            _snack(e.message ?? 'Verification failed.');
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
            _snack('Verification code sent to $phone', err: false);
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
        _snack(e.toString());
      }
    }
  }

  Future<void> _verifyRegistration() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      _snack('Please enter the 6-digit verification code');
      return;
    }
    if (_verificationId == null) {
      _snack('Session expired. Please request OTP again.');
      return;
    }

    final referralRaw = _isJobSeeker ? _referralCodeController.text.trim() : '';
    if (referralRaw.isNotEmpty) {
      if (_referralValid != true) {
        await _validateReferralCode();
        if (_referralValid != true) {
          _snack(_referralMessage ?? 'Please enter a valid referral code or leave it empty');
          return;
        }
      }
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
        await _registerToBackend(idToken);
      } else {
        throw Exception('Failed to retrieve ID token from Firebase');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack(e is FirebaseAuthException ? (e.message ?? e.toString()) : e.toString());
      }
    }
  }

  Future<void> _registerToBackend(String idToken) async {
    final referralRaw = _isJobSeeker ? _referralCodeController.text.trim() : '';
    final referralCode = referralRaw.isEmpty ? null : referralRaw;

    try {
      if (_isJobSeeker) {
        await _apiService.authenticateWithFirebaseToken(
          idToken: idToken,
          role: 'job_seeker',
          name: _seekerNameController.text.trim(),
          email: _seekerEmailController.text.trim(),
          state: _seekerState,
          district: _seekerDistrict,
          city: _seekerCityController.text.trim().isEmpty
              ? null
              : _seekerCityController.text.trim(),
          referralCode: referralCode,
        );
      } else {
        await _apiService.authenticateWithFirebaseToken(
          idToken: idToken,
          role: 'company',
          name: _adminNameController.text.trim(),
          companyName: _companyNameController.text.trim(),
          gstNumber: _gstController.text.trim().isEmpty
              ? null
              : _gstController.text.trim(),
          state: _companyState,
          district: _companyDistrict,
          city: _companyCityController.text.trim().isEmpty
              ? null
              : _companyCityController.text.trim(),
          referralCode: referralCode,
        );
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _step = 2;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _snack(ApiService.messageFromException(e));
      }
    }
  }

  void _snack(String msg, {bool err = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
