import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/village_theme.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../services/post_payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  String? _errorMessage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPayments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMorePayments();
    }
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 0;
    });

    final result = await PostPaymentService.getMyPayments(page: 0, size: _pageSize);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final data = result['data'];
          _payments = data['content'] ?? [];
          _hasMore = !(data['last'] ?? true);
        } else {
          _errorMessage = result['message'] ?? 'Failed to load payments';
          _payments = [];
        }
      });
    }
  }

  Future<void> _loadMorePayments() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final result = await PostPaymentService.getMyPayments(page: nextPage, size: _pageSize);

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result['success'] == true) {
          final data = result['data'];
          _currentPage = nextPage;
          _payments.addAll(data['content'] ?? []);
          _hasMore = !(data['last'] ?? true);
        }
      });
    }
  }

  String _getPostTypeLabel(String? postType, LanguageProvider lang) {
    switch (postType) {
      case 'MARKETPLACE':
        return lang.getText('Marketplace', '\u0B9A\u0BA8\u0BCD\u0BA4\u0BC8');
      case 'FARM_PRODUCTS':
        return lang.getText('Farm Products', '\u0BB5\u0BBF\u0BB5\u0B9A\u0BBE\u0BAF \u0BAA\u0BCA\u0BB0\u0BC1\u0B9F\u0BCD\u0B95\u0BB3\u0BCD');
      case 'LABOURS':
        return lang.getText('Labours', '\u0BA4\u0BCA\u0BB4\u0BBF\u0BB2\u0BBE\u0BB3\u0BB0\u0BCD\u0B95\u0BB3\u0BCD');
      case 'TRAVELS':
        return lang.getText('Travels', '\u0BAA\u0BAF\u0BA3\u0B99\u0BCD\u0B95\u0BB3\u0BCD');
      case 'PARCEL_SERVICE':
        return lang.getText('Packers & Movers', '\u0baa\u0bc7\u0b95\u0bcd\u0b95\u0bb0\u0bcd\u0b9a\u0bcd & \u0bae\u0bc2\u0bb5\u0bb0\u0bcd\u0b9a\u0bcd');
      default:
        return postType ?? lang.getText('Unknown', '\u0BA4\u0BC6\u0BB0\u0BBF\u0BAF\u0BBE\u0BA4');
    }
  }

  IconData _getPostTypeIcon(String? postType) {
    switch (postType) {
      case 'MARKETPLACE':
        return Icons.storefront;
      case 'FARM_PRODUCTS':
        return Icons.agriculture;
      case 'LABOURS':
        return Icons.engineering;
      case 'TRAVELS':
        return Icons.directions_car;
      case 'PARCEL_SERVICE':
        return Icons.local_shipping;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PAID':
        return VillageTheme.successGreen;
      case 'FAILED':
        return VillageTheme.errorRed;
      case 'CREATED':
        return VillageTheme.warningOrange;
      default:
        return VillageTheme.modernGray;
    }
  }

  String _getStatusLabel(String? status, LanguageProvider lang) {
    switch (status) {
      case 'PAID':
        return lang.getText('Paid', '\u0B9A\u0BC6\u0BB2\u0BC1\u0BA4\u0BCD\u0BA4\u0BAA\u0BCD\u0BAA\u0B9F\u0BCD\u0B9F\u0BA4\u0BC1');
      case 'FAILED':
        return lang.getText('Failed', '\u0BA4\u0BCB\u0BB2\u0BCD\u0BB5\u0BBF');
      case 'CREATED':
        return lang.getText('Pending', '\u0BA8\u0BBF\u0BB2\u0BC1\u0BB5\u0BC8\u0BAF\u0BBF\u0BB2\u0BCD');
      default:
        return status ?? lang.getText('Unknown', '\u0BA4\u0BC6\u0BB0\u0BBF\u0BAF\u0BBE\u0BA4');
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: VillageTheme.lightBackground,
      appBar: AppBar(
        title: Text(
          lang.getText('Payment History', '\u0B9A\u0BC6\u0BB2\u0BC1\u0BA4\u0BCD\u0BA4 \u0BB5\u0BB0\u0BB2\u0BBE\u0BB1\u0BC1'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: VillageTheme.primaryGreen,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading payments...')
          : _errorMessage != null
              ? _buildErrorState(lang)
              : _payments.isEmpty
                  ? _buildEmptyState(lang)
                  : _buildPaymentList(lang),
    );
  }

  Widget _buildErrorState(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VillageTheme.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: VillageTheme.iconHuge,
              color: VillageTheme.errorRed,
            ),
            const SizedBox(height: VillageTheme.spacingM),
            Text(
              _errorMessage!,
              style: VillageTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VillageTheme.spacingL),
            ElevatedButton.icon(
              onPressed: _loadPayments,
              icon: const Icon(Icons.refresh),
              label: Text(lang.getText('Retry', '\u0BAE\u0BC0\u0BA3\u0BCD\u0B9F\u0BC1\u0BAE\u0BCD \u0BAE\u0BC1\u0BAF\u0BB1\u0BCD\u0B9A\u0BBF')),
              style: VillageTheme.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VillageTheme.spacingL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.payment_outlined,
              size: 80,
              color: VillageTheme.modernLight,
            ),
            const SizedBox(height: VillageTheme.spacingM),
            Text(
              lang.getText('No Payments Yet', '\u0B87\u0BA9\u0BCD\u0BA9\u0BC1\u0BAE\u0BCD \u0B9A\u0BC6\u0BB2\u0BC1\u0BA4\u0BCD\u0BA4\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B87\u0BB2\u0BCD\u0BB2\u0BC8'),
              style: VillageTheme.headingSmall.copyWith(
                color: VillageTheme.modernGray,
              ),
            ),
            const SizedBox(height: VillageTheme.spacingS),
            Text(
              lang.getText(
                'Your payment history will appear here once you make a payment.',
                '\u0BA8\u0BC0\u0B99\u0BCD\u0B95\u0BB3\u0BCD \u0B9A\u0BC6\u0BB2\u0BC1\u0BA4\u0BCD\u0BA4\u0BAE\u0BCD \u0B9A\u0BC6\u0BAF\u0BCD\u0BA4\u0BAA\u0BBF\u0BA9\u0BCD \u0B9A\u0BC6\u0BB2\u0BC1\u0BA4\u0BCD\u0BA4 \u0BB5\u0BB0\u0BB2\u0BBE\u0BB1\u0BC1 \u0B87\u0B99\u0BCD\u0B95\u0BC7 \u0BA4\u0BCB\u0BA9\u0BCD\u0BB1\u0BC1\u0BAE\u0BCD.',
              ),
              style: VillageTheme.bodyMedium.copyWith(
                color: VillageTheme.modernLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(LanguageProvider lang) {
    return RefreshIndicator(
      onRefresh: _loadPayments,
      color: VillageTheme.primaryGreen,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(VillageTheme.spacingM),
        itemCount: _payments.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _payments.length) {
            return const Padding(
              padding: EdgeInsets.all(VillageTheme.spacingM),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildPaymentCard(_payments[index], lang);
        },
      ),
    );
  }

  Widget _buildPaymentCard(dynamic payment, LanguageProvider lang) {
    final postType = payment['postType'] as String?;
    final baseAmount = payment['amount'] ?? 0;
    final processingFeePaise = payment['processingFee'] ?? 0;
    final totalAmountPaise = payment['totalAmount'];
    final status = payment['status'] as String?;
    final createdAt = payment['createdAt'] as String?;
    final razorpayOrderId = payment['razorpayOrderId'] as String?;

    // Calculate display amounts
    final double feeRupees = processingFeePaise / 100.0;
    final double totalRupees = totalAmountPaise != null
        ? totalAmountPaise / 100.0
        : baseAmount.toDouble();

    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: VillageTheme.spacingS),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VillageTheme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VillageTheme.spacingM),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post type icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: VillageTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getPostTypeIcon(postType),
                    color: VillageTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: VillageTheme.spacingS),
                // Payment details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPostTypeLabel(postType, lang),
                        style: VillageTheme.textLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(createdAt),
                        style: VillageTheme.bodySmall.copyWith(
                          color: VillageTheme.modernGray,
                        ),
                      ),
                      if (razorpayOrderId != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          razorpayOrderId,
                          style: VillageTheme.bodySmall.copyWith(
                            color: VillageTheme.modernLight,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: VillageTheme.spacingS),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(VillageTheme.chipRadius),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(status, lang),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            // Fee breakdown
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildAmountRow(
                    lang.getText('Post Fee', '\u0BAA\u0BA4\u0BBF\u0BB5\u0BC1 \u0B95\u0B9F\u0BCD\u0B9F\u0BA3\u0BAE\u0BCD'),
                    '\u20B9$baseAmount.00',
                  ),
                  if (feeRupees > 0) ...[
                    const SizedBox(height: 4),
                    _buildAmountRow(
                      lang.getText('Transaction Fee', '\u0BAA\u0BB0\u0BBF\u0BB5\u0BB0\u0BCD\u0BA4\u0BCD\u0BA4\u0BA9\u0BC8 \u0B95\u0B9F\u0BCD\u0B9F\u0BA3\u0BAE\u0BCD'),
                      '\u20B9${feeRupees.toStringAsFixed(2)}',
                      isSmall: true,
                    ),
                  ],
                  Divider(height: 12, color: Colors.grey.shade300),
                  _buildAmountRow(
                    lang.getText('Total', '\u0BAE\u0BCA\u0BA4\u0BCD\u0BA4\u0BAE\u0BCD'),
                    '\u20B9${totalRupees.toStringAsFixed(2)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount, {bool isBold = false, bool isSmall = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmall ? 12 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isSmall ? Colors.grey.shade600 : Colors.grey.shade700,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isBold ? 16 : (isSmall ? 12 : 13),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? VillageTheme.primaryGreen : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

}
