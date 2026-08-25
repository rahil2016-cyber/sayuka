import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/industry_types.dart';
import '../../constants/industry_roles_skills.dart';
import '../../models/job.dart';
import '../../models/top_company.dart';
import '../../models/banner.dart' as banner_model;
import '../../services/app_session.dart' as session;
import '../../services/job_seeker_api_service.dart';
import '../../services/resume_demo_profiles_cache.dart';
import '../../services/resume_html_thumbnail_cache.dart';
import '../../services/banner_api_service.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/connection_error_panel.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';
import 'my_applications_screen.dart';
import 'job_seeker_profile.dart';
import './resume_templates_screen.dart';
import 'resume_preview_navigation.dart';
import 'saved_jobs_screen.dart';
import 'recommended_jobs_screen.dart';
import 'fresh_jobs_screen.dart';
import 'related_jobs_screen.dart';
import 'company_jobs_screen.dart';
import 'top_companies_directory_screen.dart';
import '../../widgets/job_card.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/seeker_html_template_swatch.dart';
import 'spotlight_employers_jobs_screen.dart';
import '../../utils/resume_draft_utils.dart';
import 'settings_screen.dart';
import './career_prep/interview_qa_screen.dart';
import './career_prep/career_article_feed_screen.dart';
import './career_prep/seeker_ai_coach_screen.dart';
import '../../utils/media_url.dart';
import '../../utils/network_user_message.dart';
import '../../mixins/auto_reload_on_reconnect.dart';
import '../../features/resume/adapters/draft_resume_parse.dart';
import '../../features/resume/models/resume_model.dart';
import '../../features/resume/services/resume_seed_from_profile.dart';
import 'resume_html_preview_screen.dart';
import 'resume_dashboard_template_card.dart';
import 'seeker_resume_studio_screen.dart';
import '../../widgets/popular_categories_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../../services/refer_earn_api_service.dart';
import '../../widgets/notification_bell.dart';

import './career_prep/feedback_rate_screen.dart';
import '../common/about_screen.dart';

Future<void> _navigateSeekerResumeStudio(
  BuildContext context, {
  /// When set (e.g. from a dashboard HTML template card), used as draft `template_id`.
  /// When null, uses the draftâ€™s stored `template_id`, or `'1'`.
  String? templateIdOverride,
}) async {
  if (!session.AppSession.isLoggedIn) return;
  try {
    final raw = await JobSeekerApiService.instance.getResumeDrafts();
    final draft = pickBestResumeDraftForPrefill(raw) ?? pickPrimaryResumeDraft(raw);
    int? draftId;
    ResumeModel? initial;
    if (draft != null) {
      final id = int.tryParse(draft['id']?.toString() ?? '') ?? 0;
      draftId = id > 0 ? id : null;
      final parsed = resumeDraftParseForBuilder(draft['content']);
      if (parsed.model != null) {
        initial = parsed.model;
        final title = draft['title']?.toString().trim() ?? '';
        if (title.isNotEmpty) initial = initial!.copyWith(draftTitle: title);
      } else if (parsed.legacy != null) {
        initial = ResumeModel.fromLegacyJsonResume(parsed.legacy!);
      }
    }
    final templateIdForSave =
        templateIdOverride ?? (draft != null ? (draft['template_id']?.toString() ?? '1') : '1');
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SeekerResumeStudioScreen(
          resumeDraftId: draftId,
          initialModel: initial,
          templateIdForSave: templateIdForSave,
        ),
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    }
  }
}

Future<void> _navigateResumeHtmlPreview(
  BuildContext context, {
  String? templateKey,
}) async {
  final key = templateKey ?? 't1_teal_sidebar';
  await openResumeHtmlPreviewWithUserData(context, templateKey: key);
}

class JobSeekerHomeScreen extends StatefulWidget {
  /// Used with [RouteSettings.name] so flows like application success can
  /// `popUntil` the job seeker root.
  static const String routeName = 'JobSeekerHome';

  const JobSeekerHomeScreen({super.key, this.userId, this.token});

  /// From API login; falls back to demo credentials if null.
  final String? userId;
  final String? token;

  @override
  State<JobSeekerHomeScreen> createState() => _JobSeekerHomeScreenState();
}

