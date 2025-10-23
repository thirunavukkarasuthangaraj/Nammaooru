import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/promo_code_service.dart';
import 'promo_code_form_screen.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({Key? key}) : super(key: key);

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  final PromoCodeService _promoCodeService = PromoCodeService();
  List<Map<String, dynamic>> _promoCodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
  }

  Future<void> _loadPromoCodes() async {
    setState(() => _isLoading = true);
    try {
      final promoCodes = await _promoCodeService.getPromoCodes();
      setState(() {
        _promoCodes = promoCodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading promo codes: $e')),
        );
      }
    }
  }

  Future<void> _togglePromoStatus(Map<String, dynamic> promo) async {
    final currentStatus = promo['status'];
    final newStatus = currentStatus == 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';

    final result = await _promoCodeService.togglePromoStatus(promo['id'], newStatus);

    if (result['statusCode'] == '0000') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Promo code ${newStatus == 'ACTIVE' ? 'activated' : 'deactivated'}')),
      );
      _loadPromoCodes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to update status')),
      );
    }
  }

  Future<void> _deletePromoCode(Map<String, dynamic> promo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promo Code'),
        content: Text('Are you sure you want to delete "${promo['code']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await _promoCodeService.deletePromoCode(promo['id']);
      if (result['statusCode'] == '0000') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Promo code deleted successfully')),
        );
        _loadPromoCodes();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to delete')),
        );
      }
    }
  }

  void _navigateToForm({Map<String, dynamic>? promo}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PromoCodeFormScreen(promo: promo),
      ),
    );

    if (result == true) {
      _loadPromoCodes();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.grey;
      case 'EXPIRED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Codes'),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Promo', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPromoCodes,
              child: _promoCodes.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _promoCodes.length,
                      itemBuilder: (context, index) {
                        final promo = _promoCodes[index];
                        return _buildPromoCard(promo);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Promo Codes Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first promo code to attract customers!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final isActive = promo['status'] == 'ACTIVE';
    final type = promo['type'] ?? 'PERCENTAGE';
    final discountValue = promo['discountValue'] ?? 0;
    final usedCount = promo['usedCount'] ?? 0;
    final usageLimit = promo['usageLimit'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header with code and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer,
                            color: isActive ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            promo['code'] ?? '',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        promo['title'] ?? '',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(promo['status']),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    promo['status'] ?? 'UNKNOWN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Promo details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Discount',
                        type == 'PERCENTAGE'
                            ? '$discountValue%'
                            : '₹$discountValue',
                        Icons.discount,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Min Order',
                        promo['minimumOrderAmount'] != null
                            ? '₹${promo['minimumOrderAmount']}'
                            : 'None',
                        Icons.shopping_cart,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        'Used',
                        usageLimit != null
                            ? '$usedCount / $usageLimit'
                            : '$usedCount times',
                        Icons.bar_chart,
                        Colors.purple,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        'Valid Until',
                        _formatDate(promo['endDate']),
                        Icons.calendar_today,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                if (promo['description'] != null && promo['description'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            promo['description'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _navigateToForm(promo: promo),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _togglePromoStatus(promo),
                        icon: Icon(
                          isActive ? Icons.pause : Icons.play_arrow,
                          size: 18,
                        ),
                        label: Text(isActive ? 'Pause' : 'Activate'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isActive ? Colors.orange : Colors.green,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deletePromoCode(promo),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
