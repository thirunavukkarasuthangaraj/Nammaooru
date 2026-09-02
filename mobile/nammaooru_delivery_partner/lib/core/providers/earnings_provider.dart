import 'package:flutter/foundation.dart';

import '../models/earnings_model.dart';
import '../services/api_service.dart';

/// Provider backing the earnings / wallet screen.
///
/// Talks to the real backend wallet system
/// (`/api/wallet/delivery-partner/*`) via [ApiService] — there is no mock
/// data here. A failed withdrawal request surfaces as a real error; it is
/// never silently turned into a fake "success".
class EarningsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Wallet? _wallet;
  List<WalletTransaction> _transactions = [];
  int _transactionsPage = 0;
  bool _hasMoreTransactions = true;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isWithdrawing = false;
  bool _isSavingPayoutDetails = false;
  String? _error;

  // Getters
  Wallet? get wallet => _wallet;
  List<WalletTransaction> get transactions => _transactions;
  bool get hasMoreTransactions => _hasMoreTransactions;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isWithdrawing => _isWithdrawing;
  bool get isSavingPayoutDetails => _isSavingPayoutDetails;
  String? get error => _error;

  double get availableBalance => _wallet?.balance ?? 0.0;

  /// Loads wallet balance and the first page of transactions.
  Future<void> loadWallet() async {
    _setLoading(true);
    _error = null;

    try {
      final balanceResponse = await _apiService.getWalletBalance();
      _wallet = Wallet.fromJson(balanceResponse['data'] as Map<String, dynamic>);

      await _loadTransactionsPage(page: 0, append: false);

      _error = null;
    } catch (e) {
      _error = _messageFor(e);
      if (kDebugMode) {
        print('Load Wallet Error: $e');
      }
    }

    _setLoading(false);
  }

  /// Reloads just the transaction history from page 0.
  Future<void> loadTransactions() async {
    try {
      await _loadTransactionsPage(page: 0, append: false);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = _messageFor(e);
      notifyListeners();
      if (kDebugMode) {
        print('Load Transactions Error: $e');
      }
    }
  }

  /// Loads the next page of transaction history, appending to the list.
  Future<void> loadMoreTransactions() async {
    if (_isLoadingMore || !_hasMoreTransactions) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _loadTransactionsPage(page: _transactionsPage + 1, append: true);
    } catch (e) {
      _error = _messageFor(e);
      if (kDebugMode) {
        print('Load More Transactions Error: $e');
      }
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> _loadTransactionsPage({required int page, required bool append}) async {
    final response = await _apiService.getWalletTransactions(page: page);
    final pageData = WalletTransactionPage.fromJson(response['data'] as Map<String, dynamic>);

    if (append) {
      _transactions = [..._transactions, ...pageData.content];
    } else {
      _transactions = pageData.content;
    }
    _transactionsPage = pageData.currentPage;
    _hasMoreTransactions = pageData.hasNext;
  }

  /// Requests a withdrawal. Pass `null` to withdraw the full available
  /// balance. Returns the created (PENDING) withdrawal on success.
  ///
  /// On failure this surfaces a real error via [error] and returns null —
  /// it never fabricates a fake successful withdrawal.
  Future<WalletWithdrawal?> requestWithdrawal([double? amount]) async {
    _isWithdrawing = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.requestWalletWithdrawal(amount: amount);
      final withdrawal = WalletWithdrawal.fromJson(response['data'] as Map<String, dynamic>);

      // Refresh balance + transactions so the UI reflects the new PENDING
      // withdrawal / debited balance immediately.
      await loadWallet();

      _isWithdrawing = false;
      notifyListeners();
      return withdrawal;
    } catch (e) {
      _error = _messageFor(e);
      _isWithdrawing = false;
      notifyListeners();
      if (kDebugMode) {
        print('Request Withdrawal Error: $e');
      }
      return null;
    }
  }

  /// Updates the driver's payout method/details. Returns true on success.
  Future<bool> updatePayoutDetails({
    required PayoutMethod payoutMethod,
    String? accountHolderName,
    String? accountNumber,
    String? ifsc,
    String? upiId,
  }) async {
    _isSavingPayoutDetails = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.updateWalletPayoutDetails(
        payoutMethod: payoutMethod.toJson(),
        accountHolderName: accountHolderName,
        accountNumber: accountNumber,
        ifsc: ifsc,
        upiId: upiId,
      );
      _wallet = Wallet.fromJson(response['data'] as Map<String, dynamic>);

      _isSavingPayoutDetails = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _messageFor(e);
      _isSavingPayoutDetails = false;
      notifyListeners();
      if (kDebugMode) {
        print('Update Payout Details Error: $e');
      }
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String _messageFor(Object e) {
    if (e is ApiException) return e.message;
    return e.toString();
  }
}
