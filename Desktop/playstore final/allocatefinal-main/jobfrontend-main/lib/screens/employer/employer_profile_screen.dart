import '../../services/api_service.dart';
import 'package:flutter/material.dart';
import '../../constants/employer_status_labels.dart';
import '../../main.dart' show RoleSelectionScreen;
import '../../services/app_session.dart';
import '../../services/company_api_service.dart';
import '../../services/fcm_flutter_service.dart';
import '../../utils/app_colors.dart';
import '../../mixins/auto_reload_on_reconnect.dart';
import '../../constants/industry_types.dart';
import 'employer_company_edit_screen.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen>
    with AutoReloadOnReconnect {
  final _api = CompanyApiService.instance;

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _company;

  @override
  void onNetworkRestored() => _load(allowAutoRetry: false);

  @override
  bool shouldReloadOnReconnect() => _error != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool allowAutoRetry = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final c = await _api.getProfile();
      if (!mounted) return;
      setState(() {
        _company = c;
        _loading = false;
      });

      final logo = c['company_logo_url']?.toString() ??
          c['company_logo']?.toString();
      if (logo != null && logo.trim().isNotEmpty) {
        AppSession.companyLogoNotifier.value = logo.trim();
      }
    } catch (e) {
      if (!mounted) return;
      if (allowAutoRetry) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!mounted) return;
        return _load(allowAutoRetry: false);
      }
      setState(() {
        _error = ApiService.messageFromException(e);
        _loading = false;
      });
    }
  }

  Future<void> _openEdit() async {
    final c = _company;
    if (c == null) return;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EmployerCompanyEditScreen(initial: Map<String, dynamic>.from(c)),
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
      await _load();
    }
  }

  Future<void> _logout() async {
    await FcmFlutterService.instance.unregisterTokenOnLogout();
    await AppSession.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final c = _company!;
    final name = c['name']?.toString() ?? 'Company';
    final rawLogo = c['company_logo_url']?.toString() ?? c['company_logo']?.toString();
    final trimmedLogo = rawLogo?.trim() ?? '';
    final companyLogoUrl =
        trimmedLogo.isNotEmpty &&
                (trimmedLogo.startsWith('http://') ||
                    trimmedLogo.startsWith('https://'))
            ? trimmedLogo
            : null;
    final labelWidth =
        (MediaQuery.of(context).size.width * 0.34).clamp(90.0, 150.0);
    final initials = name.isNotEmpty
        ? name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : 'C';
    final vStatus = c['verification_status']?.toString() ?? 'unverified';
    final verified = vStatus == 'verified';
    final completionRaw = c['profile_completion_percent'];
    final completion = completionRaw is int
        ? completionRaw
        : int.tryParse(completionRaw?.toString() ?? '');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ValueListenableBuilder<String?>(
                            valueListenable: AppSession.companyLogoNotifier,
                            builder: (context, logoUrl, _) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: (logoUrl != null && logoUrl.isNotEmpty)
                                      ? Image.network(
                                          logoUrl,
                                          fit: BoxFit.contain,
                                          width: 80,
                                          height: 80,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              initials.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initials.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: _openEdit,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Icon(
                            verified
                                ? Icons.verified_rounded
                                : Icons.pending_outlined,
                            size: 18,
                            color: Colors.white.withOpacity(0.95),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            CompanyVerificationValue.label(vStatus),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (completion != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pie_chart_outline_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Profile strength',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '$completion%',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (completion.clamp(0, 100)) / 100,
                                minHeight: 8,
                                backgroundColor: Colors.white,
                                color: AppColors.primary,
                              ),
                            ),
                            if (completion < 80) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Add location, bio, team & more to build trust with candidates.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  _section(
                    'Company',
                    Icons.business_rounded,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row(
                          'Industry / sector',
                          industryTypeLabel(c['industry_type']?.toString()),
                          labelWidth: labelWidth,
                        ),
                        _row(
                          'Industry notes',
                          (c['industry']?.toString().trim().isNotEmpty == true)
                              ? c['industry'].toString()
                              : '—',
                          labelWidth: labelWidth,
                        ),
                        _row(
                          'Website',
                          c['website']?.toString() ?? '—',
                          labelWidth: labelWidth,
                        ),
                        _row(
                          'GST',
                          c['gst_number']?.toString() ?? '—',
                          labelWidth: labelWidth,
                        ),
                        _row(
                          'Location',
                          c['location']?.toString() ?? '—',
                          labelWidth: labelWidth,
                        ),
                        _row(
                          'Established',
                          c['established_year'] != null
                              ? c['established_year'].toString()
                              : '—',
                          labelWidth: labelWidth,
                        ),
                        _row(
                          'Verification',
                          CompanyVerificationValue.label(vStatus),
                          labelWidth: labelWidth,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'What we do',
                    Icons.work_outline_rounded,
                    Text(
                      c['what_we_do']?.toString() ??
                          'Describe your products or services in Edit profile.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'Short description',
                    Icons.short_text_rounded,
                    Text(
                      c['description']?.toString() ?? '—',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _section(
                    'About company',
                    Icons.article_outlined,
                    Text(
                      c['about_company']?.toString() ??
                          c['company_bio']?.toString() ??
                          'Tell your story — culture, mission, team size.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if ((c['benefits']?.toString().isNotEmpty == true) ||
                      (c['salary_insights']?.toString().isNotEmpty == true)) ...[
                    _section(
                      'Benefits & Perks',
                      Icons.card_giftcard_rounded,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c['benefits']?.toString().isNotEmpty == true)
                            _bulletedList(c['benefits'].toString(), textTheme),
                          if (c['salary_insights']?.toString().isNotEmpty == true)
                            _bulletedList(c['salary_insights'].toString(), textTheme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),
                  _section(
                    'Team',
                    Icons.groups_2_outlined,
                    _buildTeamList(c['team_members'], textTheme),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(),
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {required double labelWidth}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _teamInitial(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    return n[0].toUpperCase();
  }

  Widget _buildTeamList(dynamic raw, TextTheme textTheme) {
    if (raw is! List || raw.isEmpty) {
      return Text(
        'No team members yet — add them in Edit profile.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }
    final members = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map) {
        members.add(Map<String, dynamic>.from(e));
      }
    }
    if (members.isEmpty) {
      return Text(
        'No team members yet.',
        style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in members)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  child: Text(
                    _teamInitial(m['name']?.toString()),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m['name']?.toString() ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (m['role'] != null &&
                          m['role'].toString().trim().isNotEmpty)
                        Text(
                          m['role'].toString(),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      if (m['email'] != null &&
                          m['email'].toString().trim().isNotEmpty)
                        Text(
                          m['email'].toString(),
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _bulletedList(String text, TextTheme textTheme) {
    final lines = text
        .split(RegExp(r'[\n•]'))
        .where((s) => s.trim().isNotEmpty)
        .map((s) => s.trim())
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 5, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    line,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
