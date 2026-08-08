import 'package:flutter/material.dart';
import '../../services/notification_api_service.dart';
import '../../utils/app_colors.dart';

/// In-app notification inbox — matches the light AppColors theme used elsewhere.
class NotificationInboxPage extends StatefulWidget {
  const NotificationInboxPage({super.key});

  @override
  State<NotificationInboxPage> createState() => _NotificationInboxPageState();
}

class _NotificationInboxPageState extends State<NotificationInboxPage> {
  final NotificationApiService _api = NotificationApiService();

  List<AppNotification> _notifications = [];
  bool _loading = true;
  bool _markingAll = false;

  static const Map<String, IconData> _typeIcons = {
    'new_job': Icons.work_rounded,
    'shortlisted': Icons.star_rounded,
    'interview': Icons.calendar_month_rounded,
    'accepted': Icons.check_circle_rounded,
    'rejected': Icons.cancel_rounded,
    'new_application': Icons.inbox_rounded,
    'candidate_accepted': Icons.handshake_rounded,
    'subscription_expiring': Icons.warning_amber_rounded,
    'payment_success': Icons.payment_rounded,
    'broadcast': Icons.campaign_rounded,
  };

  static const Map<String, Color> _typeColors = {
    'new_job': AppColors.primary,
    'shortlisted': AppColors.warning,
    'interview': AppColors.primary,
    'accepted': AppColors.success,
    'rejected': AppColors.error,
    'new_application': AppColors.primary,
    'candidate_accepted': AppColors.success,
    'subscription_expiring': AppColors.error,
    'payment_success': AppColors.success,
    'broadcast': AppColors.primary,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    await _api.markAllRead();
    if (mounted) {
      setState(() {
        _notifications = _notifications
            .map(
              (n) => AppNotification(
                id: n.id,
                title: n.title,
                body: n.body,
                type: n.type,
                createdAt: n.createdAt,
                readAt: n.readAt ?? DateTime.now(),
              ),
            )
            .toList();
        _markingAll = false;
      });
    }
  }

  Future<void> _handleTap(AppNotification notification) async {
    if (!notification.isRead) {
      await _markRead(notification);
    }

    if (!mounted) return;

    final type = notification.type ?? '';
    if (type == 'new_job' || type == 'job') {
      Navigator.of(context).pop();
    } else if (['shortlisted', 'interview', 'accepted', 'rejected', 'application', 'application_submitted'].contains(type)) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.isRead) return;
    await _api.markOneRead(notification.id);
    if (mounted) {
      setState(() {
        _notifications = _notifications.map((n) {
          if (n.id == notification.id) {
            return AppNotification(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              createdAt: n.createdAt,
              readAt: DateTime.now(),
            );
          }
          return n;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markingAll ? null : _markAllRead,
              child: _markingAll
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _notifications.isEmpty
              ? _buildEmptyState(textTheme)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _buildTile(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildTile(AppNotification n) {
    final icon = _typeIcons[n.type ?? ''] ?? Icons.notifications_rounded;
    final color = _typeColors[n.type ?? ''] ?? AppColors.primary;
    final timeAgo = _formatTime(n.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _handleTap(n),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: n.isRead
                    ? const Color(0xFFE2E8F0)
                    : color.withOpacity(0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight:
                                    n.isRead ? FontWeight.w600 : FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.body,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timeAgo,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No notifications yet',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We’ll notify you about job matches,\napplication updates, and more.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
