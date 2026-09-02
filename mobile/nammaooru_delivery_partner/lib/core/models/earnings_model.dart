// Wallet models matching the real backend wallet system.
//
// Backend shapes (see backend WalletController / Wallet / WalletTransaction /
// WalletWithdrawal entities):
//   Wallet: {id, ownerType, ownerId, balance, totalEarned, totalWithdrawn,
//            currency, payoutMethod, bankAccountHolderName,
//            bankAccountNumber, bankIfsc, upiId, razorpayFundAccountId,
//            payoutDetailsVerified, createdAt, updatedAt}
//   WalletTransaction: {id, type (CREDIT|DEBIT),
//            reason (ORDER_SETTLEMENT|WITHDRAWAL|ADJUSTMENT), amount,
//            balanceAfter, order (nullable, has orderNumber), notes,
//            createdAt}
//   WalletWithdrawal: {id, wallet, amount, status (PENDING|PAID|REJECTED),
//            payoutReference, notes, requestedAt, processedAt, processedBy}

enum PayoutMethod {
  bankAccount,
  upi,
  unknown;

  static PayoutMethod fromJson(String? value) {
    switch (value) {
      case 'BANK_ACCOUNT':
        return PayoutMethod.bankAccount;
      case 'UPI':
        return PayoutMethod.upi;
      default:
        return PayoutMethod.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case PayoutMethod.bankAccount:
        return 'BANK_ACCOUNT';
      case PayoutMethod.upi:
        return 'UPI';
      case PayoutMethod.unknown:
        return '';
    }
  }

  String get displayName {
    switch (this) {
      case PayoutMethod.bankAccount:
        return 'Bank Account';
      case PayoutMethod.upi:
        return 'UPI';
      case PayoutMethod.unknown:
        return 'Not set';
    }
  }
}

enum WalletTransactionType {
  credit,
  debit,
  unknown;

  static WalletTransactionType fromJson(String? value) {
    switch (value) {
      case 'CREDIT':
        return WalletTransactionType.credit;
      case 'DEBIT':
        return WalletTransactionType.debit;
      default:
        return WalletTransactionType.unknown;
    }
  }
}

enum WalletTransactionReason {
  orderSettlement,
  withdrawal,
  adjustment,
  unknown;

  static WalletTransactionReason fromJson(String? value) {
    switch (value) {
      case 'ORDER_SETTLEMENT':
        return WalletTransactionReason.orderSettlement;
      case 'WITHDRAWAL':
        return WalletTransactionReason.withdrawal;
      case 'ADJUSTMENT':
        return WalletTransactionReason.adjustment;
      default:
        return WalletTransactionReason.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case WalletTransactionReason.orderSettlement:
        return 'Order Settlement';
      case WalletTransactionReason.withdrawal:
        return 'Withdrawal';
      case WalletTransactionReason.adjustment:
        return 'Adjustment';
      case WalletTransactionReason.unknown:
        return 'Other';
    }
  }
}

enum WalletWithdrawalStatus {
  pending,
  paid,
  rejected,
  unknown;

  static WalletWithdrawalStatus fromJson(String? value) {
    switch (value) {
      case 'PENDING':
        return WalletWithdrawalStatus.pending;
      case 'PAID':
        return WalletWithdrawalStatus.paid;
      case 'REJECTED':
        return WalletWithdrawalStatus.rejected;
      default:
        return WalletWithdrawalStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case WalletWithdrawalStatus.pending:
        return 'Pending';
      case WalletWithdrawalStatus.paid:
        return 'Paid';
      case WalletWithdrawalStatus.rejected:
        return 'Rejected';
      case WalletWithdrawalStatus.unknown:
        return 'Unknown';
    }
  }
}

class Wallet {
  final int id;
  final String ownerType;
  final int ownerId;
  final double balance;
  final double totalEarned;
  final double totalWithdrawn;
  final String currency;
  final PayoutMethod payoutMethod;
  final String? bankAccountHolderName;
  final String? bankAccountNumber;
  final String? bankIfsc;
  final String? upiId;
  final String? razorpayFundAccountId;
  final bool payoutDetailsVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Wallet({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.balance,
    required this.totalEarned,
    required this.totalWithdrawn,
    required this.currency,
    required this.payoutMethod,
    this.bankAccountHolderName,
    this.bankAccountNumber,
    this.bankIfsc,
    this.upiId,
    this.razorpayFundAccountId,
    required this.payoutDetailsVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      ownerType: json['ownerType']?.toString() ?? '',
      ownerId: json['ownerId'] is int
          ? json['ownerId']
          : int.tryParse('${json['ownerId']}') ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      payoutMethod: PayoutMethod.fromJson(json['payoutMethod']?.toString()),
      bankAccountHolderName: json['bankAccountHolderName'],
      bankAccountNumber: json['bankAccountNumber'],
      bankIfsc: json['bankIfsc'],
      upiId: json['upiId'],
      razorpayFundAccountId: json['razorpayFundAccountId'],
      payoutDetailsVerified: json['payoutDetailsVerified'] == true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  String get maskedBankAccountNumber {
    final acc = bankAccountNumber;
    if (acc == null || acc.isEmpty) return '';
    if (acc.length <= 4) return acc;
    return '****${acc.substring(acc.length - 4)}';
  }

  bool get hasPayoutDetails =>
      payoutMethod == PayoutMethod.bankAccount || payoutMethod == PayoutMethod.upi;
}

class WalletTransaction {
  final int id;
  final WalletTransactionType type;
  final WalletTransactionReason reason;
  final double amount;
  final double balanceAfter;
  final String? orderNumber;
  final String? notes;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.reason,
    required this.amount,
    required this.balanceAfter,
    this.orderNumber,
    this.notes,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final order = json['order'];
    return WalletTransaction(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      type: WalletTransactionType.fromJson(json['type']?.toString()),
      reason: WalletTransactionReason.fromJson(json['reason']?.toString()),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0.0,
      orderNumber: order is Map<String, dynamic> ? order['orderNumber']?.toString() : null,
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  bool get isCredit => type == WalletTransactionType.credit;
}

class WalletWithdrawal {
  final int id;
  final double amount;
  final WalletWithdrawalStatus status;
  final String? payoutReference;
  final String? notes;
  final DateTime? requestedAt;
  final DateTime? processedAt;
  final String? processedBy;

  const WalletWithdrawal({
    required this.id,
    required this.amount,
    required this.status,
    this.payoutReference,
    this.notes,
    this.requestedAt,
    this.processedAt,
    this.processedBy,
  });

  factory WalletWithdrawal.fromJson(Map<String, dynamic> json) {
    return WalletWithdrawal(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: WalletWithdrawalStatus.fromJson(json['status']?.toString()),
      payoutReference: json['payoutReference'],
      notes: json['notes'],
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'].toString())
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'].toString())
          : null,
      processedBy: json['processedBy'],
    );
  }
}

/// A page of wallet transactions, matching ResponseUtil.paginated()'s
/// {content, currentPage, totalItems, totalPages, pageSize, isFirst, isLast,
/// hasNext, hasPrevious} envelope.
class WalletTransactionPage {
  final List<WalletTransaction> content;
  final int currentPage;
  final int totalItems;
  final int totalPages;
  final bool hasNext;

  const WalletTransactionPage({
    required this.content,
    required this.currentPage,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
  });

  factory WalletTransactionPage.fromJson(Map<String, dynamic> json) {
    return WalletTransactionPage(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: json['currentPage'] ?? 0,
      totalItems: json['totalItems'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] == true,
    );
  }
}