class _JobSeekerHomeScreenState extends State<JobSeekerHomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;

  // Demo user credentials (replace with real auth state)
  static const String _demoUserId = 'demo-user';
  static const String _demoToken = 'demo-token';

  late final List<Widget> _pages;
  Timer? _seekerTimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ResumeDemoProfilesCache.instance.ensureLoaded();
    for (var v = 0; v < ResumeDemoProfilesCache.instance.variantCount; v++) {
      ResumeHtmlThumbnailCache.instance.preloadVariant(v);
    }
    final uid = widget.userId ?? _demoUserId;
    final tok = widget.token ?? _demoToken;
    _pages = [
      _JobFeedPage(
        userId: uid,
        token: tok,
        onGoToProfileTab: () => setState(() => _currentIndex = 3),
      ),
      const MyApplicationsScreen(),
      SavedJobsScreen(
        userId: uid,
        token: tok,
      ),
      const JobSeekerProfileScreen(),
    ];
    _startSeekerTimeHeartbeat();
  }

  @override
  void dispose() {
    _seekerTimeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSeekerTimeHeartbeat();
    } else {
      _seekerTimeTimer?.cancel();
      _seekerTimeTimer = null;
    }
  }

  /// Reports foreground time to backend for admin â€œJob seeker usageâ€.
  void _startSeekerTimeHeartbeat() {
    _seekerTimeTimer?.cancel();
    if (!session.AppSession.isLoggedIn) return;
    _seekerTimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !session.AppSession.isLoggedIn) return;
      final ls = WidgetsBinding.instance.lifecycleState;
      if (ls != AppLifecycleState.resumed) return;
      JobSeekerApiService.instance.reportTimeSpent(30).then(
        (_) {},
        onError: (_, __) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // If not on the Home tab, switch back to Home tab first
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        // On Home tab → close the app immediately
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        drawer: _AppDrawer(
          userId: widget.userId,
          token: widget.token,
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _JobFeedPage(
                userId: widget.userId ?? _demoUserId,
                token: widget.token ?? _demoToken,
                onGoToProfileTab: () => setState(() => _currentIndex = 3),
              ),
              const MyApplicationsScreen(),
              SavedJobsScreen(
                userId: widget.userId ?? _demoUserId,
                token: widget.token ?? _demoToken,
                key: ValueKey('saved_$_currentIndex'),
              ),
              const JobSeekerProfileScreen(),
            ],
          ),
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.assignment_turned_in_rounded,
                    label: 'Apply',
                    index: 1,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.bookmark_outline_rounded,
                    selectedIcon: Icons.bookmark_rounded,
                    label: 'Saved',
                    index: 2,
                  ),
                ),
                Expanded(
                  child: _buildNavItem(
                    icon: Icons.person_rounded,
                    label: 'Me',
                    index: 3,
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

  Widget _buildNavItem({
    required IconData icon,
    IconData? selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final ic = isSelected && selectedIcon != null ? selectedIcon : icon;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 10 : 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Icon(
              ic,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ==========================================
// Job Feed Page (Home Tab)
// ==========================================
class _JobFeedPage extends StatefulWidget {
  final String userId;
  final String token;
  final VoidCallback onGoToProfileTab;

  const _JobFeedPage({
    this.userId = 'demo-user',
    this.token = 'demo-token',
    required this.onGoToProfileTab,
  });

  @override
  State<_JobFeedPage> createState() => _JobFeedPageState();
}

class _JobFeedPageState extends State<_JobFeedPage>
    with AutomaticKeepAliveClientMixin, AutoReloadOnReconnect {
  @override
  bool get wantKeepAlive => true;

  @override
  void onNetworkRestored() => _loadJobs();

  @override
  bool shouldReloadOnReconnect() => _loadErrorCause != null;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Job> _jobs = [];
  List<Job> _recommendedJobs = [];
  /// Same companies / industries as the seeker’s applications (`GET /job-seeker/related-jobs`).
  List<Job> _relatedJobs = [];
  /// Recently published listings (`GET /jobs?published_after=`).
  List<Job> _freshJobs = [];
  List<TopCompany> _topCompanies = [];
  /// Published roles from admin “spotlight” employers (`from_top_companies=1`).
  List<Job> _spotlightEmployerJobs = [];
  Set<String> _savedJobIds = {};
  /// Job post IDs the logged-in user has already applied to.
  Set<String> _appliedJobIds = {};
  List<banner_model.PromoBanner> _banners = [];
  bool _isLoading = true;
  /// Set when the main job list fails; used for a full-screen friendly error + optional alert.
  Object? _loadErrorCause;
  Timer? _searchDebounce;
  /// `null` = all industries (server-side filter via `GET /jobs?industry_type=`).
  String? _industryFilter;

  /// From API `profile_completion_percent` — hide prompt when ≥ 70.
  int? _profileCompletionPercent;

  int _popularCategoriesRefreshKey = 0;

  bool _showFeedback = true;
  String _referralCode = '';
  int _referredCount = 0;
  bool _loadingReferral = false;

  // Pagination fields for search results
  int _searchPage = 1;
  bool _hasMoreSearch = true;
  bool _isFetchingMoreSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadJobs();
    _refreshAppliedIds();
    _loadSavedJobIds();
    _searchController.addListener(_onSearchChanged);
    _checkFeedbackStatus();
    _loadReferralInfo();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final bool isSearchActive = _searchController.text.trim().isNotEmpty || _industryFilter != null;
    if (!isSearchActive) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _loadMoreSearch();
    }
  }

  Future<void> _loadMoreSearch() async {
    if (_isFetchingMoreSearch || !_hasMoreSearch || _isLoading) return;
    setState(() {
      _isFetchingMoreSearch = true;
    });
    try {
      final nextPage = _searchPage + 1;
      final jobs = await JobSeekerApiService.instance.listJobs(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        industryType: _industryFilter,
        page: nextPage,
        perPage: 15,
      );
      if (mounted) {
        setState(() {
          _jobs.addAll(jobs);
          _searchPage = nextPage;
          _isFetchingMoreSearch = false;
          if (jobs.length < 15) {
            _hasMoreSearch = false;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingMoreSearch = false;
        });
      }
    }
  }

  /// Loaded inside [_loadJobs] with jobs so one [setState] paints the full feed
  /// (avoids banner sliver inserting later and leaving a blank gap until scroll).
  Future<List<banner_model.PromoBanner>> _fetchBanners() async {
    try {
      return await BannerApiService.instance.getActiveBanners();
    } catch (e) {
      debugPrint('Banners not loaded (feed still works): $e');
      return [];
    }
  }

  Future<List<Job>> _fetchRecommendedJobs() async {
    if (!session.AppSession.isLoggedIn) return [];
    try {
      return await JobSeekerApiService.instance.getRecommendedJobs(perPage: 10);
    } catch (_) {
      return [];
    }
  }

  Future<List<Job>> _fetchRelatedJobs() async {
    if (!session.AppSession.isLoggedIn) return [];
    try {
      return await JobSeekerApiService.instance.getRelatedJobs(perPage: 12);
    } catch (_) {
      return [];
    }
  }

  Future<List<TopCompany>> _fetchTopCompanies() async {
    try {
      return await JobSeekerApiService.instance.getTopCompanies(limit: 16);
    } catch (_) {
      return [];
    }
  }

  Future<List<Job>> _fetchSpotlightEmployerJobs() async {
    try {
      return await JobSeekerApiService.instance.listJobs(
        fromTopCompanies: true,
        perPage: 10,
      );
    } catch (_) {
      return [];
    }
  }

  Future<List<Job>> _fetchFreshJobs() async {
    try {
      return await JobSeekerApiService.instance.listJobs(
        perPage: 12,
      );
    } catch (_) {
      return [];
    }
  }

  Future<int?> _fetchProfileCompletionPercent() async {
    if (!session.AppSession.isLoggedIn) return null;
    try {
      final raw = await JobSeekerApiService.instance.getSeekerProfile();
      final p = raw['profile_completion_percent'];
      return p is int ? p : int.tryParse(p?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadSavedJobIds() async {
    if (!session.AppSession.isLoggedIn) {
      if (mounted) setState(() => _savedJobIds = {});
      return;
    }
    try {
      final saved = await JobSeekerApiService.instance.listSavedJobs(perPage: 100);
      if (mounted) {
        setState(() {
          _savedJobIds = saved.map((j) => j.id).toSet();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _savedJobIds = {});
    }
  }

  Future<void> _refreshAppliedIds() async {
    if (!session.AppSession.isLoggedIn) {
      if (mounted) setState(() => _appliedJobIds = {});
      return;
    }
    try {
      final apps =
          await JobSeekerApiService.instance.listMyApplications(perPage: 100);
      final ids = apps.map((a) => a.jobId).toSet();
      if (mounted) setState(() => _appliedJobIds = ids);
    } catch (_) {
      if (mounted) setState(() => _appliedJobIds = {});
    }
  }

  Future<void> _toggleSaveJob(Job job) async {
    try {
      final jobId = job.id;
      final isSaved = _savedJobIds.contains(job.id);
      if (isSaved) {
        await JobSeekerApiService.instance.unsaveJob(jobId);
      } else {
        await JobSeekerApiService.instance.saveJob(jobId);
      }

      if (mounted) {
        setState(() {
          if (isSaved) {
            _savedJobIds.remove(job.id);
          } else {
            _savedJobIds.add(job.id);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _checkFeedbackStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _showFeedback = !(prefs.getBool('feedback_submitted') ?? false);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadReferralInfo() async {
    if (!session.AppSession.isLoggedIn) return;
    setState(() => _loadingReferral = true);
    try {
      final data = await ReferEarnApiService.instance.fetchReferEarn(audience: 'job_seeker');
      if (mounted) {
        setState(() {
          // API returns `my_referral_code` (not `code`) from ReferEarnService.publicPayload.
          _referralCode = data['my_referral_code']?.toString() ??
              data['code']?.toString() ??
              '';
          _referredCount = int.tryParse(
                data['referrals_count']?.toString() ?? '',
              ) ??
              0;
          _loadingReferral = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingReferral = false);
      }
    }
  }



  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
        _loadJobs();
      }
    });
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _loadErrorCause = null;
      _searchPage = 1;
      _hasMoreSearch = true;
      _isFetchingMoreSearch = false;
    });
    
    // We will start background requests AFTER the main jobs load to prevent 
    // connection pooling/TLS handshake floods on older devices.

    try {
      final list = await JobSeekerApiService.instance.listJobs(
        search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        industryType: _industryFilter,
        page: 1,
        perPage: 15,
      );
      if (!mounted) return;
      
      // Update state immediately so the user can see jobs without waiting for 7 other endpoints!
      setState(() {
        _jobs = list;
        _isLoading = false;
        if (list.length < 15) {
          _hasMoreSearch = false;
        }
      });
      await _refreshAppliedIds();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadErrorCause = e;
        _jobs = [];
        _isLoading = false;
      });
      if (NetworkUserMessage.looksLikeNetwork(e)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showNetworkIssueAlert(context, error: e, onRetry: _loadJobs);
        });
      }
    }

    // Now await the background requests sequentially to avoid TLS flooding
    try {
      final banners = await _fetchBanners();
      if (mounted) {
        setState(() => _banners = banners);
      }
      
      final recommended = await _fetchRecommendedJobs();
      final profilePct = await _fetchProfileCompletionPercent();
      final topCompanies = await _fetchTopCompanies();
      final spotlightJobs = await _fetchSpotlightEmployerJobs();
      final fresh = await _fetchFreshJobs();
      final related = await _fetchRelatedJobs();
      
      if (!mounted) return;
      setState(() {
        _recommendedJobs = recommended;
        _profileCompletionPercent = profilePct;
        _topCompanies = topCompanies;
        _spotlightEmployerJobs = spotlightJobs;
        _freshJobs = fresh;
        _relatedJobs = related;
      });
    } catch (_) {
      // It's okay if background fetches fail occasionally
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final textTheme = Theme.of(context).textTheme;
    final bool isSearchActive = _searchController.text.trim().isNotEmpty || _industryFilter != null;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await Future.wait([
          _loadJobs(),
          _loadSavedJobIds(),
          _refreshAppliedIds(),
        ]);
        if (mounted) {
          setState(() => _popularCategoriesRefreshKey++);
        }
      },
      child: Stack(
        children: [
          ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.zero,
            children: [
              // 🔹 HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Top Bar with centered logo (symmetrical Row to prevent logo overlap)
                     SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              final scaffold =
                                  context.findAncestorStateOfType<ScaffoldState>();
                              scaffold?.openDrawer();
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.menu),
                            ),
                          ),
                          const Expanded(
                            child: Center(
                              child: AppLogo(height: 28),
                            ),
                          ),
                          const SizedBox(
                            width: 44,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: NotificationBell(iconColor: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Hello, ${session.AppSession.user?['name'] ?? 'Welcome'}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),
                    // Search Bar directly on the home page
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by jobs, skills, companies, salary...',
                          hintStyle: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                    if (!isSearchActive) ...[
                      if (_profileCompletionPercent != null &&
                          _profileCompletionPercent! < 70) ...[
                        const SizedBox(height: 16),
                        _ProfileBoostCard(
                          percent: _profileCompletionPercent!,
                          onOpenProfile: widget.onGoToProfileTab,
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              if (isSearchActive) ...[
                // 🔹 SEARCH/FILTER RESULTS
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _industryFilter != null
                                  ? 'Category: $_industryFilter'
                                  : 'Search Results',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Showing ${_jobs.length} job${_jobs.length == 1 ? '' : 's'}',
                              style: textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _industryFilter = null;
                            _loadJobs();
                          });
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Clear search'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_jobs.isNotEmpty) ...[
                  ..._jobs.map((job) {
                    final isSaved = _savedJobIds.contains(job.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: JobCardWidget(
                        job: job,
                        hasApplied: _appliedJobIds.contains(job.id),
                        isBookmarked: isSaved,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => JobDetailScreen(
                                job: job,
                                userId: widget.userId,
                                token: widget.token,
                                isBookmarked: isSaved,
                                hasApplied: _appliedJobIds.contains(job.id),
                              ),
                            ),
                          );
                          if (mounted) {
                            await _refreshAppliedIds();
                            await _loadSavedJobIds();
                          }
                        },
                        onApply: () async {
                          final ok = await showApplyJobSheet(context, job);
                          if (ok && mounted) await _refreshAppliedIds();
                        },
                        onBookmark: () => _toggleSaveJob(job),
                      ),
                    );
                  }),
                  if (_isFetchingMoreSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                ] else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.textHint.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We couldn\'t find any jobs matching your criteria. Try adjusting your search query or reset filters.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _industryFilter = null;
                              _loadJobs();
                            });
                          },
                          child: const Text('Reset search'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 48),
              ] else ...[
                const SizedBox(height: 16),

                // ðŸ”¹ BANNERS
                if (_banners.isNotEmpty) ...[
                  BannerCarousel(banners: _banners),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 8),

                PopularCategoriesSection(
                  key: ValueKey<int>(_popularCategoriesRefreshKey),
                  userId: session.AppSession.userId ?? widget.userId,
                  token: session.AppSession.token ?? widget.token,
                ),

                const SizedBox(height: 24),

                // 🔸 WHAT'S NEW — recently published
                if (_freshJobs.isNotEmpty) ...[
                  _HorizontalJobSection(
                    title: "What's new",
                    count: _freshJobs.length,
                    jobs: _freshJobs,
                    onJobTap: (job) => _navigateToJobDetail(context, job),
                    onViewAll: () => _openFreshJobsFullList(context),
                    savedJobIds: _savedJobIds,
                    onBookmark: _toggleSaveJob,
                  ),
                  const SizedBox(height: 24),
                ],

                // 🔸 JOBS BASED ON PROFILE
                if (_recommendedJobs.isNotEmpty) ...[
                  _HorizontalJobSection(
                    title: 'Jobs based on your profile',
                    count: _recommendedJobs.length,
                    jobs: _recommendedJobs,
                    onJobTap: (job) => _navigateToJobDetail(context, job),
                    onViewAll: () => _openRecommendedFullList(context),
                    savedJobIds: _savedJobIds,
                    onBookmark: _toggleSaveJob,
                  ),
                  const SizedBox(height: 24),
                ],

                // 🔸 CAREER ROADMAP
                const _CareerRoadmapSection(),
                const SizedBox(height: 24),

                // 🔸 TOP COMPANIES — verified employers with open roles
                _TopCompaniesSection(
                  companies: _topCompanies,
                  userId: widget.userId,
                  token: widget.token,
                ),
                const SizedBox(height: 24),

                // 🔸 RELATED TO YOUR APPLICATIONS
                if (_relatedJobs.isNotEmpty) ...[
                  _HorizontalJobSection(
                    title: 'More like jobs you applied to',
                    count: _relatedJobs.length,
                    jobs: _relatedJobs,
                    onJobTap: (job) => _navigateToJobDetail(context, job),
                    onViewAll: () => _openRelatedFullList(context),
                    savedJobIds: _savedJobIds,
                    onBookmark: _toggleSaveJob,
                  ),
                  const SizedBox(height: 24),
                ],

                // ðŸ”¹ INTERVIEW PREP
                const _InterviewPrepSection(),
                const SizedBox(height: 32),

                // ðŸ”¹ FEEDBACK EMOJI BOX
                if (_showFeedback) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildFeedbackCard(),
                  ),
                  const SizedBox(height: 32),
                ],

                // ðŸ”¹ RESUME MAKER
                const _ResumeMakerSection(),
                const SizedBox(height: 32),

                // ðŸ”¹ REFER & EARN BOX
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildReferCard(),
                ),
                const SizedBox(height: 32),

                // ðŸ”¹ JOBS FROM SPOTLIGHT EMPLOYERS (admin-pinned companies)
                if (_spotlightEmployerJobs.isNotEmpty) ...[
                  _HorizontalJobSection(
                    title: 'Jobs from spotlight employers',
                    count: _spotlightEmployerJobs.length,
                    jobs: _spotlightEmployerJobs,
                    onJobTap: (job) => _navigateToJobDetail(context, job),
                    onViewAll: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpotlightEmployersJobsScreen(
                            userId: widget.userId,
                            token: widget.token,
                          ),
                        ),
                      );
                    },
                    savedJobIds: _savedJobIds,
                    onBookmark: _toggleSaveJob,
                  ),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 48),
              ],
        ],
      ),
      if (_isLoading && _jobs.isEmpty)
        const Positioned(
          top: 180, // Allow the top header "Hello User" to show instantly!
          left: 0,
          right: 0,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      if (!_isLoading && _jobs.isEmpty && _loadErrorCause != null)
        Positioned.fill(
          child: Material(
            color: AppColors.background,
            child: ConnectionErrorPanel(
              title: () {
                final d = NetworkUserMessage.describe(_loadErrorCause!);
                return d?.title ??
                    NetworkUserMessage.connectivityTitle;
              }(),
              message: () {
                final d = NetworkUserMessage.describe(_loadErrorCause!);
                return d?.message ?? NetworkUserMessage.connectivityBody;
              }(),
              onRetry: _loadJobs,
            ),
          ),
        ),
    ],
  ),
);
}

  void _navigateToJobDetail(BuildContext context, Job job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JobDetailScreen(
          job: job,
          userId: widget.userId,
          token: widget.token,
          // Handle bookmark state correctly if needed
          isBookmarked: _savedJobIds.contains(job.id),
        ),
      ),
    );
  }

  void _openFreshJobsFullList(BuildContext context) {
    final uid = session.AppSession.userId ?? widget.userId;
    final tok = session.AppSession.token ?? widget.token;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FreshJobsScreen(userId: uid, token: tok),
      ),
    );
  }

  void _openRecommendedFullList(BuildContext context) {
    final uid = session.AppSession.userId ?? widget.userId;
    final tok = session.AppSession.token ?? widget.token;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecommendedJobsScreen(userId: uid, token: tok),
      ),
    );
  }

  void _openRelatedFullList(BuildContext context) {
    final uid = session.AppSession.userId ?? widget.userId;
    final tok = session.AppSession.token ?? widget.token;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RelatedJobsScreen(userId: uid, token: tok),
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchBottomSheet(
        onSearch: (query, location) {
          _searchController.text = query;
          // Optionally handle location filter here if API supports it
          _loadJobs();
        },
      ),
    );
  }

  Widget _buildFeedbackCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How is your experience with us? \u{1F60A}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildEmojiButton('\u{1F620}', 1)),
              Expanded(child: _buildEmojiButton('\u{1F641}', 2)),
              Expanded(child: _buildEmojiButton('\u{1F610}', 3)),
              Expanded(child: _buildEmojiButton('\u{1F642}', 4)),
              Expanded(child: _buildEmojiButton('\u{1F604}', 5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, int rating) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          try {
            await JobSeekerApiService.instance.submitSeekerFeedback(rating: rating);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('feedback_submitted', true);
            if (mounted) {
              setState(() {
                _showFeedback = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Thank you for your feedback! â¤ï¸'),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.all(16),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit feedback: $e')),
              );
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            shape: BoxShape.circle,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }

  Widget _buildReferCard() {
    final double progress = (_referredCount / 25).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Refer & Earn Free Resume!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Refer 25 friends who register/login, and get 1 premium resume download completely for free!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (_referralCode.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR REFERRAL CODE',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _referralCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _referralCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Referral code copied to clipboard!'),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.all(16),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Referral Progress: $_referredCount/25',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (progress >= 1.0)
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent)
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBottomSheet extends StatefulWidget {
  final Function(String query, String location) onSearch;
  const _SearchBottomSheet({required this.onSearch});

  @override
  State<_SearchBottomSheet> createState() => _SearchBottomSheetState();
}

class _SearchBottomSheetState extends State<_SearchBottomSheet> {
  final _queryController = TextEditingController();
  final _locationController = TextEditingController();
  String _type = 'Jobs';
  
  late final List<String> _roleOptions;
  late final List<String> _locationOptions;

  @override
  void initState() {
    super.initState();
    final Set<String> roles = {};
    for (var ind in kIndustryTypes) {
      roles.add(ind.label);
    }
    for (var industry in kAllRolesAndSkillsByIndustry.values) {
      roles.addAll(industry.keys);
    }
    _roleOptions = roles.toList()..sort();
    
    _locationOptions = [
      'Ahmedabad', 'Agra', 'Allahabad', 'Amritsar', 'Aurangabad',
      'Bengaluru', 'Bhopal', 'Chennai', 'Chandigarh', 'Coimbatore',
      'Delhi', 'Dhanbad', 'Faridabad', 'Ghaziabad', 'Guwahati',
      'Gwalior', 'Howrah', 'Hubli-Dharwad', 'Hyderabad', 'Indore',
      'Jabalpur', 'Jaipur', 'Jodhpur', 'Kalyan-Dombivli', 'Kanpur',
      'Kolkata', 'Kota', 'Lucknow', 'Ludhiana', 'Madurai', 'Meerut',
      'Mumbai', 'Nagpur', 'Nashik', 'Navi Mumbai', 'Patna',
      'Pimpri-Chinchwad', 'Pune', 'Raipur', 'Rajkot', 'Ranchi',
      'Solapur', 'Srinagar', 'Surat', 'Thane', 'Vadodara',
      'Varanasi', 'Vasai-Virar', 'Vijayawada', 'Visakhapatnam',
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Find opportunities for you',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildRadio('Internships'),
                    const SizedBox(width: 24),
                    _buildRadio('Jobs'),
                  ],
                ),
                const SizedBox(height: 32),
                _buildAutocompleteField(
                  controller: _queryController,
                  hint: 'Designation, skill and company',
                  options: _roleOptions,
                ),
                const SizedBox(height: 16),
                _buildAutocompleteField(
                  controller: _locationController,
                  hint: 'Location',
                  options: _locationOptions,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      widget.onSearch(_queryController.text, _locationController.text);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Show jobs',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadio(String value) {
    final active = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.primary : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: active
                ? Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                  )
                : const SizedBox(width: 10, height: 10),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: active ? FontWeight.w800 : FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String hint,
    required List<String> options,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          final q = textEditingValue.text.toLowerCase();
          return options.where((String option) {
            return option.toLowerCase().contains(q);
          });
        },
        onSelected: (String selection) {
          controller.text = selection;
        },
        fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
          // Sync with our master controller if needed
          fieldTextEditingController.addListener(() {
            controller.text = fieldTextEditingController.text;
          });
          return TextField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
              border: InputBorder.none,
            ),
            onSubmitted: (String value) {
              onFieldSubmitted();
            },
          );
        },
        optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: 220.0,
                width: MediaQuery.of(context).size.width - 48,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                        ),
                        child: Text(
                          option, 
                          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown on home when profile completion is below 70%.
class _ProfileBoostCard extends StatelessWidget {
  const _ProfileBoostCard({
    required this.percent,
    required this.onOpenProfile,
  });

  final int percent;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: AppColors.surface,
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onOpenProfile,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_search_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stand out to employers',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your profile is about $percent% complete. Add headline, bio, skills, location & resume to get shortlisted faster.',
                          style: tt.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$percent% complete',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Update profile',
                    style: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Recommended job card for horizontal scrolling
class _RecommendedJobCard extends StatelessWidget {
  final Job job;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  const _RecommendedJobCard({
    required this.job,
    required this.isSaved,
    required this.onTap,
    required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        job.companyName.isNotEmpty
                            ? job.companyName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onBookmark,
                    child: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.title,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                job.companyName,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.location,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (job.salaryMin != null && job.salaryMax != null)
                Text(
                  'â‚¹${job.salaryMin?.toStringAsFixed(0)} - ${job.salaryMax?.toStringAsFixed(0)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.jobType,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// Career Roadmap Section
// ==========================================
class _CareerRoadmapSection extends StatelessWidget {
  const _CareerRoadmapSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Career Path Roadmaps',
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.map_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Where can I get a roadmap?',
                            style: tt.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Expert-curated paths for success.',
                            style: tt.bodySmall?.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CareerArticleFeedScreen(
                              title: 'Career roadmap',
                              apiType: 'career_guidance',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SeekerAiCoachScreen(kind: 'career_path'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                    label: const Text('AI career plan for my profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// Top Companies â€” `GET /companies/top`
// ==========================================
class _TopCompaniesSection extends StatelessWidget {
  final List<TopCompany> companies;
  final String userId;
  final String token;

  const _TopCompaniesSection({
    required this.companies,
    required this.userId,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return const SizedBox.shrink();
    }

    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Explore jobs by\ntop companies',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopCompaniesDirectoryScreen(
                            userId: userId,
                            token: token,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'View all',
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Verified employers with open roles from the platform. Star = admin spotlight.',
                style: tt.bodySmall?.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final c = companies[index];
              final logoUrl = MediaUrl.resolve(c.logoUrl);
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyJobsScreen(
                          companyId: c.id,
                          companyName: c.name,
                          userId: userId,
                          token: token,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFF1F5F9)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: logoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: logoUrl,
                                      fit: BoxFit.contain,
                                      width: 64,
                                      height: 64,
                                      placeholder: (context, url) => const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Center(
                                        child: Text(
                                          c.name.isNotEmpty
                                              ? c.name[0].toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        c.name.isNotEmpty
                                            ? c.name[0].toUpperCase()
                                            : 'C',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                            ),
                            if (c.isTopCompany)
                              Positioned(
                                top: -6,
                                right: -6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.star_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.work_outline_rounded,
                                  color: Color(0xFF166534), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${c.openJobsCount} open role${c.openJobsCount == 1 ? '' : 's'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF166534),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.6)),
                          ),
                          child: Center(
                            child: Text(
                              'View jobs',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Horizontal Job Section (New)
// ==========================================
class _HorizontalJobSection extends StatelessWidget {
  final String title;
  final int count;
  final List<Job> jobs;
  final Function(Job) onJobTap;
  final VoidCallback? onViewAll;
  final Set<String> savedJobIds;
  final Function(Job)? onBookmark;

  const _HorizontalJobSection({
    required this.title,
    required this.count,
    required this.jobs,
    required this.onJobTap,
    this.onViewAll,
    this.savedJobIds = const {},
    this.onBookmark,
  });

  String _getSalaryText(Job job) {
    if (job.salaryMin != null && job.salaryMax != null) {
      final min = job.salaryMin!;
      final max = job.salaryMax!;
      // Always format as monthly k-value
      String fmt(double v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toStringAsFixed(0);
      return '\u20b9${fmt(min)} - ${fmt(max)}/month';
    }
    if (job.salaryRange.isNotEmpty) {
      String range = job.salaryRange;
      final regExp = RegExp(r'(\d+),?000');
      range = range.replaceAllMapped(regExp, (m) => '${m.group(1)}k');
      return range.contains('k') ? '\u20b9$range/month' : range;
    }
    return '\u20b930k - 60k/month';
  }

  String _getPostedTime(Job job) {
    final difference = DateTime.now().difference(job.createdAt);
    if (difference.inHours < 1) {
      return 'Just now';
    } else if (difference.inHours < 24) {
      return 'Posted ${difference.inHours}h ago';
    } else {
      return 'Posted ${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                    children: [
                      TextSpan(text: title),
                      if (count > 0)
                        TextSpan(
                          text: ' ($count)',
                          style: TextStyle(
                            color: AppColors.textPrimary.withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (onViewAll != null)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onViewAll,
                  child: Text(
                    'View all',
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 235,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              final isSaved = savedJobIds.contains(job.id);
              final isNew = DateTime.now().difference(job.createdAt).inHours < 24;
              final salaryText = _getSalaryText(job);
              final postedTimeText = _getPostedTime(job);

              return GestureDetector(
                onTap: () => onJobTap(job),
                child: Container(
                  width: 250,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1B4B), // Navy circle
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Center(
                              child: job.companyLogoUrl != null && job.companyLogoUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: job.companyLogoUrl!,
                                      fit: BoxFit.contain,
                                      errorWidget: (context, url, error) => Text(
                                        job.companyName.isNotEmpty ? job.companyName[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      job.companyName.isNotEmpty ? job.companyName[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const Spacer(),
                          if (isNew)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        job.companyName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${job.location} • ${job.jobType.replaceAll('_', ' ').split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ')}',
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        salaryText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB), // Blue salary
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9), // Light grey background
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              postedTimeText,
                              style: const TextStyle(
                                color: Colors.black, // Black text
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => onBookmark?.call(job),
                            child: Icon(
                              isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: isSaved ? const Color(0xFFE53E3E) : const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Resume Maker Section
// ==========================================
class _ResumeMakerSection extends StatelessWidget {
  const _ResumeMakerSection({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    const htmlSlots = kSeekerResumeHtmlTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Resume templates',
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              height: 1.25,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 460,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: htmlSlots.length,
            itemBuilder: (context, index) {
              final slot = htmlSlots[index];
              final key = slot['key'] ?? 't1_teal_sidebar';
              final label = slot['label'] ?? 'Template';
              final variant = index % ResumeDemoProfilesCache.instance.variantCount;
              return ResumeDashboardTemplateCard(
                displayLabel: label,
                htmlTemplateKey: key,
                demoVariant: variant,
                onView: () => _navigateResumeHtmlPreview(
                  context,
                  templateKey: key,
                ),
                onEdit: () => _navigateSeekerResumeStudio(
                  context,
                  templateIdOverride: seekerStudioTemplateIdForHtmlKey(key),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// Quick Access Section (2 rows on home)
// ==========================================
class _InterviewPrepSection extends StatelessWidget {
  const _InterviewPrepSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Interview Prep',
                style: tt.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'AI-powered',
                  style: TextStyle(
                    color: Color(0xFF4338CA),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decode commonly asked interview questions.',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InterviewPrepItem(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'AI coach',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SeekerAiCoachScreen(kind: 'interview_prep'),
                        ),
                      ),
                    ),
                    _InterviewPrepItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Prepare',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InterviewQaScreen()),
                      ),
                    ),
                    _InterviewPrepItem(
                      icon: Icons.groups_rounded,
                      label: 'Participate',
                      onTap: () {},
                    ),
                    _InterviewPrepItem(
                      icon: Icons.work_outline_rounded,
                      label: 'Opportunities',
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InterviewPrepItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InterviewPrepItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
class _QuickAccessSection extends StatelessWidget {
  final String? userId;
  final String? token;

  const _QuickAccessSection({this.userId, this.token});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickAccessItem(
        icon: Icons.description_rounded,
        label: 'Resume Maker',
        color: Colors.blue,
        onTap: () {
          final userId = session.AppSession.userId;
          final token = session.AppSession.token;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResumeTemplatesScreen(
                userId: userId ?? 'demo-user',
                token: token ?? 'demo-token',
              ),
            ),
          );
        },
      ),
      _QuickAccessItem(
        icon: Icons.quiz_rounded,
        label: 'Interview Q/A',
        color: const Color(0xFF7C3AED),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InterviewQaScreen()),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.school_rounded,
        label: 'Career Guidance',
        color: const Color(0xFF059669),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CareerArticleFeedScreen(
              title: 'Career guidance',
              apiType: 'career_guidance',
            ),
          ),
        ),
      ),
      _QuickAccessItem(
        icon: Icons.forum_rounded,
        label: 'Interview Experience',
        color: const Color(0xFFD97706),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CareerArticleFeedScreen(
              title: 'Interview experience',
              apiType: 'interview_experience',
            ),
          ),
        ),
      ),
    ];

    // Arrange as 2 rows of 2
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: items[0]),
              const SizedBox(width: 12),
              Expanded(child: items[1]),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: items[2]),
              const SizedBox(width: 12),
              Expanded(child: items[3]),
            ],
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature â€” coming soon!'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// App Drawer
// ==========================================
class _AppDrawer extends StatefulWidget {
  final String? userId;
  final String? token;

  const _AppDrawer({this.userId, this.token});

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  Map<String, dynamic>? _profile;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (!session.AppSession.isLoggedIn) return;
    setState(() => _loadingProfile = true);
    try {
      final data = await JobSeekerApiService.instance.getSeekerProfile();
      if (mounted) setState(() => _profile = data);
    } catch (_) {}
    if (mounted) setState(() => _loadingProfile = false);
  }

  String _initials(String name) {
    final p = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
    return (p.first[0] + p.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = session.AppSession.user;
    final name = user?['name']?.toString() ?? 'Job seeker';

    // Extract location/headline for subtext
    String subtext = 'Complete your profile';
    if (_profile != null) {
      final city = _profile?['city']?.toString() ?? '';
      final country = _profile?['country']?.toString() ?? '';
      final loc = [city, country].where((e) => e.isNotEmpty).join(', ');
      if (loc.isNotEmpty) subtext = loc;
      else if (_profile?['headline']?.toString().isNotEmpty == true) {
        subtext = _profile!['headline'].toString();
      }
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // Logo Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: AppLogo(height: 32),
              ),
            ),
            const Divider(height: 1),

            // Profile Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: session.AppSession.profilePhotoNotifier,
                    builder: (context, _, __) {
                      final raw = _profile?['profile_photo_url']?.toString() ??
                          _profile?['profile_photo']?.toString();
                      final effective = MediaUrl.resolve(
                            session.AppSession.profilePhotoNotifier.value,
                          ) ??
                          MediaUrl.resolve(raw);
                      return ClipOval(
                        child: Container(
                          width: 60,
                          height: 60,
                          color: AppColors.primary.withOpacity(0.1),
                          child: effective != null
                              ? CachedNetworkImage(
                                  imageUrl: effective,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Center(
                                    child: Text(
                                      _initials(name),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtext,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to profile tab
                            // This might need a callback to JobSeekerHomeScreen to switch tab
                          },
                          child: const Text(
                            'View & update profile',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  _DrawerTile(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    color: AppColors.textPrimary,
                    onTap: () => Navigator.pop(context),
                  ),
                  _DrawerTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Recommended Jobs',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecommendedJobsScreen(
                            userId: session.AppSession.userId ??
                                widget.userId ??
                                'demo-user',
                            token: session.AppSession.token ??
                                widget.token ??
                                'demo-token',
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    label: 'Resume Maker',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      _navigateSeekerResumeStudio(context);
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.quiz_outlined,
                    label: 'Interview Q/A',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InterviewQaScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.school_outlined,
                    label: 'Career Guidance',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CareerArticleFeedScreen(
                            title: 'Career guidance',
                            apiType: 'career_guidance',
                          ),
                        ),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.forum_outlined,
                    label: 'Interview Experience',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CareerArticleFeedScreen(
                            title: 'Interview experience',
                            apiType: 'interview_experience',
                          ),
                        ),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Divider(height: 1),
                  ),
                  _DrawerTile(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.star_outline_rounded,
                    label: 'Feedback and rate',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedbackRateScreen()),
                      );
                    },
                  ),
                  _DrawerTile(
                    icon: Icons.info_outline_rounded,
                    label: 'About Us',
                    color: AppColors.textPrimary,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature â€” coming soon!'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
