import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';

/// Razorpay integration for customer order checkout — mirrors PostPaymentService's
/// pattern but hits the order-payment endpoints instead of the classifieds ones.
class OrderPaymentService {
  static bool _isSuccess(dynamic data) {
    return data is Map && data['statusCode'] == AppConstants.successCode;
  }

  /// Create a Razorpay order for an existing (already-placed, PENDING) order.
  static Future<Map<String, dynamic>> createOrder(int orderId) async {
    try {
      final response = await ApiClient.post('/customer/orders/$orderId/payment/create-order');
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to create payment order'};
    } on DioException catch (e) {
      Logger.e('Failed to create order payment', 'ORDER_PAYMENT', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to create payment order'};
    }
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required int orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String? razorpaySignature,
  }) async {
    try {
      final response = await ApiClient.post(
        '/customer/orders/$orderId/payment/verify',
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          if (razorpaySignature != null) 'razorpay_signature': razorpaySignature,
        },
      );
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Payment verification failed'};
    } on DioException catch (e) {
      Logger.e('Failed to verify order payment', 'ORDER_PAYMENT', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Payment verification failed'};
    }
  }
}
