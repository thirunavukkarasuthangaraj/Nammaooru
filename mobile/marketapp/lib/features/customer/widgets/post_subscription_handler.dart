import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/logger.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/services/storage_service.dart';
import '../services/post_subscription_service.dart';

/// Handles monthly subscription flow using Razorpay.
/// Usage:
///   final handler = PostSubscriptionHandler(
///     context: context,
///     postType: 'MARKETPLACE',
///     onSubscriptionSuccess: (subscriptionDbId) { ... },
///   );
///   await handler.startSubscription();
class PostSubscriptionHandler {
  final BuildContext context;
  final String postType;
  final Function(int subscriptionDbId) onSubscriptionSuccess;
  final VoidCallback? onSubscriptionCancelled;

  Razorpay? _razorpay;
  int? _subscriptionDbId;
  String? _razorpaySubscriptionId;
  bool _isTestMode = false;

  PostSubscriptionHandler({
    required this.context,
    required this.postType,
    required this.onSubscriptionSuccess,
    this.onSubscriptionCancelled,
  });

  Future<void> startSubscription() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await PostSubscriptionService.createSubscription(postType);

    if (context.mounted) Navigator.of(context).pop(); // dismiss loading

    if (result['success'] != true) {
      _showError(result['message'] ?? lang.getText(
        'Failed to start subscription. Please try again.',
        'சந்தா தொடங்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      ));
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    _subscriptionDbId = data['subscriptionDbId'] as int?;
    _razorpaySubscriptionId = data['subscriptionId'] as String?;
    _isTestMode = data['testMode'] == true;
    final int amountPaise = data['amountPaise'] ?? (data['amount'] ?? 0) * 100;
    final String keyId = data['keyId'] ?? '';

    // Show price confirmation dialog
    final confirmed = await _showPriceDialog(
      lang: lang,
      amountRupees: (amountPaise / 100).toInt(),
    );
    if (!confirmed) {
      onSubscriptionCancelled?.call();
      return;
    }

    if (_isTestMode) {
      // Test mode: skip Razorpay, auto-verify
      await _verifyAndComplete('test_sub_id', 'test_pay_id');
      return;
    }

    // Get user phone number from local storage
    final user = await StorageService.getUserData();
    final userPhone = user?.phoneNumber ?? '';

    // Open Razorpay subscription checkout
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    final options = {
      'key': keyId,
      'subscription_id': _razorpaySubscriptionId,
      'name': 'NammaOoru',
      'description': lang.getText(
        'Monthly subscription for your post',
        'உங்கள் விளம்பரத்திற்கான மாதாந்திர சந்தா',
      ),
      'prefill': {
        'contact': userPhone,
      },
      'theme': {'color': '#2E7D32'},
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      Logger.e('Razorpay open failed', 'SUBSCRIPTION', e);
      _showError(lang.getText(
        'Failed to open payment. Please try again.',
        'கட்டண திறக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
      ));
    }
  }

  Future<bool> _showPriceDialog({
    required LanguageProvider lang,
    required int amountRupees,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(lang.getText('Monthly Subscription', 'மாதாந்திர சந்தா')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.getText(
                  'Subscribe monthly to keep your post visible.',
                  'உங்கள் விளம்பரம் காட்ட மாதாந்திர சந்தா எடுக்கவும்.',
                )),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(lang.getText('Monthly fee', 'மாத கட்டணம்'),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹$amountRupees',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  lang.getText(
                    'Auto-debit every month. Cancel anytime by deleting your post.',
                    'ஒவ்வொரு மாதமும் தானாக கழிக்கப்படும். போஸ்ட் நீக்கினால் நிறுத்தலாம்.',
                  ),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(lang.getText('Cancel', 'ரத்து')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(lang.getText('Subscribe', 'சந்தா எடு')),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Logger.i('Subscription payment success: ${response.paymentId}', 'SUBSCRIPTION');
    _razorpay?.clear();
    _verifyAndComplete(
      response.paymentId ?? '',
      response.paymentId ?? '',
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Logger.e('Subscription payment error: ${response.message}', 'SUBSCRIPTION', null);
    _razorpay?.clear();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      onSubscriptionCancelled?.call();
      return;
    }
    _showError(lang.getText(
      'Payment failed: ${response.message}',
      'கட்டணம் தோல்வியடைந்தது: ${response.message}',
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Logger.i('External wallet: ${response.walletName}', 'SUBSCRIPTION');
    _razorpay?.clear();
  }

  Future<void> _verifyAndComplete(String razorpaySubscriptionId, String razorpayPaymentId) async {
    if (_subscriptionDbId == null) return;

    final lang = Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final verifyResult = await PostSubscriptionService.verifySubscription(
      subscriptionDbId: _subscriptionDbId!,
      razorpaySubscriptionId: _razorpaySubscriptionId ?? razorpaySubscriptionId,
      razorpayPaymentId: razorpayPaymentId,
    );

    if (context.mounted) Navigator.of(context).pop();

    if (verifyResult['success'] == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang.getText(
            'Subscription activated! Your post will now stay visible monthly.',
            'சந்தா செயல்படுத்தப்பட்டது! உங்கள் விளம்பரம் மாதாந்திரம் காட்டப்படும்.',
          )),
          backgroundColor: Colors.green,
        ));
      }
      onSubscriptionSuccess(_subscriptionDbId!);
    } else {
      _showError(verifyResult['message'] ?? lang.getText(
        'Subscription setup failed. Please contact support.',
        'சந்தா அமைப்பு தோல்வியடைந்தது. ஆதரவை தொடர்பு கொள்ளவும்.',
      ));
    }
  }

  void _showError(String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void dispose() {
    _razorpay?.clear();
  }
}
