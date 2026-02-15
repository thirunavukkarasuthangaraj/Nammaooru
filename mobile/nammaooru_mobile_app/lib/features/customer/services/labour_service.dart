import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class LabourService {
  final ApiService _apiService = ApiService();

  /// Get approved labour posts (public feed)
  Future<Map<String, dynamic>> getApprovedPosts({
    int page = 0,
    int size = 20,
    String? category,
  }) async {
    try {
      Logger.api('Fetching labour posts - page: $page, size: $size, category: $category');

      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final response = await _apiService.get(
        '/labours',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch labour posts', 'LABOURS', e);
      rethrow;
    }
  }

  /// Get my posts (user's own labour listings)
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      Logger.api('Fetching my labour posts');

      final response = await _apiService.get(
        '/labours/my',
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch my labour posts', 'LABOURS', e);
      rethrow;
    }
  }

  /// Create a new labour post with optional images (up to 3)
  Future<Map<String, dynamic>> createPost({
    required String name,
    required String phone,
    required String category,
    String? experience,
    String? location,
    String? description,
    List<String>? imagePaths,
  }) async {
    try {
      Logger.api('Creating labour post: $name ($category)');

      final formMap = <String, dynamic>{
        'name': name,
        'phone': phone,
        'category': category,
      };

      if (experience != null && experience.isNotEmpty) {
        formMap['experience'] = experience;
      }
      if (location != null && location.isNotEmpty) {
        formMap['location'] = location;
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
        '/labours',
        data: formData,
        options: Options(headers: headers),
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Labour listing submitted successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create labour post', 'LABOURS', e);
      final errorMessage = e.response?.data?['message'] ??
                          e.response?.data?['error'] ??
                          'Failed to create listing. Please try again.';
      return {
        'success': false,
        'message': errorMessage,
      };
    } catch (e) {
      Logger.e('Failed to create labour post', 'LABOURS', e);
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
      Logger.e('Failed to get auth token', 'LABOURS', e);
      return null;
    }
  }

  /// Mark a listing as unavailable
  Future<Map<String, dynamic>> markAsUnavailable(int postId) async {
    try {
      Logger.api('Marking labour post as unavailable: $postId');

      final response = await ApiClient.put(
        '/labours/$postId/unavailable',
      );

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Listing marked as unavailable',
      };
    } on DioException catch (e) {
      Logger.e('Failed to mark labour post as unavailable', 'LABOURS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to mark as unavailable',
      };
    } catch (e) {
      Logger.e('Failed to mark labour post as unavailable', 'LABOURS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Delete a listing
  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      Logger.api('Deleting labour post: $postId');

      final response = await ApiClient.delete(
        '/labours/$postId',
      );

      return {
        'success': true,
        'message': response.data?['message'] ?? 'Listing deleted',
      };
    } on DioException catch (e) {
      Logger.e('Failed to delete labour post', 'LABOURS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to delete listing',
      };
    } catch (e) {
      Logger.e('Failed to delete labour post', 'LABOURS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }

  /// Report a listing
  Future<Map<String, dynamic>> reportPost(int postId, String reason, {String? details}) async {
    try {
      Logger.api('Reporting labour post: $postId, reason: $reason');

      final response = await ApiClient.post(
        '/labours/$postId/report',
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
      Logger.e('Failed to report labour post', 'LABOURS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to report listing',
      };
    } catch (e) {
      Logger.e('Failed to report labour post', 'LABOURS', e);
      return {
        'success': false,
        'message': 'An unexpected error occurred: $e',
      };
    }
  }
}
