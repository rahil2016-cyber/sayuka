import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/job.dart';
import '../../services/app_session.dart';
import '../../services/job_seeker_api_service.dart';
import '../../widgets/job_card.dart';
import '../../widgets/apply_job_sheet.dart';
import '../../utils/app_colors.dart';
import 'job_detail_screen.dart';

class SimilarJobsScreen extends StatefulWidget {
  final Job job;
  final String userId;
  final String token;

  const SimilarJobsScreen({
    super.key,
    required this.job,
    required this.userId,
    required this.token,
  });

  @override
  State<SimilarJobsScreen> createState() => _SimilarJobsScreenState();
}

class _SimilarJobsScreenState extends State<SimilarJobsScreen> {
  List<Job> _similarJobs = [];
  Set<String> _appliedJobIds = {};
  Set<String> _savedJobIds = {};
  bool _isLoading = true;
  String? _loadError;

  final JobSeekerApiService _api = JobSeekerApiService.instance;

  @override
  void initState() {
    super.initState();
    _loadSimilarJobs();
    _refreshAppliedIds();
    _loadSavedJobIds();
  }

  Future<void> _loadSimilarJobs() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      // Use the backend's dedicated /jobs/{id}/similar endpoint.
      // It pre-filters by industry/functional area and scores by skills,
      // title words, experience level — no client-side heavy lifting needed.
      final jobs = await _api.getSimilarJobs(widget.job.id);

      if (mounted) {
        setState(() {
          _similarJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = ApiService.messageFromException(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshAppliedIds() async {
    if (!AppSession.isLoggedIn) return;
    try {
      final apps = await _api.listMyApplications(perPage: 100);
      if (mounted) {
        setState(() {
          _appliedJobIds = apps.map((a) => a.jobId.toString()).toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSavedJobIds() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job saved successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
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

  Future<void> _unsaveJob(Job job) async {
    try {
      await _api.unsaveJob(job.id);
      if (mounted) {
        setState(() => _savedJobIds.remove(job.id));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job removed from saved'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Similar Jobs',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            _loadSimilarJobs(),
            _refreshAppliedIds(),
            _loadSavedJobIds(),
          ]);
        },
        child: _buildBody(textTheme),
      ),
    );
  }

  Widget _buildBody(TextTheme textTheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_loadError != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
          Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.textHint.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Could not load similar jobs',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(_loadError!, textAlign: TextAlign.center, style: textTheme.bodySmall),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _loadSimilarJobs,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      );
    }

    if (_similarJobs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Icon(Icons.info_outline_rounded, size: 64, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No similar jobs found',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'There are no other jobs with similar industry or functional area right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: _similarJobs.length,
      itemBuilder: (context, index) {
        final job = _similarJobs[index];
        final isSaved = _savedJobIds.contains(job.id);
        final hasApplied = _appliedJobIds.contains(job.id);

        return JobCardWidget(
          job: job,
          hasApplied: hasApplied,
          isBookmarked: isSaved,
          onTap: () async {
            await Navigator.of(context).push(
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
            if (mounted) {
              await _refreshAppliedIds();
              await _loadSavedJobIds();
            }
          },
          onApply: () async {
            final ok = await showApplyJobSheet(context, job);
            if (ok && mounted) {
              await _refreshAppliedIds();
            }
          },
          onBookmark: () => isSaved ? _unsaveJob(job) : _saveJob(job),
        );
      },
    );
  }
}
