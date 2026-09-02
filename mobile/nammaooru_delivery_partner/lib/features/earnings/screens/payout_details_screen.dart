import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/earnings_model.dart';
import '../../../core/providers/earnings_provider.dart';

/// Minimal form allowing a driver to set/update how they get paid out —
/// either a bank account or a UPI ID. Calls the real
/// PUT /api/wallet/delivery-partner/payout-details endpoint via
/// [EarningsProvider.updatePayoutDetails].
class PayoutDetailsScreen extends StatefulWidget {
  const PayoutDetailsScreen({Key? key}) : super(key: key);

  @override
  State<PayoutDetailsScreen> createState() => _PayoutDetailsScreenState();
}

class _PayoutDetailsScreenState extends State<PayoutDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  PayoutMethod _method = PayoutMethod.bankAccount;
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  bool _initialized = false;

  @override
  void dispose() {
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _prefillFromWallet(Wallet? wallet) {
    if (_initialized || wallet == null) return;
    _initialized = true;

    if (wallet.payoutMethod == PayoutMethod.upi) {
      _method = PayoutMethod.upi;
    } else {
      _method = PayoutMethod.bankAccount;
    }
    _accountHolderController.text = wallet.bankAccountHolderName ?? '';
    _accountNumberController.text = wallet.bankAccountNumber ?? '';
    _ifscController.text = wallet.bankIfsc ?? '';
    _upiController.text = wallet.upiId ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EarningsProvider>();
    final success = await provider.updatePayoutDetails(
      payoutMethod: _method,
      accountHolderName: _method == PayoutMethod.bankAccount
          ? _accountHolderController.text.trim()
          : null,
      accountNumber: _method == PayoutMethod.bankAccount
          ? _accountNumberController.text.trim()
          : null,
      ifsc: _method == PayoutMethod.bankAccount ? _ifscController.text.trim() : null,
      upiId: _method == PayoutMethod.upi ? _upiController.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payout details updated')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to update payout details'),
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
          'Payout Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
      ),
      body: Consumer<EarningsProvider>(
        builder: (context, provider, child) {
          _prefillFromWallet(provider.wallet);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How would you like to receive withdrawals?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<PayoutMethod>(
                    segments: const [
                      ButtonSegment(
                        value: PayoutMethod.bankAccount,
                        label: Text('Bank Account'),
                        icon: Icon(Icons.account_balance),
                      ),
                      ButtonSegment(
                        value: PayoutMethod.upi,
                        label: Text('UPI'),
                        icon: Icon(Icons.qr_code),
                      ),
                    ],
                    selected: {_method},
                    onSelectionChanged: (selection) {
                      setState(() => _method = selection.first);
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_method == PayoutMethod.bankAccount) ...[
                    TextFormField(
                      controller: _accountHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ifscController,
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _upiController,
                      decoration: const InputDecoration(
                        labelText: 'UPI ID',
                        hintText: 'example@upi',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Required'
                          : null,
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: provider.isSavingPayoutDetails ? null : _submit,
                      child: provider.isSavingPayoutDetails
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Payout Details',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
