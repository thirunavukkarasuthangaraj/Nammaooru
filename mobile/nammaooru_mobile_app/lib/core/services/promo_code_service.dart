import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';
import '../storage/secure_storage.dart';

class PromoCodeService {
  static const String _baseUrl = EnvConfig.fullApiUrl;

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
      final url = Uri.parse('$_baseUrl/promotions/validate');

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
          promoCode: promoCode,
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
  /// Filters out promotions that the user has already used (based on orders)
  ///
  /// @param shopId Shop ID for shop-specific promotions
  /// @param customerId Customer ID (optional, for filtering used promos)
  /// @param phone Customer phone (optional, for filtering used promos)
  Future<List<PromoCode>> getActivePromotions({
    String? shopId,
    String? customerId,
    String? phone,
    double? latitude,
    double? longitude,
    String? category,
  }) async {
    try {
      // Build URL with query parameters
      final queryParams = <String, String>{};
      if (shopId != null) queryParams['shopId'] = shopId;
      if (customerId != null) queryParams['customerId'] = customerId;
      if (phone != null) queryParams['phone'] = phone;
      // Lets the backend drop shop-tied promotions for shops outside that
      // shop's own delivery radius from this location; ignored server-side
      // when shopId is set, since that promo is already scoped to one shop.
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      // Scopes shop-tied promotions to shops in this category (e.g. Grocery
      // listing page only shows Grocery shop offers); ignored when shopId is set.
      if (category != null) queryParams['category'] = category;

      final url = Uri.parse('$_baseUrl/promotions/active')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

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
          Uri.parse('$_baseUrl/promotions/my-usage?customerId=$customerId');

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
  final String? promoCode;
  final double discountAmount;
  final int? promotionId;
  final String? promotionTitle;
  final String? discountType;

  PromoCodeValidationResult({
    required this.isValid,
    required this.message,
    this.promoCode,
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
  /// Promo video for the home banner. The backend only sends this once a
  /// super admin has approved it, so anything non-null here is safe to play.
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final bool? isFirstTimeOnly;
  final String? termsAndConditions;
  final int? shopId;
  final String? shopName;
  final String? shopNameTamil;
  final String? shopBusinessType;
  /// 'PROMO_CODE' (the default - a code the customer redeems) or
  /// 'IMAGE_BANNER' (a super-admin-uploaded picture with an optional link;
  /// no code, no discount, nothing to redeem).
  final String bannerType;
  /// Where an image-only banner should take the customer when tapped. Null or
  /// empty means the banner is just an announcement.
  final String? linkUrl;

  PromoCode({
    required this.id,
    this.code = '',
    required this.title,
    this.description,
    this.type = 'PERCENTAGE',
    this.discountValue = 0,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.usageLimitPerCustomer,
    required this.startDate,
    required this.endDate,
    this.imageUrl,
    this.bannerUrl,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.isFirstTimeOnly,
    this.termsAndConditions,
    this.shopId,
    this.shopName,
    this.shopNameTamil,
    this.shopBusinessType,
    this.bannerType = 'PROMO_CODE',
    this.linkUrl,
  });

  /// Lenient on purpose: [PromoCodeService.getActivePromotions] parses the
  /// whole list inside one try/catch, so a single row that threw here (an
  /// image-only banner with no code/type/discount, or an odd date string)
  /// used to blank the entire home carousel.
  factory PromoCode.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime parseDate(dynamic v, DateTime fallback) {
      if (v == null) return fallback;
      return DateTime.tryParse(v.toString()) ?? fallback;
    }

    final now = DateTime.now();
    final type = json['type']?.toString();

    return PromoCode(
      id: asInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      type: (type == null || type.isEmpty) ? 'PERCENTAGE' : type,
      discountValue: asDouble(json['discountValue']) ?? 0,
      minimumOrderAmount: asDouble(json['minimumOrderAmount']),
      maximumDiscountAmount: asDouble(json['maximumDiscountAmount']),
      usageLimitPerCustomer: asInt(json['usageLimitPerCustomer']),
      startDate: parseDate(json['startDate'], now),
      // A banner with no readable end date is treated as open-ended rather
      // than dropped.
      endDate: parseDate(json['endDate'], now.add(const Duration(days: 365 * 10))),
      imageUrl: json['imageUrl']?.toString(),
      bannerUrl: json['bannerUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      videoThumbnailUrl: json['videoThumbnailUrl']?.toString(),
      isFirstTimeOnly: json['isFirstTimeOnly'] is bool
          ? json['isFirstTimeOnly'] as bool
          : null,
      termsAndConditions: json['termsAndConditions']?.toString(),
      shopId: asInt(json['shopId']),
      shopName: json['shopName']?.toString(),
      shopNameTamil: json['shopNameTamil']?.toString(),
      shopBusinessType: json['shopBusinessType']?.toString(),
      bannerType: json['bannerType']?.toString() ?? 'PROMO_CODE',
      linkUrl: json['linkUrl']?.toString(),
    );
  }

  bool get hasVideo => videoUrl != null && videoUrl!.trim().isNotEmpty;

  /// A picture-only banner: nothing to redeem, so no code/discount text
  /// should ever be drawn for it.
  bool get isImageOnly => bannerType == 'IMAGE_BANNER';

  bool get hasLink => linkUrl != null && linkUrl!.trim().isNotEmpty;

  String get formattedDiscount {
    if (isImageOnly) return '';
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
