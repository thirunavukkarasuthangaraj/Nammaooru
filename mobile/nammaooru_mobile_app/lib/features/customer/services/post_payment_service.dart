import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';

class PostPaymentService {
  /// Get payment config (price, enabled, razorpay key)
  static Future<Map<String, dynamic>> getConfig() async {
    try {
      final response = await ApiClient.get('/post-payments/config');
      if (response.data?['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Failed to get config'};
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
      if (response.data?['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Failed to create order'};
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
      if (response.data?['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Failed to get payment history'};
    } on DioException catch (e) {
      Logger.e('Failed to get payment history', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to get payment history',
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
      if (response.data?['success'] == true) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      }
      return {'success': false, 'message': 'Payment verification failed'};
    } on DioException catch (e) {
      Logger.e('Failed to verify payment', 'POST_PAYMENT', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Payment verification failed',
      };
    }
  }
}
