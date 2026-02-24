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
  Future<void> startPayment({bool includeBanner = false}) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Get config first
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
    final int price = config['price'] ?? 10;
    final int processingFeePaise = config['processingFeePaise'] ?? 24;
    final int totalAmountPaise = config['totalAmountPaise'] ?? (price * 100 + processingFeePaise);
    final String currency = config['currency'] ?? 'INR';
    final String keyId = config['razorpayKeyId'] ?? '';
    final int durationDays = config['durationDays'] ?? 30;
    final bool bannerEnabled = config['bannerEnabled'] == true;
    final int bannerPrice = config['bannerPrice'] ?? 20;

    if (!enabled || keyId.isEmpty) {
      _showError(lang.getText(
        'Paid posting is currently unavailable.',
        'கட்டணமில்லா பதிவு தற்போது கிடைக்கவில்லை.',
      ));
      return;
    }

    // Build the dialog content based on whether banner is included
    Widget dialogContent;
    String dialogTitle;
    int displayTotal;
    int displayProcessingFee;

    final bool limitReached = config['limitReached'] == true;

    if (includeBanner && bannerEnabled) {
      // Banner payment - show combined breakdown
      final int estPostFee = limitReached ? price : 0;
      final int estBannerFee = bannerPrice;
      final int estBase = estPostFee + estBannerFee;
      final int estProcessing = (estBase * 236 / 10000).ceil();
      final int estTotal = estBase * 100 + estProcessing;

      displayTotal = estTotal;
      displayProcessingFee = estProcessing;

      dialogTitle = lang.getText('Banner Post Payment', 'பேனர் பதிவு கட்டணம்');
      final String feeDisplay = (estProcessing / 100.0).toStringAsFixed(2);
      final String totalDisplay = (estTotal / 100.0).toStringAsFixed(2);

      dialogContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang.getText(
              'Your post will be featured as a banner at the top of listings.',
              'உங்கள் பதிவு பட்டியல்களின் மேலே பேனராக இடம்பெறும்.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  lang.getText(
                    'Post will be active for $durationDays days',
                    'பதிவு $durationDays நாட்கள் செயலில் இருக்கும்',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
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
                if (limitReached) ...[
                  _buildPriceRow(
                    lang.getText('Post Fee', 'பதிவு கட்டணம்'),
                    '\u20B9$estPostFee.00',
                    isBold: false,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildPriceRow(
                  lang.getText('Banner Fee', 'பேனர் கட்டணம்'),
                  '\u20B9$estBannerFee.00',
                  isBold: false,
                  color: Colors.purple.shade700,
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  lang.getText('Transaction Fee', 'பரிவர்த்தனை கட்டணம்'),
                  '\u20B9$feeDisplay',
                  isBold: false,
                  color: Colors.orange.shade700,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
                _buildPriceRow(
                  lang.getText('Total', 'மொத்தம்'),
                  '\u20B9$totalDisplay',
                  isBold: true,
                  color: Colors.green.shade700,
                  fontSize: 20,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // Regular paid post flow
      dialogTitle = lang.getText('Post Limit Reached', 'பதிவு வரம்பு எட்டியது');
      final String feeDisplay = (processingFeePaise / 100.0).toStringAsFixed(2);
      final String totalDisplay = (totalAmountPaise / 100.0).toStringAsFixed(2);
      displayTotal = totalAmountPaise;

      dialogContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang.getText(
              'You have reached your free post limit. Pay to publish this post.',
              'உங்கள் இலவச பதிவு வரம்பை எட்டிவிட்டீர்கள். பதிவை வெளியிட செலுத்தவும்.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 18, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Text(
                  lang.getText(
                    'Post will be active for $durationDays days',
                    'பதிவு $durationDays நாட்கள் செயலில் இருக்கும்',
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
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
                _buildPriceRow(
                  lang.getText('Post Fee', 'பதிவு கட்டணம்'),
                  '\u20B9$price.00',
                  isBold: false,
                ),
                const SizedBox(height: 8),
                _buildPriceRow(
                  lang.getText('Transaction Fee', 'பரிவர்த்தனை கட்டணம்'),
                  '\u20B9$feeDisplay',
                  isBold: false,
                  color: Colors.orange.shade700,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Colors.grey.shade300),
                ),
                _buildPriceRow(
                  lang.getText('Total', 'மொத்தம்'),
                  '\u20B9$totalDisplay',
                  isBold: true,
                  color: Colors.green.shade700,
                  fontSize: 20,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final String finalTotalDisplay = (displayTotal / 100.0).toStringAsFixed(2);

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              includeBanner ? Icons.star : Icons.info_outline,
              color: includeBanner ? Colors.amber : const Color(0xFF1565C0),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dialogTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: dialogContent,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.getText('Cancel', 'ரத்துசெய்')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: includeBanner ? Colors.amber.shade700 : const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.getText('Pay \u20B9$finalTotalDisplay', '\u20B9$finalTotalDisplay செலுத்து')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      onPaymentCancelled?.call();
      return;
    }

    // Create order on backend
    final orderResult = await PostPaymentService.createOrder(postType, includeBanner: includeBanner);
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
      'description': includeBanner ? 'Banner Post Payment' : 'Post Payment',
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
