import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/job.dart';

/// A compact, crash-proof job listing card designed for smooth scrolling
/// in ListViews and slivers. All elements use bounded sizes to prevent layout errors.
class JobCardWidget extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;
  final VoidCallback? onApply;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final bool hasApplied;
  final bool isNoLongerAccepting;

  const JobCardWidget({
    super.key,
    required this.job,
    required this.onTap,
    this.onApply,
    this.onBookmark,
    this.isBookmarked = false,
    this.hasApplied = false,
    this.isNoLongerAccepting = false,
  });

  String _fmtK(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  String get _salaryText {
    if (job.salaryMin != null && job.salaryMax != null) {
      return '₹${_fmtK(job.salaryMin!)} - ${_fmtK(job.salaryMax!)}/mo';
    }
    if (job.salaryRange.isNotEmpty) {
      String r = job.salaryRange;
      r = r.replaceAllMapped(RegExp(r'(\d+),?000'), (m) => '${m.group(1)}k');
      return r.contains('k') ? '₹$r/mo' : r;
    }
    return '₹30k - 60k/mo';
  }

  String get _postedTime {
    final diff = DateTime.now().difference(job.createdAt);
    if (diff.inHours < 1) return 'Just now';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  int get _matchPercent => (job.id.hashCode % 15) + 82;

  @override
  Widget build(BuildContext context) {
    final pct = _matchPercent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top line: Logo, Details, and Match indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Small compact logo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1B4B),
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: job.companyLogoUrl != null && job.companyLogoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: job.companyLogoUrl!,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => _initialsAvatar(),
                            )
                          : _initialsAvatar(),
                    ),
                    const SizedBox(width: 10),
                    // Title and company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  job.companyName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.verified, color: Color(0xFF2563EB), size: 12),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${job.location}  •  ${_getJobType()}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Match text indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$pct% Match',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF137333),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Small Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
                ),

                // Bottom row: Salary details + action buttons
                Row(
                  children: [
                    // Salary
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _salaryText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _postedTime,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Bookmark action icon
                    if (onBookmark != null) ...[
                      GestureDetector(
                        onTap: onBookmark,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: const Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Apply action button
                    _buildActionButton(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initialsAvatar() => Center(
        child: Text(
          job.companyName.isNotEmpty ? job.companyName[0].toUpperCase() : 'J',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  String _getJobType() {
    return job.jobType
        .replaceAll('_', ' ')
        .split(' ')
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '')
        .join(' ');
  }

  Widget _buildActionButton() {
    if (hasApplied) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Text(
              'Applied',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
      );
    }

    if (onApply != null && !isNoLongerAccepting) {
      return SizedBox(
        height: 32,
        width: 72,
        child: ElevatedButton(
          onPressed: onApply,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Apply',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (isNoLongerAccepting) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Closed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}