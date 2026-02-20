import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class RealEstateService {
  final ApiService _apiService = ApiService();

  /// Get approved real estate posts (public feed)
  Future<Map<String, dynamic>> getApprovedPosts({
    int page = 0,
    int size = 20,
    String? propertyType,
    String? listingType,
    String? location,
    String? search,
  }) async {
    try {
      Logger.api('Fetching real estate posts - page: $page, propertyType: $propertyType, listingType: $listingType');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (propertyType != null && propertyType.isNotEmpty) {
        queryParams['propertyType'] = propertyType;
      }
      if (listingType != null && listingType.isNotEmpty) {
        queryParams['listingType'] = listingType;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        '/real-estate',
        queryParams: queryParams,
        includeAuth: false,  // Public endpoint
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch real estate posts', 'REAL_ESTATE', e);
      rethrow;
    }
  }

  /// Get featured properties
  Future<Map<String, dynamic>> getFeaturedPosts({
    int page = 0,
    int size = 10,
  }) async {
    try {
      Logger.api('Fetching featured real estate posts');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      final response = await _apiService.get(
        '/real-estate/featured',
        queryParams: queryParams,
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch featured posts', 'REAL_ESTATE', e);
      rethrow;
    }
  }

  /// Get property by ID
  Future<Map<String, dynamic>> getPostById(int id) async {
    try {
      Logger.api('Fetching real estate post: $id');

      final response = await _apiService.get(
        '/real-estate/$id',
        includeAuth: false,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch real estate post', 'REAL_ESTATE', e);
      rethrow;
    }
  }

  /// Get my properties (seller's own posts)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my real estate posts');

      final response = await _apiService.get(
        '/real-estate/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my properties', 'REAL_ESTATE', e);
      rethrow;
    }
  }

  /// Create a new real estate post with multipart upload
  Future<Map<String, dynamic>> createPost({
    required String title,
    String? description,
    required String propertyType,
    required String listingType,
    double? price,
    int? areaSqft,
    int? bedrooms,
    int? bathrooms,
    String? location,
    double? latitude,
    double? longitude,
    required String phone,
    List<String>? imagePaths,
    String? videoPath,
  }) async {
    try {
      Logger.api('Creating real estate post: $title, type: $propertyType');

      final formMap = <String, dynamic>{
        'title': title,
        'propertyType': propertyType.toUpperCase().replaceAll(' ', '_'),
        'listingType': listingType.toUpperCase().replaceAll(' ', '_'),
        'phone': phone,
      };

      if (description != null && description.isNotEmpty) {
        formMap['description'] = description;
      }
      if (price != null) {
        formMap['price'] = price.toString();
      }
      if (areaSqft != null) {
        formMap['areaSqft'] = areaSqft.toString();
      }
      if (bedrooms != null) {
        formMap['bedrooms'] = bedrooms.toString();
      }
      if (bathrooms != null) {
        formMap['bathrooms'] = bathrooms.toString();
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

      // Add images (up to 5)
      if (imagePaths != null && imagePaths.isNotEmpty) {
        final imageFiles = <MultipartFile>[];
        for (int i = 0; i < imagePaths.length && i < 5; i++) {
          final path = imagePaths[i];
          if (path.isNotEmpty) {
            final fileName = path.split('/').last;
            imageFiles.add(await MultipartFile.fromFile(
              path,
              filename: fileName.isNotEmpty ? fileName : 'image_$i.jpg',
            ));
          }
        }
        if (imageFiles.isNotEmpty) {
          formMap['images'] = imageFiles;
        }
      }

      // Add video if provided
      if (videoPath != null && videoPath.isNotEmpty) {
        final videoFileName = videoPath.split('/').last;
        formMap['video'] = await MultipartFile.fromFile(
          videoPath,
          filename: videoFileName.isNotEmpty ? videoFileName : 'video.mp4',
        );
      }

      final formData = FormData.fromMap(formMap);

      // Use Dio directly for multipart upload
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
        '/real-estate',
        data: formData,
        options: Options(headers: headers),
      );

      final responseCode = response.data?['statusCode']?.toString() ?? '';
      if (responseCode.isNotEmpty && responseCode != '0000') {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to create property listing',
          'statusCode': responseCode,
        };
      }

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Property listing submitted for approval',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create real estate post', 'REAL_ESTATE', e);
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create property listing. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      Logger.e('Failed to create real estate post', 'REAL_ESTATE', e);
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
      Logger.e('Failed to get auth token', 'REAL_ESTATE', e);
      return null;
    }
  }

  /// Mark a property as sold
  Future<Map<String, dynamic>> markAsSold(int postId) async {
    try {
      Logger.api('Marking property as sold: $postId');

      final response = await ApiClient.put(
        '/real-estate/$postId/sold',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Property marked as sold',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark property as sold', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as sold',
      };
    } catch (e) {
      Logger.e('Failed to mark property as sold', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Mark a property as rented
  Future<Map<String, dynamic>> markAsRented(int postId) async {
    try {
      Logger.api('Marking property as rented: $postId');

      final response = await ApiClient.put(
        '/real-estate/$postId/rented',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Property marked as rented',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark property as rented', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as rented',
      };
    } catch (e) {
      Logger.e('Failed to mark property as rented', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a property
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting real estate post: $postId');

      final response = await ApiClient.delete(
        '/real-estate/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Property deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete property', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete property',
      };
    } catch (e) {
      Logger.e('Failed to delete property', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Renew an expired/expiring post
  Future<Map<String, dynamic>> renewPost(int postId) async {
    try {
      Logger.api('Renewing real estate post: $postId');

      final response = await ApiClient.put(
        '/real-estate/$postId/renew',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Property renewed successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to renew real estate post', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to renew property',
      };
    } catch (e) {
      Logger.e('Failed to renew real estate post', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Edit a post (text fields only, no image changes)
  Future<Map<String, dynamic>> editPost(int postId, Map<String, dynamic> updates) async {
    try {
      Logger.api('Editing real estate post: $postId');

      final response = await ApiClient.put(
        '/real-estate/$postId/edit',
        data: updates,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post updated successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to edit real estate post', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to edit post',
      };
    } catch (e) {
      Logger.e('Failed to edit real estate post', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a property as fake/inappropriate
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting real estate post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/real-estate/$postId/report',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Property reported successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to report property', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report property',
      };
    } catch (e) {
      Logger.e('Failed to report property', 'REAL_ESTATE', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
