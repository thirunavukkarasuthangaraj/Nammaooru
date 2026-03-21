import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class RentalService {
  final ApiService _apiService = ApiService();

  /// Get approved rental posts (public feed)
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
      Logger.api('Fetching rental posts - page: $page, size: $size, category: $category');

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
        '/rentals',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch rental posts', 'RENTAL', e);
      rethrow;
    }
  }

  /// Get my posts (owner's own posts)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my rental posts');

      final response = await _apiService.get(
        '/rentals/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my rental posts', 'RENTAL', e);
      rethrow;
    }
  }

  /// Create a new rental post with multipart upload
  Future<Map<String, dynamic>> createPost({
    required String title,
    String? description,
    double? price,
    String? priceUnit,
    required String phone,
    String? category,
    String? location,
    List<String>? imagePaths,
    double? latitude,
    double? longitude,
    int? paidTokenId,
    bool isBanner = false,
  }) async {
    try {
      Logger.api('Creating rental post: $title, paidTokenId: $paidTokenId');

      final formMap = <String, dynamic>{
        'title': title,
        'phone': phone,
      };

      if (paidTokenId != null) {
        formMap['paidTokenId'] = paidTokenId.toString();
      }
      if (isBanner) {
        formMap['isBanner'] = 'true';
      }

      if (description != null && description.isNotEmpty) {
        formMap['description'] = description;
      }
      if (price != null) {
        formMap['price'] = price.toString();
      }
      if (priceUnit != null && priceUnit.isNotEmpty) {
        formMap['priceUnit'] = priceUnit;
      }
      if (category != null && category.isNotEmpty) {
        formMap['category'] = category;
      }
      if (location != null && location.isNotEmpty) {
        formMap['location'] = location;
      }
      if (latitude != null) {
        formMap['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        formMap['longitude'] = longitude.toString();
      }

      // Multi-image upload
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final imageFiles = <MultipartFile>[];
        for (final path in imagePaths) {
          if (path.isNotEmpty) {
            final fileName = path.split('/').last;
            imageFiles.add(await MultipartFile.fromFile(
              path,
              filename: fileName.isNotEmpty ? fileName : 'image.jpg',
            ));
          }
        }
        if (imageFiles.isNotEmpty) {
          formMap['images'] = imageFiles;
        }
      }

      final formData = FormData.fromMap(formMap);

      final dio = ApiClient.dio;
      final token = await _getAuthToken();
      final headers = <String, dynamic>{
        'Accept': 'application/json',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '/rentals',
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
      Logger.e('Failed to create rental post', 'RENTAL', e);
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create post. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      Logger.e('Failed to create rental post', 'RENTAL', e);
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
      Logger.e('Failed to get auth token', 'RENTAL', e);
      return null;
    }
  }

  /// Mark a post as rented
  Future<Map<String, dynamic>> markAsRented(int postId) async {
    try {
      Logger.api('Marking rental post as rented: $postId');

      final response = await ApiClient.put(
        '/rentals/$postId/rented',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post marked as rented',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark post as rented', 'RENTAL', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as rented',
      };
    } catch (e) {
      Logger.e('Failed to mark post as rented', 'RENTAL', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a post
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting rental post: $postId');

      final response = await ApiClient.delete(
        '/rentals/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Post deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete post',
      };
    } catch (e) {
      Logger.e('Failed to delete rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Renew an expired/expiring post
  Future<Map<String, dynamic>> renewPost(int postId) async {
    try {
      Logger.api('Renewing rental post: $postId');

      final response = await ApiClient.put(
        '/rentals/$postId/renew',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post renewed successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to renew rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to renew post',
      };
    } catch (e) {
      Logger.e('Failed to renew rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Edit a post (text fields only)
  Future<Map<String, dynamic>> editPost(int postId, Map<String, dynamic> updates) async {
    try {
      Logger.api('Editing rental post: $postId');

      final response = await ApiClient.put(
        '/rentals/$postId/edit',
        data: updates,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post updated successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to edit rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to edit post',
      };
    } catch (e) {
      Logger.e('Failed to edit rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a post
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting rental post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/rentals/$postId/report',
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
      Logger.e('Failed to report rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report post',
      };
    } catch (e) {
      Logger.e('Failed to report rental post', 'RENTAL', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
