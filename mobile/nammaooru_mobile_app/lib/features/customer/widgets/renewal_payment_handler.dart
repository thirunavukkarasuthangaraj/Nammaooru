import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/localization/language_provider.dart';
import '../services/post_payment_service.dart';

/// Handles payment flow for renewing expired/expiring posts.
/// Supports both single and bulk renewal.
class RenewalPaymentHandler {
  final BuildContext context;
  final String postType;

  Razorpay? _razorpay;
  Function(List<int> paidTokenIds)? _onTokensReceived;
  VoidCallback? _onCancelled;

  RenewalPaymentHandler({
    required this.context,
    required this.postType,
  });

  /// Renew a single post with payment
  Future<void> renewSingle({
    required Function(int paidTokenId) onTokenReceived,
    VoidCallback? onCancelled,
  }) async {
    _onTokensReceived = (ids) => onTokenReceived(ids.first);
    _onCancelled = onCancelled;
    await _startPayment(count: 1);
  }

  /// Renew multiple posts with a single payment
  Future<void> renewBulk({
    required int count,
    required Function(List<int> paidTokenIds) onTokensReceived,
    VoidCallback? onCancelled,
  }) async {
    _onTokensReceived = onTokensReceived;
    _onCancelled = onCancelled;
    await _startPayment(count: count);
  }

