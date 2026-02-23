import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class WomensCornerService {
  final ApiService _apiService = ApiService();

  // Categories cache
  List<Map<String, dynamic>>? _categoriesCache;
  DateTime? _categoriesCacheTime;
  static const _cacheDuration = Duration(hours: 1);

  /// Get active categories (cached)
  Future<List<Map<String, dynamic>>> getCategories() async {
    if (_categoriesCache != null &&
        _categoriesCacheTime != null &&
        DateTime.now().difference(_categoriesCacheTime!) < _cacheDuration) {
      return _categoriesCache!;
    }

    try {
      Logger.api('Fetching women\'s corner categories');
      final response = await _apiService.get(
        '/womens-corner/categories',
        includeAuth: false,
      );

      if (response['success'] == true && response['data'] is List) {
        _categoriesCache = List<Map<String, dynamic>>.from(response['data']);
        _categoriesCacheTime = DateTime.now();
        return _categoriesCache!;
      }
      return _categoriesCache ?? [];
    } catch (e) {
      Logger.e('Failed to fetch categories', 'WOMENS_CORNER', e);
      return _categoriesCache ?? [];
    }
  }

  /// Get approved posts (public feed)
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
      Logger.api('Fetching women\'s corner posts - page: $page, category: $category');

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
        '/womens-corner/posts',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch women\'s corner posts', 'WOMENS_CORNER', e);
      rethrow;
    }
  }

  /// Get my posts
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my women\'s corner posts');

      final response = await _apiService.get(
        '/womens-corner/posts/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my women\'s corner posts', 'WOMENS_CORNER', e);
      rethrow;
    }
  }

  /// Create a new post with multipart upload
  Future<Map<String, dynamic>> createPost({
    required String title,
    String? description,
    double? price,
    required String phone,
    String? category,
    String? location,
    List<String>? imagePaths,
    int? paidTokenId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Logger.api('Creating women\'s corner post: $title, paidTokenId: $paidTokenId');

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

      // Add images
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
        '/womens-corner/posts',
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
        'message': response.data?['message'] ?? 'Post submitted successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create women\'s corner post', 'WOMENS_CORNER', e);
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
      Logger.e('Failed to create women\'s corner post', 'WOMENS_CORNER', e);
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
      Logger.e('Failed to get auth token', 'WOMENS_CORNER', e);
      return null;
    }
  }

  /// Mark a post as sold
  Future<Map<String, dynamic>> markAsSold(int postId) async {
    try {
      final response = await ApiClient.put('/womens-corner/posts/$postId/sold');
      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post marked as sold',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as sold',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a post
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final response = await ApiClient.delete('/womens-corner/posts/$postId');
      return {
        'success': true,
        'message': response.data?['message'] ?? 'Post deleted',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete post',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a post
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      final response = await ApiClient.post(
        '/womens-corner/posts/$postId/report',
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
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report post',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
