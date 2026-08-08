import 'dart:convert';

import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

import 'app_session.dart';

/// Runs PhonePe Standard Checkout (Flutter SDK) then confirms with our backend.
///
/// Secrets stay on the server; [orderData] must come from create-order APIs and include
/// `merchant_order_id`, `order_id`, `token`, `merchant_id`, `environment`.
class PhonePePaymentService {
  PhonePePaymentService._();
  static final PhonePePaymentService instance = PhonePePaymentService._();

  /// iOS URL scheme from Info.plist (`joballocate`).
  static const String iosAppSchema = 'joballocate';

  Future<Map<String, dynamic>> checkoutAndConfirm({
    required Map<String, dynamic> orderData,
    required Future<Map<String, dynamic>> Function(String merchantOrderId)
        confirmStatus,
  }) async {
    final merchantOrderId =
        orderData['merchant_order_id']?.toString().trim() ?? '';
    final orderId = orderData['order_id']?.toString().trim() ?? '';
    final token = orderData['token']?.toString().trim() ?? '';
    final merchantId = orderData['merchant_id']?.toString().trim() ?? '';
    final environment =
        (orderData['environment']?.toString().trim().isNotEmpty ?? false)
            ? orderData['environment'].toString().trim()
            : 'SANDBOX';

    if (merchantOrderId.isEmpty ||
        orderId.isEmpty ||
        token.isEmpty ||
        merchantId.isEmpty) {
      throw Exception('Invalid PhonePe order response from server.');
    }

    final rawFlow = (AppSession.userId ?? 'guest').replaceAll(
      RegExp(r'[^a-zA-Z0-9]'),
      '',
    );
    final flowId = rawFlow.isEmpty ? 'guest' : rawFlow;

    final initialized = await PhonePePaymentSdk.init(
      environment,
      merchantId,
      flowId,
      true,
    );
    if (initialized != true) {
      throw Exception('PhonePe SDK failed to initialize.');
    }

    final request = jsonEncode({
      'orderId': orderId,
      'merchantId': merchantId,
      'token': token,
      'paymentMode': {'type': 'PAY_PAGE'},
    });

    final response = await PhonePePaymentSdk.startTransaction(
      request,
      iosAppSchema,
    );

    final status = response?['status']?.toString() ?? '';
    final error = response?['error']?.toString() ?? '';

    // Always ask backend (Order Status API) — SDK SUCCESS is not final authority.
    final confirmed = await confirmStatus(merchantOrderId);
    final paymentStatus = confirmed['payment_status']?.toString() ?? '';

    if (paymentStatus == 'successful') {
      return confirmed;
    }

    if (paymentStatus == 'pending') {
      throw Exception(
        'Payment is still pending. Please wait a moment and check purchase history.',
      );
    }

    if (status == 'SUCCESS') {
      throw Exception(
        confirmed['message']?.toString() ??
            'Payment could not be confirmed. Please try again or contact support.',
      );
    }

    final detail = error.isNotEmpty ? error : status;
    throw Exception(
      detail.isNotEmpty
          ? 'Payment not completed ($detail).'
          : 'Payment was cancelled or incomplete.',
    );
  }
}
