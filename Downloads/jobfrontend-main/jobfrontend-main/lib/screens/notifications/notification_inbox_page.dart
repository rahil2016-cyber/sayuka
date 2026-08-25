import 'package:flutter/material.dart';
import '../../services/notification_api_service.dart';

/// In-app notification inbox screen.
/// Shows the user's notification history with read/unread visual distinction.
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

  // Notification type → icon mapping
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
    'new_job': Color(0xFF6366F1),
    'shortlisted': Color(0xFFF59E0B),
    'interview': Color(0xFF3B82F6),
    'accepted': Color(0xFF10B981),
    'rejected': Color(0xFFEF4444),
    'new_application': Color(0xFF8B5CF6),
    'candidate_accepted': Color(0xFF059669),
    'subscription_expiring': Color(0xFFEF4444),
    'payment_success': Color(0xFF10B981),
    'broadcast': Color(0xFF6366F1),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.fetchNotifications();
    if (mounted) setState(() { _notifications = list; _loading = false; });
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    await _api.markAllRead();
    if (mounted) {
      setState(() {
        _notifications = _notifications
            .map((n) => AppNotification(
                  id: n.id,
                  title: n.title,
                  body: n.body,
                  type: n.type,
                  createdAt: n.createdAt,
                  readAt: n.readAt ?? DateTime.now(),
                ))
            .toList();
        _markingAll = false;
      });
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
    final theme = Theme.of(context);
    final hasUnread = _notifications.any((n) => !n.isRead);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16161E),
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                        color: Color(0xFF6366F1),
                      ),
                    )
                  : const Text(
                      'Mark all read',
                      style: TextStyle(
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF6366F1),
                  backgroundColor: const Color(0xFF16161E),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) => _buildTile(_notifications[i]),
                  ),
                ),
    );
  }

  Widget _buildTile(AppNotification n) {
    final icon = _typeIcons[n.type ?? ''] ?? Icons.notifications_rounded;
    final color = _typeColors[n.type ?? ''] ?? const Color(0xFF6366F1);
    final timeAgo = _formatTime(n.createdAt);

    return InkWell(
      onTap: () => _markRead(n),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? const Color(0xFF16161E) : const Color(0xFF1E1B2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead
                ? const Color(0xFF2A2A35)
                : color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: n.isRead
              ? null
              : [
                  BoxShadow(
                    color: color.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
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
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
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
                      color: Color(0xFF9CA3AF),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No notifications yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you about job matches,\napplication updates, and more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
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
