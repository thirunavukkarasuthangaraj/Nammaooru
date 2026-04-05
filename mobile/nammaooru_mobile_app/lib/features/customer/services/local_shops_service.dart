import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class LocalShopsService {
  final ApiService _apiService = ApiService();

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
      Logger.api('Fetching local shop posts - page: $page, size: $size, category: $category');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null && category.isNotEmpty) queryParams['category'] = category;
      if (latitude != null && longitude != null) {
        queryParams['lat'] = latitude.toString();
        queryParams['lng'] = longitude.toString();
        if (radiusKm != null) queryParams['radius'] = radiusKm.toString();
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        '/local-shops',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch local shop posts', 'LOCAL_SHOPS', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my local shop posts');
      final response = await _apiService.get('/local-shops/my', includeAuth: true);
      return response;
    } catch (e) {
      Logger.e('Failed to fetch my local shop posts', 'LOCAL_SHOPS', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String shopName,
    required String phone,
    required String category,
    String? address,
    String? timings,
    String? description,
    List<String>? imagePaths,
    double? latitude,
    double? longitude,
    int? paidTokenId,
    bool isBanner = false,
  }) async {
    try {
      Logger.api('Creating local shop post: $shopName ($category)');

      final formMap = <String, dynamic>{
        'shopName': shopName,
        'phone': phone,
        'category': category,
      };

      if (paidTokenId != null) formMap['paidTokenId'] = paidTokenId.toString();
      if (isBanner) formMap['isBanner'] = 'true';
      if (address != null && address.isNotEmpty) formMap['address'] = address;
      if (timings != null && timings.isNotEmpty) formMap['timings'] = timings;
      if (description != null && description.isNotEmpty) formMap['description'] = description;
      if (latitude != null) formMap['latitude'] = latitude.toString();
      if (longitude != null) formMap['longitude'] = longitude.toString();

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
      final headers = <String, dynamic>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await dio.post(
        '/local-shops',
        data: formData,
        options: Options(headers: headers),
      );

      final responseCode = response.data?['statusCode']?.toString() ?? '';
      if (responseCode.isNotEmpty && responseCode != '0000') {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to create listing',
          'statusCode': responseCode,
        };
      }

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Shop listing submitted successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create local shop post', 'LOCAL_SHOPS', e);
      final errorCode = e.response?.data?['statusCode'] ?? '';
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create listing. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
        'statusCode': errorCode,
        'httpStatus': e.response?.statusCode,
      };
    } catch (e) {
      Logger.e('Failed to create local shop post', 'LOCAL_SHOPS', e);
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      return await SecureStorage.getAuthToken();
    } catch (e) {
      Logger.e('Failed to get auth token', 'LOCAL_SHOPS', e);
      return null;
    }
  }

  Future<Map<String, dynamic>> markAsAvailable(int postId) async {
    try {
      final response = await ApiClient.put('/local-shops/$postId/available');
      return {'success': true, 'data': response.data?['data'], 'message': response.data?['message'] ?? 'Listing marked as open'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to mark as open'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> markAsUnavailable(int postId) async {
    try {
      final response = await ApiClient.put('/local-shops/$postId/unavailable');
      return {'success': true, 'data': response.data?['data'], 'message': response.data?['message'] ?? 'Listing marked as closed'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to mark as closed'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final response = await ApiClient.delete('/local-shops/$postId');
      return {'success': true, 'message': response.data?['message'] ?? 'Listing deleted'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to delete listing'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> renewPost(int postId, {int? paidTokenId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (paidTokenId != null) queryParams['paidTokenId'] = paidTokenId;
      final response = await ApiClient.put(
        '/local-shops/$postId/renew',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return {'success': true, 'data': response.data?['data'], 'message': response.data?['message'] ?? 'Listing renewed'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to renew listing'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> editPost(int postId, Map<String, dynamic> updates) async {
    try {
      final response = await ApiClient.put('/local-shops/$postId/edit', data: updates);
      return {'success': true, 'data': response.data?['data'], 'message': response.data?['message'] ?? 'Post updated'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to edit post'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }

  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      final response = await ApiClient.post(
        '/local-shops/$postId/report',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );
      return {'success': true, 'message': response.data?['message'] ?? 'Listing reported successfully'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to report listing'};
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred: $e'};
    }
  }
}
