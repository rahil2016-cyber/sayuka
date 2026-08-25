import 'package:flutter/material.dart';
import '../../services/notification_api_service.dart';
import '../../services/fcm_flutter_service.dart';
import '../../screens/notifications/notification_inbox_page.dart';

/// A bell icon button that shows an unread badge.
/// Designed to be placed in any AppBar's actions list.
///
/// Usage in AppBar:
/// ```dart
/// actions: const [NotificationBell()],
/// ```
class NotificationBell extends StatefulWidget {
  final Color? iconColor;

  const NotificationBell({super.key, this.iconColor});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  final NotificationApiService _api = NotificationApiService();
  int _unreadCount = 0;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _loadCount();

    // React to incoming push messages
    NotificationEvents.addListener(_onNewMessage);
  }

  @override
  void dispose() {
    NotificationEvents.removeListener(_onNewMessage);
    _shakeController.dispose();
    super.dispose();
  }

  void _onNewMessage(_) {
    _loadCount();
    _shakeController.forward(from: 0);
  }

  Future<void> _loadCount() async {
    final count = await _api.fetchUnreadCount();
    if (mounted) setState(() => _unreadCount = count);
  }

  void _openInbox() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationInboxPage()),
    ).then((_) => _loadCount()); // refresh count after returning
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (ctx, child) => Transform.rotate(
          angle: _shakeAnimation.value * 0.3 * ((_shakeAnimation.value < 0.5) ? 1 : -1),
          child: child,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_rounded),
              color: widget.iconColor ?? Colors.white,
              iconSize: 26,
              onPressed: _openInbox,
              tooltip: 'Notifications',
            ),
            if (_unreadCount > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF16161E), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
