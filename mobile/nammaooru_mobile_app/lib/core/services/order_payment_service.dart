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

  /// Fetches the current gateway fee percent so checkout can show it in the
  /// bill summary before the order is even placed. Falls back to the
  /// backend's own default if the call fails, so the UI never shows nothing.
  static Future<double> getGatewayFeePercent() async {
    try {
      final response = await ApiClient.get('/customer/order-payments/config');
      if (_isSuccess(response.data)) {
        final percent = response.data['data']?['gatewayFeePercent'];
        if (percent != null) return double.parse(percent.toString());
      }
    } catch (e) {
      Logger.e('Failed to fetch gateway fee percent', 'ORDER_PAYMENT', e);
    }
    return 0.0;
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
