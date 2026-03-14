import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/language_provider.dart';
import '../services/post_subscription_service.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  List<dynamic> _subscriptions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await PostSubscriptionService.getMySubscriptions();
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _subscriptions = result['data'] ?? [];
      } else {
        _error = result['message'] ?? 'Failed to load subscriptions';
      }
    });
  }

  Future<void> _cancelSubscription(int subscriptionId) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(lang.getText('Cancel Subscription', 'சந்தா ரத்து')),
        content: Text(lang.getText(
          'Are you sure? Auto-debit will stop. Your post will be hidden after current month.',
          'நிச்சயமா? தானியங்கி கழிப்பு நிறுத்தப்படும். இந்த மாத முடிவில் விளம்பரம் மறைக்கப்படும்.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.getText('No', 'இல்லை')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.getText('Yes, Cancel', 'ஆம், ரத்து செய்')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await PostSubscriptionService.cancelSubscription(subscriptionId);

    if (mounted) Navigator.of(context).pop();

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(lang.getText(
          'Subscription cancelled. Auto-debit stopped.',
          'சந்தா ரத்து செய்யப்பட்டது. தானியங்கி கழிப்பு நிறுத்தப்பட்டது.',
        )),
        backgroundColor: Colors.orange,
      ));
      _loadSubscriptions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? 'Failed to cancel'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'AUTHENTICATED':
        return Colors.blue;
      case 'HALTED':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.red;
      case 'EXPIRED':
      case 'COMPLETED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status, LanguageProvider lang) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return lang.getText('Active', 'செயல்படு');
      case 'AUTHENTICATED':
        return lang.getText('Pending charge', 'கட்டணம் நிலுவை');
      case 'HALTED':
        return lang.getText('Payment failed', 'கட்டணம் தோல்வி');
      case 'CANCELLED':
        return lang.getText('Cancelled', 'ரத்து');
      case 'EXPIRED':
        return lang.getText('Expired', 'காலாவதி');
      case 'COMPLETED':
        return lang.getText('Completed', 'முடிந்தது');
      default:
        return status;
    }
  }

  String _postTypeLabel(String postType) {
    switch (postType.toUpperCase()) {
      case 'MARKETPLACE':
        return 'Marketplace';
      case 'FARM_PRODUCTS':
        return 'Farm Products';
      case 'LABOURS':
        return 'Labour';
      case 'TRAVELS':
        return 'Travel';
      case 'PARCEL_SERVICE':
        return 'Parcel Service';
      case 'REAL_ESTATE':
        return 'Real Estate';
      case 'RENTAL':
        return 'Rental';
      case 'WOMENS_CORNER':
        return "Women's Corner";
      default:
        return postType;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.getText('My Subscriptions', 'என் சந்தாக்கள்')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubscriptions,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadSubscriptions,
                          child: Text(lang.getText('Retry', 'மீண்டும்')),
                        ),
                      ],
                    ),
                  )
                : _subscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              lang.getText(
                                'No subscriptions yet.\nSubscribe when creating a post.',
                                'சந்தா இல்லை.\nவிளம்பரம் உருவாக்கும்போது சந்தா எடுக்கலாம்.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _subscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = _subscriptions[index] as Map<String, dynamic>;
                          final status = sub['status']?.toString() ?? '';
                          final isActive = status == 'ACTIVE' || status == 'AUTHENTICATED';
                          final amount = sub['amount'] ?? 0;
                          final postType = sub['postType']?.toString() ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: _statusColor(status).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _postTypeLabel(postType),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _statusColor(status)),
                                        ),
                                        child: Text(
                                          _statusLabel(status, lang),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.currency_rupee,
                                          size: 16, color: Colors.grey),
                                      Text(
                                        '$amount / ${lang.getText('month', 'மாதம்')}',
                                        style: const TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  if (sub['currentPeriodStart'] != null &&
                                      sub['currentPeriodEnd'] != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_formatDate(sub['currentPeriodStart'])} → ${_formatDate(sub['currentPeriodEnd'])}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (isActive) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.autorenew,
                                            size: 14, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          lang.getText(
                                            'Auto-debit enabled',
                                            'தானியங்கி கழிப்பு செயல்படு',
                                          ),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.cancel_outlined,
                                            color: Colors.red),
                                        label: Text(
                                          lang.getText(
                                              'Cancel Auto-Debit', 'தானியங்கி கழிப்பு ரத்து'),
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        onPressed: () =>
                                            _cancelSubscription(sub['id'] as int),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
