import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../widgets/job_card.dart' show JobCardWidget;
import 'job_detail_screen.dart';

/// Jobs filtered by [companyId] (`GET /jobs?company_id=`).
/// Shows Apply + Save buttons on each card, tracked with applied/saved state.
class CompanyJobsScreen extends StatefulWidget {
  final int companyId;
  final String companyName;
  final String userId;
  final String token;

  const CompanyJobsScreen({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.userId,
    required this.token,
  });

  @override
  State<CompanyJobsScreen> createState() => _CompanyJobsScreenState();
}

class _CompanyJobsScreenState extends State<CompanyJobsScreen> {
  List<Job> _jobs = [];
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _loading = true;
  String? _error;

  final _api = JobSeekerApiService.instance;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
    _loadAppliedIds();
    _loadSavedIds();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Scroll pagination ─────────────────────────────────────────────────────

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.maxScrollExtent - _scrollController.position.pixels <= 200) {
      _loadMore();
    }
  }

  // ─── Data fetching ─────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
      _isFetchingMore = false;
    });
    try {
      final jobs = await _api.listJobs(
        companyId: widget.companyId,
        page: 1,
        perPage: 15,
      );
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _loading = false;
          if (jobs.length < 15) _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _loading) return;
    setState(() => _isFetchingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final jobs = await _api.listJobs(
        companyId: widget.companyId,
        page: nextPage,
        perPage: 15,
      );
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

  Future<void> _loadAppliedIds() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final apps = await _api.listMyApplications(perPage: 100);
      if (mounted) {
        setState(() => _appliedJobIds = apps.map((a) => a.jobId.toString()).toSet());
      }
    } catch (_) {}
  }

  Future<void> _loadSavedIds() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final saved = await _api.listSavedJobs(perPage: 100);
      if (mounted) {
        setState(() => _savedJobIds = saved.map((j) => j.id).toSet());
      }
    } catch (_) {}
  }

  Future<void> _saveJob(Job job) async {
    try {
      await _api.saveJob(job.id);
      if (mounted) {
        setState(() => _savedJobIds.add(job.id));
        _snack('Job saved ✓', AppColors.primary);
      }
    } catch (e) {
      if (mounted) _snack('Could not save: $e', AppColors.error);
    }
  }

  Future<void> _unsaveJob(Job job) async {
    try {
      await _api.unsaveJob(job.id);
      if (mounted) {
        setState(() => _savedJobIds.remove(job.id));
        _snack('Removed from saved', AppColors.textSecondary);
      }
    } catch (e) {
      if (mounted) _snack('Could not unsave: $e', AppColors.error);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.companyName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([_load(), _loadAppliedIds(), _loadSavedIds()]);
        },
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // ── Loading ───────────────────────────────────────────────────────────────
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Loading jobs…',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // ── Error ─────────────────────────────────────────────────────────────────
    if (_error != null && _jobs.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 64, color: Color(0xFFCBD5E1)),
                  const SizedBox(height: 16),
                  const Text('Could not load jobs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(_error!,
                      textAlign: TextAlign.center,
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
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(45),
                    ),
                    child: const Icon(Icons.business_center_outlined,
                        size: 44, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No open roles right now',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.companyName} has no active job postings at the moment.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.5),
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
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              // Pagination spinner
              if (i == _jobs.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                );
              }

              final job = _jobs[i];
              final isSaved = _savedJobIds.contains(job.id);
              final hasApplied = _appliedJobIds.contains(job.id);

              return JobCardWidget(
                job: job,
                hasApplied: hasApplied,
                isBookmarked: isSaved,

                // ── Navigate to detail ────────────────────────────────────
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobDetailScreen(
                        job: job,
                        userId: widget.userId,
                        token: widget.token,
                        isBookmarked: isSaved,
                        hasApplied: hasApplied,
                      ),
                    ),
                  );
                  // Refresh applied/saved state after returning
                  if (mounted) {
                    await Future.wait([_loadAppliedIds(), _loadSavedIds()]);
                  }
                },

                // ── Apply ─────────────────────────────────────────────────
                onApply: () async {
                  final ok = await showApplyJobSheet(context, job);
                  if (ok && mounted) await _loadAppliedIds();
                },

                // ── Save / Unsave ──────────────────────────────────────────
                onBookmark: () =>
                    isSaved ? _unsaveJob(job) : _saveJob(job),
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
