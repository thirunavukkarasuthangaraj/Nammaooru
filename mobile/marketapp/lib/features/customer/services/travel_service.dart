import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class TravelService {
  final ApiService _apiService = ApiService();

  /// Get approved travel posts (public feed)
  Future<Map<String, dynamic>> getApprovedPosts({
    int page = 0,
    int size = 20,
    String? vehicleType,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? search,
  }) async {
    try {
      Logger.api('Fetching travel posts - page: $page, size: $size, vehicleType: $vehicleType');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (vehicleType != null && vehicleType.isNotEmpty) {
        queryParams['vehicleType'] = vehicleType;
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
        '/travels',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch travel posts', 'TRAVELS', e);
      rethrow;
    }
  }

  /// Get my posts (user's own travel listings)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my travel posts');

      final response = await _apiService.get(
        '/travels/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my travel posts', 'TRAVELS', e);
      rethrow;
    }
  }

  /// Create a new travel post with optional images (up to 3)
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String phone,
    required String vehicleType,
    String? fromLocation,
    String? toLocation,
    String? price,
    int? seatsAvailable,
    String? description,
    List<String>? imagePaths,
    double? latitude,
    double? longitude,
    int? paidTokenId,
    bool isBanner = false,
  }) async {
    try {
      Logger.api('Creating travel post: $title ($vehicleType), paidTokenId: $paidTokenId');

      final formMap = <String, dynamic>{
        'title': title,
        'phone': phone,
        'vehicleType': vehicleType,
      };

      if (paidTokenId != null) {
        formMap['paidTokenId'] = paidTokenId.toString();
      }
      if (isBanner) {
        formMap['isBanner'] = 'true';
      }

      if (fromLocation != null && fromLocation.isNotEmpty) {
        formMap['fromLocation'] = fromLocation;
      }
      if (toLocation != null && toLocation.isNotEmpty) {
        formMap['toLocation'] = toLocation;
      }
      if (price != null && price.isNotEmpty) {
        formMap['price'] = price;
      }
      if (seatsAvailable != null) {
        formMap['seatsAvailable'] = seatsAvailable.toString();
      }
      if (description != null && description.isNotEmpty) {
        formMap['description'] = description;
      }
      if (latitude != null) {
        formMap['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        formMap['longitude'] = longitude.toString();
      }

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
        '/travels',
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
        'message': response.data?['message'] ?? 'Travel listing submitted successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create travel post', 'TRAVELS', e);
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
      Logger.e('Failed to create travel post', 'TRAVELS', e);
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
      Logger.e('Failed to get auth token', 'TRAVELS', e);
      return null;
    }
  }

  /// Mark a listing as available (toggle back from unavailable)
  Future<Map<String, dynamic>> markAsAvailable(int postId) async {
    try {
      Logger.api('Marking travel post as available: $postId');

      final response = await ApiClient.put(
        '/travels/$postId/available',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Listing marked as available',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark travel post as available', 'TRAVELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as available',
      };
    } catch (e) {
      Logger.e('Failed to mark travel post as available', 'TRAVELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Mark a listing as unavailable
  Future<Map<String, dynamic>> markAsUnavailable(int postId) async {
    try {
      Logger.api('Marking travel post as unavailable: $postId');

      final response = await ApiClient.put(
        '/travels/$postId/unavailable',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Listing marked as unavailable',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark travel post as unavailable', 'TRAVELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as unavailable',
      };
    } catch (e) {
      Logger.e('Failed to mark travel post as unavailable', 'TRAVELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a listing
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting travel post: $postId');

      final response = await ApiClient.delete(
        '/travels/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Listing deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete travel post', 'TRAVELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete listing',
      };
    } catch (e) {
      Logger.e('Failed to delete travel post', 'TRAVELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Renew an expired/expiring post
  Future<Map<String, dynamic>> renewPost(int postId, {int? paidTokenId}) async {
    try {
      Logger.api('Renewing travel post: $postId, paidTokenId: $paidTokenId');

      final queryParams = <String, dynamic>{};
      if (paidTokenId != null) {
        queryParams['paidTokenId'] = paidTokenId;
      }

      final response = await ApiClient.put(
        '/travels/$postId/renew',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Listing renewed successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to renew travel post', 'TRAVELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to renew listing',
      };
    } catch (e) {
      Logger.e('Failed to renew travel post', 'TRAVELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Edit a post (text fields only, no image changes)
  Future<Map<String, dynamic>> editPost(int postId, Map<String, dynamic> updates) async {
    try {
      Logger.api('Editing travel post: $postId');

      final response = await ApiClient.put(
        '/travels/$postId/edit',
        data: updates,
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Post updated successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to edit travel post', 'TRAVEL', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to edit post',
      };
    } catch (e) {
      Logger.e('Failed to edit travel post', 'TRAVEL', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a listing
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting travel post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/travels/$postId/report',
        data: {
          'reason': reason,
          if (details != null && details.isNotEmpty) 'details': details,
        },
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Listing reported successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to report travel post', 'TRAVELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report listing',
      };
    } catch (e) {
      Logger.e('Failed to report travel post', 'TRAVELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
