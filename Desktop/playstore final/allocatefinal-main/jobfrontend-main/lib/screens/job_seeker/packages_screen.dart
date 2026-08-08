import 'package:flutter/material.dart';
import '../../services/job_seeker_api_service.dart';
import '../../services/phonepe_payment_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/network_user_message.dart';
import '../../mixins/auto_reload_on_reconnect.dart';
import 'package_purchase_history_screen.dart';

/// Job-seeker plans (catalog from API).
class JobSeekerPackagesScreen extends StatefulWidget {
  const JobSeekerPackagesScreen({super.key});

  @override
  State<JobSeekerPackagesScreen> createState() =>
      _JobSeekerPackagesScreenState();
}

class _JobSeekerPackagesScreenState extends State<JobSeekerPackagesScreen>
    with AutoReloadOnReconnect {
  bool _loading = true;
  bool _purchasing = false;
  String? _error;
  List<Map<String, dynamic>> _catalog = [];

  @override
  void onNetworkRestored() => _load();

  @override
  bool shouldReloadOnReconnect() => _error != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cat = await JobSeekerApiService.instance.getPackagesCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = cat;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = NetworkUserMessage.shortSummary(e);
        _loading = false;
      });
    }
  }

  int _intVal(Map<String, dynamic> row, String k, [String? alt]) {
    final v = row[k] ?? (alt != null ? row[alt] : null);
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  int? _optionalInt(Map<String, dynamic> row, String k) {
    if (!row.containsKey(k) || row[k] == null) return null;
    final v = row[k];
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  /// Opens PhonePe immediately — no confirmation dialog.
  Future<void> _purchase(Map<String, dynamic> row) async {
    final key = row['key']?.toString() ?? '';
    if (key.isEmpty || _purchasing) return;

    setState(() => _purchasing = true);

    try {
      final orderData =
          await JobSeekerApiService.instance.createPhonePeOrder(key);
      await PhonePePaymentService.instance.checkoutAndConfirm(
        orderData: orderData,
        confirmStatus: (merchantOrderId) =>
            JobSeekerApiService.instance.confirmPhonePePayment(
          merchantOrderId: merchantOrderId,
        ),
      );
      _showSuccess('Payment successful! Package activated.');
      await _load();
    } catch (e) {
      _showError(NetworkUserMessage.shortSummary(e));
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plans & packages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Purchase history',
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const PackagePurchaseHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _load,
            child: _loading && !_purchasing
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _load,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          Text(
                            'Resume packages',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Unlock premium templates and exports.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (_catalog.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No packages available.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textHint,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ..._catalog.map((row) {
                              final featured =
                                  row['key']?.toString() == 'premium_resume';
                              var features =
                                  List<String>.from(row['features'] ?? []);
                              if (features.isEmpty) {
                                final desc =
                                    row['description']?.toString() ?? '';
                                if (desc.contains('\n')) {
                                  features = desc
                                      .split('\n')
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList();
                                }
                              }
                              // Keep cards scannable — at most 3 bullets.
                              if (features.length > 3) {
                                features = features.take(3).toList();
                              }

                              return _PackageCard(
                                title: row['title']?.toString() ?? '',
                                listPriceInr:
                                    _optionalInt(row, 'list_price_inr'),
                                priceInr: _intVal(row, 'price_inr'),
                                features: features,
                                durationDays: _intVal(row, 'duration_days'),
                                featured: featured,
                                onSelect: () => _purchase(row),
                              );
                            }),
                        ],
                      ),
          ),
          if (_purchasing)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.title,
    this.listPriceInr,
    required this.priceInr,
    required this.features,
    required this.durationDays,
    required this.featured,
    required this.onSelect,
  });

  final String title;
  final int? listPriceInr;
  final int priceInr;
  final List<String> features;
  final int durationDays;
  final bool featured;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accent = featured ? const Color(0xFFD97706) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: featured ? accent : const Color(0xFFE2E8F0),
          width: featured ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (featured)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Popular',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (listPriceInr != null &&
                  listPriceInr! > 0 &&
                  listPriceInr! > priceInr) ...[
                Text(
                  '₹$listPriceInr',
                  style: textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '₹$priceInr',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '$durationDays days',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded, size: 16, color: accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: onSelect,
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Purchase',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