  Future<void> _startPayment({required int count}) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Get config
    final configResult = await PostPaymentService.getConfig(postType: postType);
    if (configResult['success'] != true) {
      _showError(lang.getText(
        'Unable to load payment config. Please try again.',
        'கட்டண அமைப்பை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      ));
      return;
    }

    final config = configResult['data'];
    final bool enabled = config['enabled'] == true;
    final int pricePerPost = config['price'] ?? 10;
    final String currency = config['currency'] ?? 'INR';
    final String keyId = config['razorpayKeyId'] ?? '';
    final int durationDays = config['durationDays'] ?? 30;

    if (!enabled || keyId.isEmpty) {
      _showError(lang.getText(
        'Paid posting is currently unavailable.',
        'கட்டணமில்லா பதிவு தற்போது கிடைக்கவில்லை.',
      ));
      return;
    }

    final int totalBase = pricePerPost * count;
    final int singleProcessingFee = config['processingFeePaise'] ?? (pricePerPost * 2.36).ceil();
    final int processingFeePaise = singleProcessingFee * count;
    final int singleTotal = config['totalAmountPaise'] ?? ((pricePerPost * 100) + singleProcessingFee);
    final int totalAmountPaise = singleTotal * count;
    final String feeDisplay = (processingFeePaise / 100.0).toStringAsFixed(2);
    final String totalDisplay = (totalAmountPaise / 100.0).toStringAsFixed(2);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                count == 1
                    ? lang.getText('Renew Post', 'பதிவை புதுப்பிக்க')
                    : lang.getText('Renew $count Posts', '$count பதிவுகளை புதுப்பிக்க'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count == 1
                  ? lang.getText(
                      'Pay to renew this post for another period.',
                      'இந்த பதிவை மீண்டும் ஒரு காலத்திற்கு புதுப்பிக்க செலுத்தவும்.',
                    )
                  : lang.getText(
                      'Pay to renew $count posts for another period.',
                      '$count பதிவுகளை மீண்டும் ஒரு காலத்திற்கு புதுப்பிக்க செலுத்தவும்.',
                    ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: Colors.green.shade700),
                  const SizedBox(width: 6),
                  Text(
                    lang.getText(
                      'Renewed for $durationDays days',
                      '$durationDays நாட்களுக்கு புதுப்பிக்கப்படும்',
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  if (count > 1)
                    _buildPriceRow(
                      lang.getText('$count posts × ₹$pricePerPost', '$count பதிவுகள் × ₹$pricePerPost'),
                      '₹$totalBase.00',
                      isBold: false,
                    ),
                  if (count == 1)
                    _buildPriceRow(
                      lang.getText('Renewal Fee', 'புதுப்பிப்பு கட்டணம்'),
                      '₹$pricePerPost.00',
                      isBold: false,
                    ),
                  const SizedBox(height: 8),
                  _buildPriceRow(
                    lang.getText('Transaction Fee', 'பரிவர்த்தனை கட்டணம்'),
                    '₹$feeDisplay',
                    isBold: false,
                    color: Colors.orange.shade700,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: Colors.grey.shade300),
                  ),
                  _buildPriceRow(
                    lang.getText('Total', 'மொத்தம்'),
                    '₹$totalDisplay',
                    isBold: true,
                    color: Colors.green.shade700,
                    fontSize: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.getText('Cancel', 'ரத்துசெய்')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.getText('Pay ₹$totalDisplay', '₹$totalDisplay செலுத்து')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _onCancelled?.call();
      return;
    }

    // Create order
    Map<String, dynamic> orderResult;
    if (count == 1) {
      orderResult = await PostPaymentService.createOrder(postType);
    } else {
      orderResult = await PostPaymentService.createBulkOrder(postType, count);
    }

    if (orderResult['success'] != true) {
      _showError(orderResult['message'] ?? 'Failed to create order');
      return;
    }

    final orderData = orderResult['data'];
    final String orderId = orderData['orderId'];
    final int amount = orderData['amount'];
    final bool isTestMode = orderData['testMode'] == true;

    // Store tokenIds for bulk (returned from create-bulk-order)
    List<int>? preTokenIds;
    if (count > 1 && orderData['tokenIds'] != null) {
      preTokenIds = (orderData['tokenIds'] as List).map((e) => (e as num).toInt()).toList();
    }

    if (isTestMode) {
      await _handleTestMode(orderId, count, preTokenIds, lang);
      return;
    }

    // Open Razorpay
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
      await _handleSuccess(response.orderId ?? '', response.paymentId ?? '', response.signature ?? '', count);
      _razorpay?.clear();
    });
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      Logger.e('Renewal payment failed: ${response.code} - ${response.message}', 'RENEWAL_PAYMENT');
      _razorpay?.clear();
      _onCancelled?.call();
    });
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      Logger.i('External wallet selected: ${response.walletName}', 'RENEWAL_PAYMENT');
    });

    try {
      _razorpay!.open({
        'key': keyId,
        'amount': amount,
        'currency': currency,
        'name': 'NammaOoru',
        'description': count == 1 ? 'Post Renewal' : 'Renew $count Posts',
        'order_id': orderId,
        'theme': {'color': '#4CAF50'},
      });
    } catch (e) {
      Logger.e('Razorpay open error', 'RENEWAL_PAYMENT', e);
      _showError('Unable to open payment gateway');
    }
  }

  Future<void> _handleTestMode(String orderId, int count, List<int>? preTokenIds, LanguageProvider lang) async {
    final pay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.orange),
            SizedBox(width: 8),
            Text('TEST MODE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          count == 1
              ? 'This is a test payment for post renewal. No real money will be charged.'
              : 'This is a test payment for renewing $count posts. No real money will be charged.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.getText('Cancel', 'ரத்துசெய்')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simulate Pay'),
          ),
        ],
      ),
    );

    if (pay != true) {
      _onCancelled?.call();
      return;
    }

    final testPaymentId = 'test_pay_${DateTime.now().millisecondsSinceEpoch}';
    await _handleSuccess(orderId, testPaymentId, 'test_sig', count);
  }

  Future<void> _handleSuccess(String orderId, String paymentId, String signature, int count) async {
    Map<String, dynamic> verifyResult;
    if (count == 1) {
      verifyResult = await PostPaymentService.verifyPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );
      if (verifyResult['success'] == true) {
        final tokenId = verifyResult['data']?['paidTokenId'];
        if (tokenId != null) {
          _onTokensReceived?.call([(tokenId as num).toInt()]);
        } else {
          _showError('Payment verified but no token received');
        }
      } else {
        _showError(verifyResult['message'] ?? 'Payment verification failed');
      }
    } else {
      verifyResult = await PostPaymentService.verifyBulkPayment(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );
      if (verifyResult['success'] == true) {
        final tokenIds = (verifyResult['data']?['paidTokenIds'] as List?)
            ?.map((e) => (e as num).toInt())
            .toList();
        if (tokenIds != null && tokenIds.isNotEmpty) {
          _onTokensReceived?.call(tokenIds);
        } else {
          _showError('Payment verified but no tokens received');
        }
      } else {
        _showError(verifyResult['message'] ?? 'Bulk payment verification failed');
      }
    }
  }

  Widget _buildPriceRow(String label, String amount, {
    bool isBold = false,
    Color? color,
    double fontSize = 15,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color ?? (isBold ? Colors.black87 : Colors.grey.shade800),
          ),
        ),
      ],
    );
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  void dispose() {
    _razorpay?.clear();
  }
}
