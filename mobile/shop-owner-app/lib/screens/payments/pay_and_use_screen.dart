import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_config.dart';
import '../dashboard/main_navigation.dart';
import '../../main.dart' show LoginScreen;

/// Mirrors the web admin's /shop-owner/pay-and-use screen: shows the shop's
/// monthly platform fee + unbilled WhatsApp usage (bill/marketing messages),
/// GST, and total due, then collects payment via Razorpay. The actual lock
/// is enforced server-side (ShopPaymentGateFilter) - this screen is the UX
/// for it, matching the web PaymentLockGuard's behavior.
class PayAndUseScreen extends StatefulWidget {
  final String token;
  final String userName;
  // When true (shown because the account is locked), a successful payment
  // navigates into MainNavigation. When opened voluntarily from Profile to
  // just check usage, it stays on this screen after paying.
  final bool isLockScreen;

  const PayAndUseScreen({
    super.key,
    required this.token,
    required this.userName,
    this.isLockScreen = false,
  });

  @override
  State<PayAndUseScreen> createState() => _PayAndUseScreenState();
}

class _PayAndUseScreenState extends State<PayAndUseScreen> {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _paying = false;
  String? _error;
  late Razorpay _razorpay;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadStatus();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      };

  Future<void> _loadStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/shop-owner-payments/status'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        setState(() {
          _status = data['data'];
          _loading = false;
        });
        // Already paid and this screen was only shown to enforce the lock -
        // step straight into the app instead of showing a "pay" screen.
        if (widget.isLockScreen && _status?['paid'] == true) {
          _goToDashboard();
        }
      } else {
        setState(() {
          _error = data['message']?.toString() ?? 'Failed to load payment status';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Check your connection and try again.';
        _loading = false;
      });
    }
  }

  void _goToDashboard() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainNavigation(userName: widget.userName, token: widget.token),
      ),
      (route) => false,
    );
  }

  Future<void> _pay() async {
    setState(() => _paying = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop-owner-payments/create-order'),
        headers: _headers,
        body: jsonEncode({}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode != 200 || data['statusCode'] != '0000') {
        setState(() => _paying = false);
        _showError(data['message']?.toString() ?? 'Failed to start payment');
        return;
      }

      final order = data['data'];
      _pendingOrderId = order['orderId'];
      final bool testMode = order['testMode'] == true;

      if (testMode) {
        // No real gateway in test mode - mirror the web's simulated success.
        await _verify(
          _pendingOrderId!,
          'test_pay_${DateTime.now().millisecondsSinceEpoch}',
          'test_sig',
        );
        return;
      }

      final options = {
        'key': order['keyId'],
        'amount': order['amount'],
        'currency': order['currency'],
        'name': 'NammaOoru',
        'description': 'Shop usage payment${_status != null ? ' - ${_status!['shopName']}' : ''}',
        'order_id': order['orderId'],
        'theme': {'color': '#2e7d32'},
      };
      _razorpay.open(options);
    } catch (e) {
      setState(() => _paying = false);
      _showError('Failed to start payment. Please try again.');
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) {
    final orderId = response.orderId ?? _pendingOrderId;
    if (orderId == null) {
      setState(() => _paying = false);
      _showError('Payment succeeded but order reference was lost. Contact support.');
      return;
    }
    _verify(orderId, response.paymentId ?? '', response.signature ?? '');
  }

  void _onPaymentError(PaymentFailureResponse response) {
    setState(() => _paying = false);
    _showError(response.message ?? 'Payment was cancelled or failed');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    setState(() => _paying = false);
  }

  Future<void> _verify(String orderId, String paymentId, String signature) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shop-owner-payments/verify'),
        headers: _headers,
        body: jsonEncode({
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        }),
      );
      final data = jsonDecode(response.body);
      setState(() => _paying = false);

      if (response.statusCode == 200 && data['statusCode'] == '0000') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful. You can now use the app.'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.isLockScreen) {
          _goToDashboard();
        } else {
          _loadStatus();
        }
      } else {
        _showError(data['message']?.toString() ?? 'Payment verification failed');
      }
    } catch (e) {
      setState(() => _paying = false);
      _showError('Could not verify payment. If money was deducted, contact support.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  String _formatPaise(num? paise) {
    final rupees = (paise ?? 0) / 100;
    return '₹${rupees.toStringAsFixed(rupees == rupees.roundToDouble() ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('Subscription & Usage'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1F36),
        elevation: 0,
        automaticallyImplyLeading: !widget.isLockScreen,
        actions: widget.isLockScreen
            ? [
                TextButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                  label: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ]
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildStatus(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _loadStatus, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    final status = _status!;
    final paid = status['paid'] == true;
    final billCount = status['billMsgCount'] ?? 0;
    final marketingCount = status['marketingMsgCount'] ?? 0;
    final amount = (status['amount'] as num?)?.toDouble() ?? 0;
    final usagePaise = status['usageAmountPaise'];
    final gstPaise = status['gstAmountPaise'];
    final totalPaise = status['totalAmountPaise'];
    final gstPercent = status['gstPercent'];
    final validUntil = status['validUntil']?.toString();

    return RefreshIndicator(
      onRefresh: _loadStatus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isLockScreen)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your subscription period has ended. Pay to keep using the app.',
                        style: TextStyle(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status['shopName']?.toString() ?? 'Your Shop',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    paid && validUntil != null
                        ? 'Active until ${validUntil.split('T').first}'
                        : 'Payment required to continue',
                    style: TextStyle(fontSize: 13, color: paid ? Colors.green.shade700 : Colors.orange.shade800),
                  ),
                  const Divider(height: 28),
                  _buildRow('Monthly platform fee', '₹${amount.toStringAsFixed(0)}'),
                  if ((billCount as num) > 0 || (marketingCount as num) > 0) ...[
                    const SizedBox(height: 10),
                    _buildRow('Bill WhatsApp messages', '$billCount'),
                    _buildRow('Marketing WhatsApp messages', '$marketingCount'),
                    _buildRow('Usage amount', _formatPaise(usagePaise)),
                  ],
                  if (gstPercent != null) ...[
                    const SizedBox(height: 10),
                    _buildRow('GST ($gstPercent%)', _formatPaise(gstPaise)),
                  ],
                  const Divider(height: 28),
                  _buildRow('Total due', _formatPaise(totalPaise), emphasize: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!paid)
              ElevatedButton(
                onPressed: _paying ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _paying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text('You are all paid up', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 15 : 13,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
              color: emphasize ? const Color(0xFF1A1F36) : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasize ? 18 : 14,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: emphasize ? const Color(0xFF2E7D32) : const Color(0xFF1A1F36),
            ),
          ),
        ],
      ),
    );
  }
}
