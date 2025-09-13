class Earnings {
  final double totalEarnings;
  final double baseEarnings;
  final double distanceBonus;
  final double customerTips;
  final int totalDeliveries;
  final Duration onlineTime;
  final double efficiency;
  final List<DeliveryEarning> recentDeliveries;
  final BankDetails bankDetails;
  final EarningsPeriod period;

  const Earnings({
    required this.totalEarnings,
    required this.baseEarnings,
    required this.distanceBonus,
    required this.customerTips,
    required this.totalDeliveries,
    required this.onlineTime,
    required this.efficiency,
    required this.recentDeliveries,
    required this.bankDetails,
    required this.period,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) {
    return Earnings(
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      baseEarnings: (json['baseEarnings'] ?? 0.0).toDouble(),
      distanceBonus: (json['distanceBonus'] ?? 0.0).toDouble(),
      customerTips: (json['customerTips'] ?? 0.0).toDouble(),
      totalDeliveries: json['totalDeliveries'] ?? 0,
      onlineTime: Duration(minutes: json['onlineTimeMinutes'] ?? 0),
      efficiency: (json['efficiency'] ?? 0.0).toDouble(),
      recentDeliveries: (json['recentDeliveries'] as List<dynamic>? ?? [])
          .map((item) => DeliveryEarning.fromJson(item))
          .toList(),
      bankDetails: BankDetails.fromJson(json['bankDetails'] ?? {}),
      period: EarningsPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == json['period'],
        orElse: () => EarningsPeriod.today,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEarnings': totalEarnings,
      'baseEarnings': baseEarnings,
      'distanceBonus': distanceBonus,
      'customerTips': customerTips,
      'totalDeliveries': totalDeliveries,
      'onlineTimeMinutes': onlineTime.inMinutes,
      'efficiency': efficiency,
      'recentDeliveries': recentDeliveries.map((e) => e.toJson()).toList(),
      'bankDetails': bankDetails.toJson(),
      'period': period.toString().split('.').last,
    };
  }

  String get formattedOnlineTime {
    final hours = onlineTime.inHours;
    final minutes = onlineTime.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get formattedEfficiency {
    return '${efficiency.toStringAsFixed(0)}%';
  }

  double get averageEarningsPerDelivery {
    if (totalDeliveries == 0) return 0.0;
    return totalEarnings / totalDeliveries;
  }
}

class DeliveryEarning {
  final String orderId;
  final String orderNumber;
  final String restaurantName;
  final String deliveryArea;
  final double earnings;
  final DateTime deliveryTime;
  final double rating;

  const DeliveryEarning({
    required this.orderId,
    required this.orderNumber,
    required this.restaurantName,
    required this.deliveryArea,
    required this.earnings,
    required this.deliveryTime,
    required this.rating,
  });

  factory DeliveryEarning.fromJson(Map<String, dynamic> json) {
    return DeliveryEarning(
      orderId: json['orderId'] ?? '',
      orderNumber: json['orderNumber'] ?? '',
      restaurantName: json['restaurantName'] ?? '',
      deliveryArea: json['deliveryArea'] ?? '',
      earnings: (json['earnings'] ?? 0.0).toDouble(),
      deliveryTime: DateTime.parse(json['deliveryTime'] ?? DateTime.now().toIso8601String()),
      rating: (json['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'orderNumber': orderNumber,
      'restaurantName': restaurantName,
      'deliveryArea': deliveryArea,
      'earnings': earnings,
      'deliveryTime': deliveryTime.toIso8601String(),
      'rating': rating,
    };
  }

  String get formattedDeliveryTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deliveryDate = DateTime(deliveryTime.year, deliveryTime.month, deliveryTime.day);
    
    if (deliveryDate == today) {
      return 'Today, ${_formatTime(deliveryTime)}';
    } else if (deliveryDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(deliveryTime)}';
    } else {
      return '${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  String get route {
    return '$restaurantName → $deliveryArea';
  }

  String get formattedRating {
    return '⭐${rating.toStringAsFixed(1)}';
  }
}

class BankDetails {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String accountHolderName;

  const BankDetails({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.accountHolderName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      bankName: json['bankName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      ifscCode: json['ifscCode'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'accountHolderName': accountHolderName,
    };
  }

  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}

enum EarningsPeriod {
  today,
  week,
  month,
  all,
}

extension EarningsPeriodExtension on EarningsPeriod {
  String get displayName {
    switch (this) {
      case EarningsPeriod.today:
        return 'Today';
      case EarningsPeriod.week:
        return 'Week';
      case EarningsPeriod.month:
        return 'Month';
      case EarningsPeriod.all:
        return 'All Time';
    }
  }
}

class WithdrawalRequest {
  final String id;
  final double amount;
  final DateTime requestDate;
  final WithdrawalStatus status;
  final BankDetails bankDetails;
  final String? transactionId;
  final DateTime? processedDate;

  const WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.requestDate,
    required this.status,
    required this.bankDetails,
    this.transactionId,
    this.processedDate,
  });

  factory WithdrawalRequest.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequest(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      requestDate: DateTime.parse(json['requestDate'] ?? DateTime.now().toIso8601String()),
      status: WithdrawalStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => WithdrawalStatus.pending,
      ),
      bankDetails: BankDetails.fromJson(json['bankDetails'] ?? {}),
      transactionId: json['transactionId'],
      processedDate: json['processedDate'] != null 
          ? DateTime.parse(json['processedDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'requestDate': requestDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'bankDetails': bankDetails.toJson(),
      'transactionId': transactionId,
      'processedDate': processedDate?.toIso8601String(),
    };
  }
}

enum WithdrawalStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}