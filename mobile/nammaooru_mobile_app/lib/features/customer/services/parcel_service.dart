import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class ParcelService {
  final ApiService _apiService = ApiService();

  /// Get approved parcel posts (public feed)
  Future<Map<String, dynamic>> getApprovedPosts({
    int page = 0,
    int size = 20,
    String? serviceType,
  }) async {
    try {
      Logger.api('Fetching parcel posts - page: $page, size: $size, serviceType: $serviceType');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (serviceType != null && serviceType.isNotEmpty) {
        queryParams['serviceType'] = serviceType;
      }

      final response = await _apiService.get(
        '/parcels',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch parcel posts', 'PARCELS', e);
      rethrow;
    }
  }

  /// Get my posts (user's own parcel listings)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my parcel posts');

      final response = await _apiService.get(
        '/parcels/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my parcel posts', 'PARCELS', e);
      rethrow;
    }
  }

  /// Create a new parcel post with optional images (up to 3)
  Future<Map<String, dynamic>> createPost({
    required String serviceName,
    required String phone,
    required String serviceType,
    String? fromLocation,
    String? toLocation,
    String? priceInfo,
    String? address,
    String? timings,
    String? description,
    List<String>? imagePaths,
  }) async {
    try {
      Logger.api('Creating parcel post: $serviceName ($serviceType)');

      final formMap = <String, dynamic>{
        'serviceName': serviceName,
        'phone': phone,
        'serviceType': serviceType,
      };

      if (fromLocation != null && fromLocation.isNotEmpty) {
        formMap['fromLocation'] = fromLocation;
      }
      if (toLocation != null && toLocation.isNotEmpty) {
        formMap['toLocation'] = toLocation;
      }
      if (priceInfo != null && priceInfo.isNotEmpty) {
        formMap['priceInfo'] = priceInfo;
      }
      if (address != null && address.isNotEmpty) {
        formMap['address'] = address;
      }
      if (timings != null && timings.isNotEmpty) {
        formMap['timings'] = timings;
      }
      if (description != null && description.isNotEmpty) {
        formMap['description'] = description;
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
        '/parcels',
        data: formData,
        options: Options(headers: headers),
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Parcel service listing submitted successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create parcel post', 'PARCELS', e);
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create listing. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      Logger.e('Failed to create parcel post', 'PARCELS', e);
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
      Logger.e('Failed to get auth token', 'PARCELS', e);
      return null;
    }
  }

  /// Mark a listing as available (toggle back from unavailable)
  Future<Map<String, dynamic>> markAsAvailable(int postId) async {
    try {
      Logger.api('Marking parcel post as available: $postId');

      final response = await ApiClient.put(
        '/parcels/$postId/available',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Listing marked as available',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark parcel post as available', 'PARCELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as available',
      };
    } catch (e) {
      Logger.e('Failed to mark parcel post as available', 'PARCELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Mark a listing as unavailable
  Future<Map<String, dynamic>> markAsUnavailable(int postId) async {
    try {
      Logger.api('Marking parcel post as unavailable: $postId');

      final response = await ApiClient.put(
        '/parcels/$postId/unavailable',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Listing marked as unavailable',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark parcel post as unavailable', 'PARCELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as unavailable',
      };
    } catch (e) {
      Logger.e('Failed to mark parcel post as unavailable', 'PARCELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a listing
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting parcel post: $postId');

      final response = await ApiClient.delete(
        '/parcels/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Listing deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete parcel post', 'PARCELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete listing',
      };
    } catch (e) {
      Logger.e('Failed to delete parcel post', 'PARCELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a listing
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting parcel post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/parcels/$postId/report',
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
      Logger.e('Failed to report parcel post', 'PARCELS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report listing',
      };
    } catch (e) {
      Logger.e('Failed to report parcel post', 'PARCELS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
