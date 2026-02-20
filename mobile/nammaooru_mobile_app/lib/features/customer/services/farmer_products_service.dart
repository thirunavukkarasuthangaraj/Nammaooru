import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class FarmerProductsService {
  final ApiService _apiService = ApiService();

  /// Get approved farmer product posts (public feed)
  Future<Map<String, dynamic>> getApprovedPosts({
    int page = 0,
    int size = 20,
    String? category,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) async {
    try {
      Logger.api('Fetching farmer products - page: $page, size: $size, category: $category');

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

      final response = await _apiService.get(
        '/farmer-products',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch farmer products', 'FARMER_PRODUCTS', e);
      rethrow;
    }
  }

  /// Get my posts (farmer's own posts)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my farmer product posts');

      final response = await _apiService.get(
        '/farmer-products/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my farmer posts', 'FARMER_PRODUCTS', e);
      rethrow;
    }
  }

  /// Create a new farmer product post with multipart upload (supports up to 5 images)
  Future<Map<String, dynamic>> createPost({
    required String title,
    String? description,
    double? price,
    required String phone,
    String? category,
    String? location,
    String? unit,
    List<String>? imagePaths,
    int? paidTokenId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Logger.api('Creating farmer product post: $title, paidTokenId: $paidTokenId');

      final formMap = <String, dynamic>{
        'title': title,
        'phone': phone,
      };

      if (paidTokenId != null) {
        formMap['paidTokenId'] = paidTokenId.toString();
      }
      if (latitude != null) {
        formMap['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        formMap['longitude'] = longitude.toString();
      }

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
      if (unit != null && unit.isNotEmpty) {
        formMap['unit'] = unit;
      }

      // Add images to formMap BEFORE creating FormData (same pattern as marketplace)
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final List<MultipartFile> imageFiles = [];
        for (final imagePath in imagePaths) {
          if (imagePath.isNotEmpty) {
            final imageFileName = imagePath.split('/').last;
            imageFiles.add(await MultipartFile.fromFile(
              imagePath,
              filename: imageFileName.isNotEmpty ? imageFileName : 'image.jpg',
            ));
          }
        }
        if (imageFiles.length == 1) {
          formMap['images'] = imageFiles.first;
        } else if (imageFiles.isNotEmpty) {
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
        '/farmer-products',
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
      Logger.e('Failed to create farmer product post', 'FARMER_PRODUCTS', e);
      final errorCode = e.response?.data?['statusCode'] ?? '';
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create post. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
        'statusCode': errorCode,
        'httpStatus': e.response?.statusCode,
      };
    } catch (e) {
      Logger.e('Failed to create farmer product post', 'FARMER_PRODUCTS', e);
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
      Logger.e('Failed to get auth token', 'FARMER_PRODUCTS', e);
      return null;
    }
  }

  /// Mark a post as sold
  Future<Map<String, dynamic>> markAsSold(int postId) async {
    try {
      Logger.api('Marking farmer product as sold: $postId');

      final response = await ApiClient.put(
        '/farmer-products/$postId/sold',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post marked as sold',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark farmer product as sold', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as sold',
      };
    } catch (e) {
      Logger.e('Failed to mark farmer product as sold', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a post
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting farmer product post: $postId');

      final response = await ApiClient.delete(
        '/farmer-products/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Post deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete post',
      };
    } catch (e) {
      Logger.e('Failed to delete farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Renew an expired/expiring post
  Future<Map<String, dynamic>> renewPost(int postId, {int? paidTokenId}) async {
    try {
      Logger.api('Renewing farmer product post: $postId, paidTokenId: $paidTokenId');

      final queryParams = <String, dynamic>{};
      if (paidTokenId != null) {
        queryParams['paidTokenId'] = paidTokenId;
      }

      final response = await ApiClient.put(
        '/farmer-products/$postId/renew',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post renewed successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to renew farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to renew post',
      };
    } catch (e) {
      Logger.e('Failed to renew farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Edit a post (text fields only, no image changes)
  Future<Map<String, dynamic>> editPost(int postId, Map<String, dynamic> updates) async {
    try {
      Logger.api('Editing farmer product post: $postId');

      final response = await ApiClient.put(
        '/farmer-products/$postId/edit',
        data: updates,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post updated successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to edit farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to edit post',
      };
    } catch (e) {
      Logger.e('Failed to edit farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a post
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting farmer product post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/farmer-products/$postId/report',
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
      Logger.e('Failed to report farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report post',
      };
    } catch (e) {
      Logger.e('Failed to report farmer product post', 'FARMER_PRODUCTS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
