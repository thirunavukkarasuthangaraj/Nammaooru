import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

class PostPaymentService {
  /// Check if raw API response is successful (statusCode == '0000')
  static bool _isSuccess(dynamic data) {
    return data is Map && data['statusCode'] == AppConstants.successCode;
  }

  /// Get payment config (price, enabled, razorpay key)
  static Future<Map<String, dynamic>> getConfig({String? postType}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (postType != null && postType.isNotEmpty) {
        queryParams['postType'] = postType;
      }
      final response = await ApiClient.get(
        '/post-payments/config',
        queryParameters: queryParams,
      );
      if (_isSuccess(response.data)) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to get config'};
    } on DioException catch (e) {
      Logger.e('Failed to get payment config', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to get payment config',
      };
    }
  }

  /// Create Razorpay order
  static Future<Map<String, dynamic>> createOrder(String postType) async {
    try {
      final response = await ApiClient.post(
        '/post-payments/create-order',
        data: {'postType': postType},
      );
      if (_isSuccess(response.data)) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to create order'};
    } on DioException catch (e) {
      Logger.e('Failed to create payment order', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to create order',
      };
    }
  }

  /// Get current user's payment history
  static Future<Map<String, dynamic>> getMyPayments({int page = 0, int size = 20}) async {
    try {
      final response = await ApiClient.get(
        '/post-payments/my',
        queryParameters: {'page': page, 'size': size},
      );
      if (_isSuccess(response.data)) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to get payment history'};
    } on DioException catch (e) {
      Logger.e('Failed to get payment history', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to get payment history',
      };
    }
  }

  /// Create bulk Razorpay order for renewing multiple posts
  static Future<Map<String, dynamic>> createBulkOrder(String postType, int count) async {
    try {
      final response = await ApiClient.post(
        '/post-payments/create-bulk-order',
        data: {'postType': postType, 'count': count},
      );
      if (_isSuccess(response.data)) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to create bulk order'};
    } on DioException catch (e) {
      Logger.e('Failed to create bulk payment order', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to create bulk order',
      };
    }
  }

  /// Verify bulk payment and get list of paid token IDs
  static Future<Map<String, dynamic>> verifyBulkPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await ApiClient.post(
        '/post-payments/verify-bulk',
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );
      if (_isSuccess(response.data)) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Bulk payment verification failed'};
    } on DioException catch (e) {
      Logger.e('Failed to verify bulk payment', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Bulk payment verification failed',
      };
    }
  }

  /// Verify payment and get paid token ID
  static Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await ApiClient.post(
        '/post-payments/verify',
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );
      if (_isSuccess(response.data)) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Payment verification failed'};
    } on DioException catch (e) {
      Logger.e('Failed to verify payment', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Payment verification failed',
      };
    }
  }
}
