import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../storage/secure_storage.dart';

class PromoCodeService {
  static const String _baseUrl = EnvConfig.baseUrl;

  /// Validate a promo code
  /// Returns validation result with discount amount
  Future<PromoCodeValidationResult> validatePromoCode({
    required String promoCode,
    required double orderAmount,
    String? customerId,
    String? deviceUuid,
    String? phone,
    String? shopId,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/api/promotions/validate');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'promoCode': promoCode,
          'customerId': customerId,
          'deviceUuid': deviceUuid,
          'phone': phone,
          'orderAmount': orderAmount,
          'shopId': shopId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['valid'] == true) {
        return PromoCodeValidationResult(
          isValid: true,
          message: data['message'] ?? 'Promo code applied successfully!',
          discountAmount: (data['discountAmount'] ?? 0).toDouble(),
          promotionId: data['promotionId'],
          promotionTitle: data['promotionTitle'],
          discountType: data['discountType'],
        );
      } else {
        return PromoCodeValidationResult(
          isValid: false,
          message: data['message'] ?? 'Invalid promo code',
          discountAmount: 0,
        );
      }
    } catch (e) {
      print('Error validating promo code: $e');
      return PromoCodeValidationResult(
        isValid: false,
        message: 'Failed to validate promo code. Please try again.',
        discountAmount: 0,
      );
    }
  }

  /// Get all active promotions
  Future<List<PromoCode>> getActivePromotions({String? shopId}) async {
    try {
      final url = shopId != null
          ? Uri.parse('$_baseUrl/api/promotions/active?shopId=$shopId')
          : Uri.parse('$_baseUrl/api/promotions/active');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final List<dynamic> promos = data['data'];
          return promos.map((p) => PromoCode.fromJson(p)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching active promotions: $e');
      return [];
    }
  }

  /// Get customer's promo code usage history
  Future<List<PromoUsage>> getMyUsageHistory(String customerId) async {
    try {
      final token = await SecureStorage.getAuthToken();
      final url =
          Uri.parse('$_baseUrl/api/promotions/my-usage?customerId=$customerId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['statusCode'] == '0000' && data['data'] != null) {
          final List<dynamic> usages = data['data'];
          return usages.map((u) => PromoUsage.fromJson(u)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching usage history: $e');
      return [];
    }
  }
}

/// Promo Code Validation Result
class PromoCodeValidationResult {
  final bool isValid;
  final String message;
  final double discountAmount;
  final int? promotionId;
  final String? promotionTitle;
  final String? discountType;

  PromoCodeValidationResult({
    required this.isValid,
    required this.message,
    required this.discountAmount,
    this.promotionId,
    this.promotionTitle,
    this.discountType,
  });
}

/// Promo Code Model
class PromoCode {
  final int id;
  final String code;
  final String title;
  final String? description;
  final String type; // PERCENTAGE, FIXED_AMOUNT, etc.
  final double discountValue;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final int? usageLimitPerCustomer;
  final DateTime startDate;
  final DateTime endDate;
  final String? imageUrl;
  final String? bannerUrl;
  final bool? isFirstTimeOnly;
  final String? termsAndConditions;

  PromoCode({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.type,
    required this.discountValue,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimitPerCustomer,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.bannerUrl,
    this.isFirstTimeOnly,
    this.termsAndConditions,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id'],
      code: json['code'],
      title: json['title'],
      description: json['description'],
      type: json['type'],
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minimumOrderAmount: json['minimumOrderAmount'] != null
          ? (json['minimumOrderAmount']).toDouble()
          : null,
      maximumDiscountAmount: json['maximumDiscountAmount'] != null
          ? (json['maximumDiscountAmount']).toDouble()
          : null,
      usageLimitPerCustomer: json['usageLimitPerCustomer'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      imageUrl: json['imageUrl'],
      bannerUrl: json['bannerUrl'],
      isFirstTimeOnly: json['isFirstTimeOnly'],
      termsAndConditions: json['termsAndConditions'],
    );
  }

  String get formattedDiscount {
    if (type == 'PERCENTAGE') {
      return '${discountValue.toStringAsFixed(0)}% OFF';
    } else if (type == 'FIXED_AMOUNT') {
      return '₹${discountValue.toStringAsFixed(0)} OFF';
    } else if (type == 'FREE_SHIPPING') {
      return 'FREE DELIVERY';
    } else {
      return 'SPECIAL OFFER';
    }
  }

  String get formattedMinOrder {
    if (minimumOrderAmount != null && minimumOrderAmount! > 0) {
      return 'Min order: ₹${minimumOrderAmount!.toStringAsFixed(0)}';
    }
    return 'No minimum order';
  }
}

/// Promo Usage Model
class PromoUsage {
  final int id;
  final String promoCode;
  final double discountApplied;
  final double orderAmount;
  final DateTime usedAt;
  final String? orderNumber;

  PromoUsage({
    required this.id,
    required this.promoCode,
    required this.discountApplied,
    required this.orderAmount,
    required this.usedAt,
    this.orderNumber,
  });

  factory PromoUsage.fromJson(Map<String, dynamic> json) {
    return PromoUsage(
      id: json['id'],
      promoCode: json['promotion']?['code'] ?? '',
      discountApplied: (json['discountApplied'] ?? 0).toDouble(),
      orderAmount: (json['orderAmount'] ?? 0).toDouble(),
      usedAt: DateTime.parse(json['usedAt']),
      orderNumber: json['order']?['orderNumber'],
    );
  }
}
