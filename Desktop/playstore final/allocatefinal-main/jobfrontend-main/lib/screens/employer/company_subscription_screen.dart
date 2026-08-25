import 'package:flutter/material.dart';

import '../../services/company_subscription_api_service.dart';
import '../../services/phonepe_payment_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/network_user_message.dart';
import 'company_subscription_history_screen.dart';

class CompanySubscriptionScreen extends StatefulWidget {
  const CompanySubscriptionScreen({super.key});

  @override
  State<CompanySubscriptionScreen> createState() =>
      _CompanySubscriptionScreenState();
}

class _CompanySubscriptionScreenState extends State<CompanySubscriptionScreen> {
  final _subApi = CompanySubscriptionApiService.instance;
  final _couponController = TextEditingController();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _offer;
  int? _appliedDiscountPercent;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final offer = await _subApi.getOffer();
      if (!mounted) return;

      final first = (offer['first_month'] is Map<String, dynamic>)
          ? offer['first_month'] as Map<String, dynamic>
          : <String, dynamic>{};
      final suggestedCode = first['suggested_coupon_code']?.toString().trim();

      setState(() {
        _offer = offer;
        if (_couponController.text.trim().isEmpty &&
            suggestedCode != null &&
            suggestedCode.isNotEmpty) {
          _couponController.text = suggestedCode;
        }
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

  Future<void> _purchaseSubscription({String? fallbackCouponCode}) async {
    try {
      setState(() => _loading = true);

      final orderData = await _subApi.purchase(couponCode: null);
      await PhonePePaymentService.instance.checkoutAndConfirm(
        orderData: orderData,
        confirmStatus: (merchantOrderId) => _subApi.confirmStatus(
          merchantOrderId: merchantOrderId,
        ),
      );

      _showSnack('Payment successful! Subscription activated.');
      await _load();
    } catch (e) {
      _showSnack('Failed to complete payment: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Company Subscription',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Could not load subscription offers.',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _buildSubscriptionCard(context, textTheme),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, TextTheme textTheme) {
    final offer = _offer;
    if (offer == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Subscription details not available.',
          style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final verified = offer['verified'] == true;
    final first = (offer['first_month'] is Map<String, dynamic>)
        ? offer['first_month'] as Map<String, dynamic>
        : <String, dynamic>{};
    final alreadyPurchased = first['already_purchased'] == true;
    final suggestedCode = first['suggested_coupon_code']?.toString();

    // Static pricing values for Corporate Package
    const double basePrice = 499.0;
    final previewDiscount = _appliedDiscountPercent ?? 0;
    final discountAmount = basePrice * (previewDiscount / 100);
    final discountedBase = (basePrice - discountAmount).clamp(0.0, basePrice);
    final gstAmount = discountedBase * 0.18;
    final totalAmount = discountedBase + gstAmount;

    const features = [
      '1 Job Post',
      '30 Days Advertisement',
      'Basic Candidate Profile Access',
      'Bulk Hiring Support',
      'Priority Listing',
      'WhatsApp & Email Support',
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Premium Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '🥇 CORPORATE PACKAGE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CompanySubscriptionHistoryScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.history_rounded, size: 18, color: Colors.white70),
                      label: const Text(
                        'History',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Grow Your Team Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Post jobs, reach thousands of qualified seekers, and manage applications seamlessly.',
                  style: TextStyle(
                    color: Colors.blueGrey.shade100,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checklist Features
                Text(
                  'Package Features',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          f,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),




                const SizedBox(height: 24),

                // Price Summary Section
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Summary',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailRow('Base Fee', '₹ ${basePrice.toStringAsFixed(2)}'),
                      if (_appliedDiscountPercent != null)
                        _detailRow(
                          'Discount (${_appliedDiscountPercent!}%)',
                          '- ₹ ${discountAmount.toStringAsFixed(2)}',
                        ),
                      _detailRow('GST (18%)', '₹ ${gstAmount.toStringAsFixed(2)}'),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '₹ ${totalAmount.toStringAsFixed(2)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Subscription Status / Purchase button
                if (!verified) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You can buy subscription features after admin verification.',
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (alreadyPurchased) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Your Corporate Package is active!',
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: () => _purchaseSubscription(
                        fallbackCouponCode: suggestedCode,
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_bag_rounded),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Purchase Plan - ₹ ${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
