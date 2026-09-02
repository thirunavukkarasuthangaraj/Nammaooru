import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/earnings_model.dart';
import '../../../core/providers/earnings_provider.dart';
import 'payout_details_screen.dart';

/// Earnings / wallet screen. Backed entirely by the real backend wallet
/// system via [EarningsProvider] — balance, transaction history, and
/// withdrawal requests all come from the API. A requested withdrawal stays
/// PENDING until an admin processes it; nothing here pretends it's instant.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  WalletWithdrawal? _lastWithdrawal;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWallet());
  }

  Future<void> _loadWallet() async {
    await context.read<EarningsProvider>().loadWallet();
  }

  Future<void> _openPayoutDetails() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PayoutDetailsScreen()),
    );
  }

  Future<void> _showWithdrawDialog(Wallet wallet) async {
    final controller = TextEditingController(text: wallet.balance.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Withdrawal'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Available balance: ₹${wallet.balance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount to withdraw',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  if (parsed > wallet.balance) return 'Exceeds available balance';
                  return null;
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Withdrawals are processed manually and stay PENDING until an '
                'admin approves and pays them out — this is not instant.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(double.parse(controller.text));
              }
            },
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (amount == null || !mounted) return;

    final provider = context.read<EarningsProvider>();
    final withdrawal = await provider.requestWithdrawal(amount);

    if (!mounted) return;

    if (withdrawal != null) {
      setState(() => _lastWithdrawal = withdrawal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Withdrawal of ₹${withdrawal.amount.toStringAsFixed(2)} requested — status: PENDING',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to request withdrawal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance, color: Colors.white),
            tooltip: 'Payout details',
            onPressed: _openPayoutDetails,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallet,
        child: Consumer<EarningsProvider>(
          builder: (context, provider, child) {
            final wallet = provider.wallet;

            if (provider.isLoading && wallet == null) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              );
            }

            if (provider.error != null && wallet == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Error: ${provider.error}',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadWallet,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (wallet == null) {
              return const SizedBox.shrink();
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildBalanceCard(wallet),
                        if (_lastWithdrawal != null &&
                            _lastWithdrawal!.status == WalletWithdrawalStatus.pending) ...[
                          const SizedBox(height: 12),
                          _buildPendingWithdrawalBanner(_lastWithdrawal!),
                        ],
                        const SizedBox(height: 16),
                        _buildActionButtons(wallet, provider),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (provider.transactions.isEmpty)
                          _buildEmptyTransactions()
                        else
                          ...provider.transactions.map(_buildTransactionTile),
                        if (provider.hasMoreTransactions)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: provider.isLoadingMore
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: () => provider.loadMoreTransactions(),
                                      child: const Text('Load more'),
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBalanceCard(Wallet wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Available Balance',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${wallet.balance.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white24),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Earned', '₹${wallet.totalEarned.toStringAsFixed(0)}', Icons.trending_up),
              Container(width: 1, height: 40, color: Colors.white24),
              _buildStatItem('Total Withdrawn', '₹${wallet.totalWithdrawn.toStringAsFixed(0)}', Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingWithdrawalBanner(WalletWithdrawal withdrawal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top, color: Colors.orange[800], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Withdrawal of ₹${withdrawal.amount.toStringAsFixed(2)} is PENDING admin approval.',
              style: TextStyle(color: Colors.orange[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Wallet wallet, EarningsProvider provider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: provider.isWithdrawing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_downward, color: Colors.white, size: 18),
            label: const Text('Withdraw', style: TextStyle(color: Colors.white)),
            onPressed: (provider.isWithdrawing || wallet.balance <= 0)
                ? null
                : () => _showWithdrawDialog(wallet),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            icon: const Icon(Icons.account_balance, size: 18),
            label: const Text('Payout Details'),
            onPressed: _openPayoutDetails,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('No transactions yet', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(WalletTransaction txn) {
    final isCredit = txn.isCredit;
    final color = isCredit ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    final sign = isCredit ? '+' : '-';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    txn.reason.displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (txn.orderNumber != null)
                    Text(
                      'Order #${txn.orderNumber}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(txn.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Text(
              '$sign₹${txn.amount.toStringAsFixed(2)}',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
