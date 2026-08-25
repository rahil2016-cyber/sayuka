import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../services/job_seeker_api_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/job_card.dart' show JobCardWidget;
import 'job_detail_screen.dart';

/// Jobs filtered by [companyId] (`GET /jobs?company_id=`).
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
  bool _loading = true;
  String? _error;

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
      _isFetchingMore = false;
    });
    try {
      final jobs = await JobSeekerApiService.instance.listJobs(
        companyId: widget.companyId,
        page: 1,
        perPage: 15,
      );
      if (mounted) {
        setState(() {
          _jobs = jobs;
          _loading = false;
          if (jobs.length < 15) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isFetchingMore || !_hasMore || _loading) return;
    setState(() {
      _isFetchingMore = true;
    });
    try {
      final nextPage = _currentPage + 1;
      final jobs = await JobSeekerApiService.instance.listJobs(
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
            if (jobs.length < 15) {
              _hasMore = false;
            }
          }
          _isFetchingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFetchingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.companyName),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_error!, style: const TextStyle(color: Colors.red)),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      );
    }
    if (_jobs.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 80),
          Text(
            'No open roles from this company right now.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _jobs.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _jobs.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            ),
          );
        }

        final job = _jobs[i];
        return JobCardWidget(
          job: job,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => JobDetailScreen(
                  job: job,
                  userId: widget.userId,
                  token: widget.token,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
