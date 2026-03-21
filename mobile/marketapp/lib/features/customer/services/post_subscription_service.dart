import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

class PostSubscriptionService {
  static bool _isSuccess(dynamic data) {
    return data is Map && data['statusCode'] == AppConstants.successCode;
  }

  /// Get subscription config (price, enabled, razorpay key)
  static Future<Map<String, dynamic>> getConfig({String postType = 'MARKETPLACE'}) async {
    try {
      final response = await ApiClient.get(
        '/subscriptions/config',
        queryParameters: {'postType': postType},
      );
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to get config'};
    } on DioException catch (e) {
      Logger.e('Failed to get subscription config', 'SUBSCRIPTION', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to get config'};
    }
  }

  /// Create a Razorpay subscription for the given post type
  static Future<Map<String, dynamic>> createSubscription(String postType) async {
    try {
      final response = await ApiClient.post(
        '/subscriptions/create',
        data: {'postType': postType},
      );
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to create subscription'};
    } on DioException catch (e) {
      Logger.e('Failed to create subscription', 'SUBSCRIPTION', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to create subscription'};
    }
  }

  /// Verify subscription after mandate setup in Razorpay
  static Future<Map<String, dynamic>> verifySubscription({
    required int subscriptionDbId,
    required String razorpaySubscriptionId,
    String razorpayPaymentId = '',
  }) async {
    try {
      final response = await ApiClient.post(
        '/subscriptions/verify',
        data: {
          'subscriptionDbId': subscriptionDbId,
          'razorpaySubscriptionId': razorpaySubscriptionId,
          'razorpayPaymentId': razorpayPaymentId,
        },
      );
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Verification failed'};
    } on DioException catch (e) {
      Logger.e('Failed to verify subscription', 'SUBSCRIPTION', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Verification failed'};
    }
  }

  /// Link subscription to a post after post is created
  static Future<Map<String, dynamic>> linkToPost({
    required int subscriptionDbId,
    required int postId,
  }) async {
    try {
      final response = await ApiClient.post(
        '/subscriptions/$subscriptionDbId/link-post',
        data: {'postId': postId},
      );
      if (_isSuccess(response.data)) {
        return {'success': true};
      }
      return {'success': false};
    } on DioException catch (e) {
      Logger.e('Failed to link subscription to post', 'SUBSCRIPTION', e);
      return {'success': false};
    }
  }

  /// Get current user's subscriptions
  static Future<Map<String, dynamic>> getMySubscriptions() async {
    try {
      final response = await ApiClient.get('/subscriptions/my');
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed'};
    } on DioException catch (e) {
      Logger.e('Failed to get subscriptions', 'SUBSCRIPTION', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed'};
    }
  }

  /// Get subscription status (has active subscription)
  static Future<Map<String, dynamic>> getStatus() async {
    try {
      final response = await ApiClient.get('/subscriptions/status');
      if (_isSuccess(response.data)) {
        return {'success': true, 'data': response.data['data']};
      }
      return {'success': false};
    } on DioException catch (e) {
      Logger.e('Failed to get subscription status', 'SUBSCRIPTION', e);
      return {'success': false};
    }
  }

  /// Cancel a subscription
  static Future<Map<String, dynamic>> cancelSubscription(int subscriptionDbId) async {
    try {
      final response = await ApiClient.post('/subscriptions/$subscriptionDbId/cancel');
      if (_isSuccess(response.data)) {
        return {'success': true, 'message': response.data['data']?['message'] ?? 'Cancelled'};
      }
      return {'success': false, 'message': response.data?['message'] ?? 'Failed to cancel'};
    } on DioException catch (e) {
      Logger.e('Failed to cancel subscription', 'SUBSCRIPTION', e);
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to cancel'};
    }
  }
}
