import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../widgets/job_card.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';

/// Full list of jobs similar to the seeker's applications.
/// Falls back to all published jobs when no personalised results exist.
class RelatedJobsScreen extends StatefulWidget {
  final String? userId;
  final String? token;

  const RelatedJobsScreen({
    super.key,
    this.userId,
    this.token,
  });

  @override
  State<RelatedJobsScreen> createState() => _RelatedJobsScreenState();
}

class _RelatedJobsScreenState extends State<RelatedJobsScreen> {
  List<Job> _jobs = [];
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _isLoading = true;
  bool _isFallback = false;   // true when we fell back to all-jobs
  String? _loadError;

  final _api = JobSeekerApiService.instance;
  final _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
    _refreshAppliedIds();
    _loadSavedJobIds();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels <= 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _currentPage = 1;
      _hasMore = true;
      _isFetchingMore = false;
      _isFallback = false;
    });

    if (!AppSession.isLoggedIn) {
      // Not logged in — show all jobs as fallback
      await _fallbackToAllJobs(page: 1);
      return;
    }

    try {
      List<Job> jobs = await _api.getRelatedJobs(page: 1, perPage: 15);

      if (jobs.isEmpty && mounted) {
        // No related jobs → gracefully fall back to all jobs
        await _fallbackToAllJobs(page: 1);
        return;
      }

      if (mounted) {
        setState(() {
          _jobs = jobs;
          _isLoading = false;
          if (jobs.length < 15) _hasMore = false;
        });
      }
    } catch (e) {
      // API error → fall back to all jobs so screen is never blank
      if (mounted) await _fallbackToAllJobs(page: 1, error: ApiService.messageFromException(e));
    }
  }

  Future<void> _fallbackToAllJobs({required int page, String? error}) async {
    try {
      final jobs = await _api.listJobs(page: page, perPage: 15);
      if (mounted) {
        setState(() {
          _isFallback = true;
          if (page == 1) {
            _jobs = jobs;
          } else {
            _jobs.addAll(jobs);
          }
          _currentPage = page;
          _isLoading = false;
          if (jobs.length < 15) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = error ?? ApiService.messageFromException(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _isLoading) return;
    setState(() => _isFetchingMore = true);

    try {
      final nextPage = _currentPage + 1;
      List<Job> jobs;

      if (_isFallback || !AppSession.isLoggedIn) {
        jobs = await _api.listJobs(page: nextPage, perPage: 15);
      } else {
        jobs = await _api.getRelatedJobs(page: nextPage, perPage: 15);
      }

      if (mounted) {
        setState(() {
          if (jobs.isEmpty) {
            _hasMore = false;
          } else {
            _jobs.addAll(jobs);
            _currentPage = nextPage;
            if (jobs.length < 15) _hasMore = false;
          }
          _isFetchingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isFetchingMore = false);
    }
  }

  Future<void> _refreshAppliedIds() async {
    if (!AppSession.isLoggedIn) { if (mounted) setState(() => _appliedJobIds = {}); return; }
    try {
      final apps = await _api.listMyApplications(perPage: 100);
      if (mounted) setState(() => _appliedJobIds = apps.map((a) => a.jobId.toString()).toSet());
    } catch (_) { if (mounted) setState(() => _appliedJobIds = {}); }
  }

  Future<void> _loadSavedJobIds() async {
    if (!AppSession.isLoggedIn) { if (mounted) setState(() => _savedJobIds = {}); return; }
    try {
      final saved = await _api.listSavedJobs(perPage: 100);
      if (mounted) setState(() => _savedJobIds = saved.map((j) => j.id).toSet());
    } catch (_) { if (mounted) setState(() => _savedJobIds = {}); }
  }

  Future<void> _saveJob(Job job) async {
    try {
      await _api.saveJob(job.id);
      if (mounted) setState(() => _savedJobIds.add(job.id));
    } catch (_) {}
  }

  Future<void> _unsaveJob(Job job) async {
    try {
      await _api.unsaveJob(job.id);
      if (mounted) setState(() => _savedJobIds.remove(job.id));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'More like jobs you applied to',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([_load(), _refreshAppliedIds(), _loadSavedJobIds()]);
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Finding jobs for you…',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // ── Error ─────────────────────────────────────────────────────────────────
    if (_loadError != null && _jobs.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  const Text('Could not load jobs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_loadError!, textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ── Empty ─────────────────────────────────────────────────────────────────
    if (_jobs.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(Icons.work_history_rounded,
                        size: 48, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No suggestions yet',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apply to a few roles and we\'ll suggest similar openings here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ── Job list ──────────────────────────────────────────────────────────────
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Fallback banner
        if (_isFallback)
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Apply to more jobs to get personalised suggestions. Showing all jobs for now.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == _jobs.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              }

              final job = _jobs[index];
              final isSaved = _savedJobIds.contains(job.id);
              return JobCardWidget(
                job: job,
                hasApplied: _appliedJobIds.contains(job.id),
                isBookmarked: isSaved,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => JobDetailScreen(
                      job: job,
                      userId: widget.userId ?? 'demo-user',
                      token: widget.token ?? 'demo-token',
                      isBookmarked: isSaved,
                      hasApplied: _appliedJobIds.contains(job.id),
                    ),
                  ));
                  if (mounted) {
                    await _refreshAppliedIds();
                    await _loadSavedJobIds();
                  }
                },
                onApply: () async {
                  final ok = await showApplyJobSheet(context, job);
                  if (ok && mounted) await _refreshAppliedIds();
                },
                onBookmark: () => isSaved ? _unsaveJob(job) : _saveJob(job),
              );
            },
            childCount: _jobs.length + (_hasMore ? 1 : 0),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}
