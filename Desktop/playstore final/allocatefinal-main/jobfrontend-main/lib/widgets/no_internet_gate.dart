import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';

/// Blocks the whole app with a friendly offline screen when there is no network.
class NoInternetGate extends StatelessWidget {
  const NoInternetGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final connectivity = ConnectivityService.instance;
    return AnimatedBuilder(
      animation: connectivity,
      builder: (context, _) {
        if (connectivity.isOnline) return child;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            const Positioned.fill(
              child: _NoInternetBlocker(),
            ),
          ],
        );
      },
    );
  }
}

class _NoInternetBlocker extends StatefulWidget {
  const _NoInternetBlocker();

  @override
  State<_NoInternetBlocker> createState() => _NoInternetBlockerState();
}

class _NoInternetBlockerState extends State<_NoInternetBlocker> {
  bool _checking = false;

  Future<void> _tryAgain() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await ConnectivityService.instance.refresh();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!ok) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Still offline. Check Wi‑Fi or mobile data.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 72,
                  color: AppColors.textSecondary.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 24),
                Text(
                  'Internet connection is not available',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Turn on Wi‑Fi or mobile data to continue using JobAllocate.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: _checking ? null : _tryAgain,
                  icon: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_checking ? 'Checking…' : 'Try again'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
