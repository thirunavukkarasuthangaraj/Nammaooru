import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/localization/language_provider.dart';
import '../services/post_payment_service.dart';

class PostPaymentHandler {
  final BuildContext context;
  final String postType;
  final VoidCallback onPaymentSuccess;
  final Function(int paidTokenId) onTokenReceived;
  final VoidCallback? onPaymentCancelled;

  Razorpay? _razorpay;
  int? _paidTokenId;

  PostPaymentHandler({
    required this.context,
    required this.postType,
    required this.onPaymentSuccess,
    required this.onTokenReceived,
    this.onPaymentCancelled,
  });

  /// Check if an error response indicates a limit was reached
  static bool isLimitReached(Map<String, dynamic> result) {
    final message = result['message']?.toString() ?? '';
    final statusCode = result['statusCode']?.toString() ?? '';
    return message.contains('LIMIT_REACHED') || statusCode == 'LIMIT_REACHED';
  }

  /// Check if a DioException indicates a limit was reached (HTTP 402)
  static bool isDioLimitReached(dynamic error) {
    if (error is! Exception) return false;
    // Check the error string for LIMIT_REACHED
    return error.toString().contains('LIMIT_REACHED');
  }

  /// Show the payment dialog and initiate Razorpay
  Future<void> startPayment() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Get config first
    final configResult = await PostPaymentService.getConfig();
    if (configResult['success'] != true) {
      _showError(lang.getText(
        'Unable to load payment config. Please try again.',
        'கட்டண அமைப்பை ஏற்ற முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      ));
      return;
    }

    final config = configResult['data'];
    final bool enabled = config['enabled'] == true;
    final int price = config['price'] ?? 10;
    final String currency = config['currency'] ?? 'INR';
    final String keyId = config['razorpayKeyId'] ?? '';

    if (!enabled || keyId.isEmpty) {
      _showError(lang.getText(
        'Paid posting is currently unavailable.',
        'கட்டணமில்லா பதிவு தற்போது கிடைக்கவில்லை.',
      ));
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF1565C0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lang.getText('Post Limit Reached', 'பதிவு வரம்பு எட்டியது'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.getText(
                'You have reached your free post limit. Pay \u20B9$price to publish this post.',
                'உங்கள் இலவச பதிவு வரம்பை எட்டிவிட்டீர்கள். இந்தப் பதிவை வெளியிட \u20B9$price செலுத்தவும்.',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.payment, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    '\u20B9$price',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.getText('Pay \u20B9$price', '\u20B9$price செலுத்து')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      onPaymentCancelled?.call();
      return;
    }

    // Create order on backend
    final orderResult = await PostPaymentService.createOrder(postType);
    if (orderResult['success'] != true) {
      _showError(orderResult['message'] ?? 'Failed to create order');
      return;
    }

    final orderData = orderResult['data'];
    final String orderId = orderData['orderId'];
    final int amount = orderData['amount'];
    final bool isTestMode = orderData['testMode'] == true;

    if (isTestMode) {
      // TEST MODE: Skip Razorpay, simulate payment
      await _handleTestModePayment(orderId, lang);
      return;
    }

    // Open Razorpay
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    var options = {
      'key': keyId,
      'amount': amount,
      'currency': currency,
      'name': 'NammaOoru',
      'description': 'Post Payment',
      'order_id': orderId,
      'theme': {'color': '#1565C0'},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      Logger.e('Razorpay open error', 'POST_PAYMENT', e);
      _showError('Unable to open payment gateway');
    }
  }

  /// Test mode: show a mock payment dialog and auto-verify
  Future<void> _handleTestModePayment(String orderId, LanguageProvider lang) async {
    final pay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.science, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('TEST MODE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This is a test payment. No real money will be charged.\n\nTap "Simulate Pay" to test the flow.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.getText('Cancel', 'ரத்துசெய்')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simulate Pay'),
          ),
        ],
      ),
    );

    if (pay != true) {
      onPaymentCancelled?.call();
      return;
    }

    // Verify on backend (test mode auto-approves)
    final verifyResult = await PostPaymentService.verifyPayment(
      razorpayOrderId: orderId,
      razorpayPaymentId: 'test_pay_${DateTime.now().millisecondsSinceEpoch}',
      razorpaySignature: 'test_sig',
    );

    if (verifyResult['success'] == true) {
      _paidTokenId = verifyResult['data']?['paidTokenId'];
      if (_paidTokenId != null) {
        onTokenReceived(_paidTokenId!);
      }
      onPaymentSuccess();
    } else {
      _showError(verifyResult['message'] ?? 'Payment verification failed');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    Logger.i('Payment success: ${response.paymentId}', 'POST_PAYMENT');

    // Verify on backend
    final verifyResult = await PostPaymentService.verifyPayment(
      razorpayOrderId: response.orderId ?? '',
      razorpayPaymentId: response.paymentId ?? '',
      razorpaySignature: response.signature ?? '',
    );

    _razorpay?.clear();

    if (verifyResult['success'] == true) {
      _paidTokenId = verifyResult['data']?['paidTokenId'];
      if (_paidTokenId != null) {
        onTokenReceived(_paidTokenId!);
      }
      onPaymentSuccess();
    } else {
      _showError(verifyResult['message'] ?? 'Payment verification failed');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Logger.e('Payment failed: ${response.code} - ${response.message}', 'POST_PAYMENT');
    _razorpay?.clear();
    onPaymentCancelled?.call();
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Logger.i('External wallet selected: ${response.walletName}', 'POST_PAYMENT');
  }

  void _showError(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void dispose() {
    _razorpay?.clear();
  }
}
