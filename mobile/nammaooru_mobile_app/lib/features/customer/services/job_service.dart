import 'package:dio/dio.dart';
import '../../../core/services/api_service.dart';
import '../../../core/api/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/storage/secure_storage.dart';

class JobService {
  final ApiService _apiService = ApiService();

  /// Get approved job postings (public feed)
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
      Logger.api('Fetching job posts - page: $page, category: $category');

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
        '/jobs',
        queryParams: queryParams,
        includeAuth: true,
      );

      return response;
    } catch (e) {
      Logger.e('Failed to fetch job posts', 'JOBS', e);
      rethrow;
    }
  }

  /// Get my posted jobs
  Future<Map<String, dynamic>> getMyPosts() async {
    try {
      final response = await _apiService.get('/jobs/my', includeAuth: true);
      return response;
    } catch (e) {
      Logger.e('Failed to fetch my job posts', 'JOBS', e);
      rethrow;
    }
  }

  /// Create a new job posting
  Future<Map<String, dynamic>> createPost({
    required String companyName,
    required String phone,
    required String jobTitle,
    required String category,
    String? salary,
    String? salaryType,
    String? location,
    String? description,
    String? requirements,
    String? jobType,
    int? vacancies,
    List<String>? imagePaths,
    double? latitude,
    double? longitude,
  }) async {
    try {
      Logger.api('Creating job post: $jobTitle ($category)');

      final formMap = <String, dynamic>{
        'companyName': companyName,
        'phone': phone,
        'jobTitle': jobTitle,
        'category': category,
      };

      if (salary != null && salary.isNotEmpty) formMap['salary'] = salary;
      if (salaryType != null) formMap['salaryType'] = salaryType;
      if (location != null && location.isNotEmpty) formMap['location'] = location;
      if (description != null && description.isNotEmpty) formMap['description'] = description;
      if (requirements != null && requirements.isNotEmpty) formMap['requirements'] = requirements;
      if (jobType != null) formMap['jobType'] = jobType;
      if (vacancies != null) formMap['vacancies'] = vacancies.toString();
      if (latitude != null) formMap['latitude'] = latitude.toString();
      if (longitude != null) formMap['longitude'] = longitude.toString();

      if (imagePaths != null && imagePaths.isNotEmpty) {
        final List<MultipartFile> imageFiles = [];
        for (final path in imagePaths) {
          if (path.isNotEmpty) {
            final fileName = path.split('/').last;
            imageFiles.add(await MultipartFile.fromFile(
              path,
              filename: fileName.isNotEmpty ? fileName : 'image.jpg',
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
      final token = await _getAuthToken();
      final headers = <String, dynamic>{'Accept': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await ApiClient.dio.post(
        '/jobs',
        data: formData,
        options: Options(headers: headers),
      );

      final responseCode = response.data?['statusCode']?.toString() ?? '';
      if (responseCode.isNotEmpty && responseCode != '0000') {
        return {
          'success': false,
          'message': response.data?['message'] ?? 'Failed to post job',
          'statusCode': responseCode,
        };
      }

      return {
        'success': true,
        'data': response.data?['data'],
        'message': response.data?['message'] ?? 'Job posted successfully',
      };
    } on DioException catch (e) {
      Logger.e('Failed to create job post', 'JOBS', e);
      return {
        'success': false,
        'message': e.response?.data?['message'] ?? 'Failed to post job. Please try again.',
      };
    } catch (e) {
      Logger.e('Failed to create job post', 'JOBS', e);
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<Map<String, dynamic>> deletePost(int postId) async {
    try {
      final response = await ApiClient.delete('/jobs/$postId');
      return {'success': true, 'message': response.data?['message'] ?? 'Job deleted'};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data?['message'] ?? 'Failed to delete'};
    } catch (e) {
      return {'success': false, 'message': 'Unexpected error: $e'};
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      return await SecureStorage.getAuthToken();
    } catch (_) {
      return null;
    }
  }
}
