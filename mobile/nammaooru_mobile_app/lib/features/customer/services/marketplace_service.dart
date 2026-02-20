import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class MarketplaceService {
  final ApiService _apiService = ApiService();

  /// Get approved marketplace posts (public feed)
  Future<Map<String, dynamic>> getApprovedPosts({
    int page = 0,
    int size = 20,
    String? category,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? search,
  }) async {
    try {
      Logger.api('Fetching marketplace posts - page: $page, size: $size, category: $category');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude.toString();
        queryParams['lng'] = longitude.toString();
        if (radiusKm != null) {
          queryParams['radius'] = radiusKm.toString();
        }
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        '/marketplace',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch marketplace posts', 'MARKETPLACE', e);
      rethrow;
    }
  }

  /// Get my posts (seller's own posts)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my marketplace posts');

      final response = await _apiService.get(
        '/marketplace/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my posts', 'MARKETPLACE', e);
      rethrow;
    }
  }

  /// Create a new marketplace post with multipart upload
  Future<Map<String, dynamic>> createPost({
    required String title,
    String? description,
    double? price,
    required String phone,
    String? category,
    String? location,
    String? imagePath,
    String? voicePath,
    int? paidTokenId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Logger.api('Creating marketplace post: $title, paidTokenId: $paidTokenId');

      final formMap = <String, dynamic>{
        'title': title,
        'phone': phone,
      };

      if (description != null && description.isNotEmpty) {
        formMap['description'] = description;
      }
      if (price != null) {
        formMap['price'] = price.toString();
      }
      if (category != null && category.isNotEmpty) {
        formMap['category'] = category;
      }
      if (location != null && location.isNotEmpty) {
        formMap['location'] = location;
      }
      if (paidTokenId != null) {
        formMap['paidTokenId'] = paidTokenId.toString();
      }
      if (latitude != null) {
        formMap['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        formMap['longitude'] = longitude.toString();
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        // Get proper filename with extension from the actual file path
        final imageFileName = imagePath.split('/').last;
        formMap['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: imageFileName.isNotEmpty ? imageFileName : 'image.jpg',
        );
      }
      if (voicePath != null && voicePath.isNotEmpty) {
        final voiceFileName = voicePath.split('/').last;
        formMap['voice'] = await MultipartFile.fromFile(
          voicePath,
          filename: voiceFileName.isNotEmpty ? voiceFileName : 'voice.m4a',
        );
      }

      final formData = FormData.fromMap(formMap);

      // Use Dio directly for multipart upload - don't set Content-Type manually
      // Dio will auto-generate the correct multipart/form-data with boundary
      final dio = ApiClient.dio;

      // Add auth token
      final token = await _getAuthToken();
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '/marketplace',
        data: formData,
        options: Options(headers: headers),
      );

      final responseCode = response.data?['statusCode']?.toString() ?? '';
      if (responseCode.isNotEmpty && responseCode != '0000') {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to create post',
          'statusCode': responseCode,
        };
      }

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post submitted for approval',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create marketplace post', 'MARKETPLACE', e);
      final statusCode = e.response?.statusCode;
      final errorCode = e.response?.data?['statusCode'] ?? '';
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create post. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
        'statusCode': errorCode,
        'httpStatus': statusCode,
      };
    } catch (e) {
      Logger.e('Failed to create marketplace post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      return await SecureStorage.getAuthToken();
    } catch (e) {
      Logger.e('Failed to get auth token', 'MARKETPLACE', e);
      return null;
    }
  }

  /// Mark a post as sold
  Future<Map<String, dynamic>> markAsSold(int postId) async {
    try {
      Logger.api('Marking post as sold: $postId');

      final response = await ApiClient.put(
        '/marketplace/$postId/sold',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post marked as sold',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark post as sold', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as sold',
      };
    } catch (e) {
      Logger.e('Failed to mark post as sold', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a post
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting marketplace post: $postId');

      final response = await ApiClient.delete(
        '/marketplace/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Post deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete post',
      };
    } catch (e) {
      Logger.e('Failed to delete post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Renew an expired/expiring post
  Future<Map<String, dynamic>> renewPost(int postId, {int? paidTokenId}) async {
    try {
      Logger.api('Renewing marketplace post: $postId, paidTokenId: $paidTokenId');

      final queryParams = <String, dynamic>{};
      if (paidTokenId != null) {
        queryParams['paidTokenId'] = paidTokenId;
      }

      final response = await ApiClient.put(
        '/marketplace/$postId/renew',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post renewed successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to renew marketplace post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to renew post',
      };
    } catch (e) {
      Logger.e('Failed to renew marketplace post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Edit a post (text fields only, no image changes)
  Future<Map<String, dynamic>> editPost(int postId, Map<String, dynamic> updates) async {
    try {
      Logger.api('Editing marketplace post: $postId');

      final response = await ApiClient.put(
        '/marketplace/$postId/edit',
        data: updates,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post updated successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to edit marketplace post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to edit post',
      };
    } catch (e) {
      Logger.e('Failed to edit marketplace post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a post as fake/stolen/inappropriate
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting marketplace post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/marketplace/$postId/report',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Post reported successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to report post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report post',
      };
    } catch (e) {
      Logger.e('Failed to report post', 'MARKETPLACE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
