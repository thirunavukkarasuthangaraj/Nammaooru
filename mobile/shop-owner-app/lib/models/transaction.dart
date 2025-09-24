class Transaction {
  final String id;
  final String type;
  final double amount;
  final String currency;
  final String description;
  final String status;
  final String? orderId;
  final String? customerId;
  final String? customerName;
  final String paymentMethod;
  final String? paymentId;
  final String? referenceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;
  final String? failureReason;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.currency,
    required this.description,
    required this.status,
    this.orderId,
    this.customerId,
    this.customerName,
    required this.paymentMethod,
    this.paymentId,
    this.referenceId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.metadata,
    this.failureReason,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'INR',
      description: json['description'] ?? '',
      status: json['status'] ?? 'PENDING',
      orderId: json['orderId'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      paymentMethod: json['paymentMethod'] ?? '',
      paymentId: json['paymentId'],
      referenceId: json['referenceId'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      metadata: json['metadata'],
      failureReason: json['failureReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'currency': currency,
      'description': description,
      'status': status,
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
      'failureReason': failureReason,
    };
  }

  Transaction copyWith({
    String? id,
    String? type,
    double? amount,
    String? currency,
    String? description,
    String? status,
    String? orderId,
    String? customerId,
    String? customerName,
    String? paymentMethod,
    String? paymentId,
    String? referenceId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
    String? failureReason,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentId: paymentId ?? this.paymentId,
      referenceId: referenceId ?? this.referenceId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  bool get isCredit => type == 'CREDIT' || type == 'ORDER' || type == 'REFUND';
  bool get isDebit => type == 'DEBIT' || type == 'EXPENSE' || type == 'COMMISSION';
  bool get isCompleted => status == 'COMPLETED' || status == 'SUCCESS';
  bool get isFailed => status == 'FAILED' || status == 'CANCELLED';
  bool get isPending => status == 'PENDING' || status == 'PROCESSING';

  @override
  String toString() {
    return 'Transaction(id: $id, type: $type, amount: $amount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

class FinanceSummary {
  final double totalRevenue;
  final double todayRevenue;
  final double monthRevenue;
  final double yearRevenue;
  final double totalExpenses;
  final double pendingAmount;
  final double commission;
  final int totalOrders;
  final int todayOrders;
  final double averageOrderValue;
  final Map<String, double> paymentMethodBreakdown;
  final Map<String, double> monthlyRevenue;
  final DateTime lastUpdated;

  FinanceSummary({
    required this.totalRevenue,
    required this.todayRevenue,
    required this.monthRevenue,
    required this.yearRevenue,
    required this.totalExpenses,
    required this.pendingAmount,
    required this.commission,
    required this.totalOrders,
    required this.todayOrders,
    required this.averageOrderValue,
    required this.paymentMethodBreakdown,
    required this.monthlyRevenue,
    required this.lastUpdated,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      monthRevenue: (json['monthRevenue'] ?? 0).toDouble(),
      yearRevenue: (json['yearRevenue'] ?? 0).toDouble(),
      totalExpenses: (json['totalExpenses'] ?? 0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      totalOrders: json['totalOrders'] ?? 0,
      todayOrders: json['todayOrders'] ?? 0,
      averageOrderValue: (json['averageOrderValue'] ?? 0).toDouble(),
      paymentMethodBreakdown: Map<String, double>.from(
        json['paymentMethodBreakdown'] ?? {},
      ),
      monthlyRevenue: Map<String, double>.from(
        json['monthlyRevenue'] ?? {},
      ),
      lastUpdated: DateTime.parse(
        json['lastUpdated'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRevenue': totalRevenue,
      'todayRevenue': todayRevenue,
      'monthRevenue': monthRevenue,
      'yearRevenue': yearRevenue,
      'totalExpenses': totalExpenses,
      'pendingAmount': pendingAmount,
      'commission': commission,
      'totalOrders': totalOrders,
      'todayOrders': todayOrders,
      'averageOrderValue': averageOrderValue,
      'paymentMethodBreakdown': paymentMethodBreakdown,
      'monthlyRevenue': monthlyRevenue,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  double get netRevenue => totalRevenue - totalExpenses - commission;
  double get growthRate => monthRevenue > 0 ? ((todayRevenue * 30) / monthRevenue - 1) * 100 : 0;

  @override
  String toString() {
    return 'FinanceSummary(totalRevenue: $totalRevenue, todayRevenue: $todayRevenue, totalOrders: $totalOrders)';
  }
}