import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';
import '../storage/secure_storage.dart';
import '../config/env_config.dart';

class ApiClient {
  static late Dio _dio;

  static void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.baseUrl + '/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ));
    }
  }

  static Dio get dio => _dio;

  static Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool includeAuth = true,
  }) async {
    if (includeAuth) {
      await _addAuthToken();
    }
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool includeAuth = true,
  }) async {
    if (includeAuth) {
      await _addAuthToken();
    }
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool includeAuth = true,
  }) async {
    if (includeAuth) {
      await _addAuthToken();
    }
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool includeAuth = true,
  }) async {
    if (includeAuth) {
      await _addAuthToken();
    }
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  static Future<Response> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    ProgressCallback? onSendProgress,
  }) async {
    FormData formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      ...?data,
    });

    return await _dio.post(
      path,
      data: formData,
      onSendProgress: onSendProgress,
    );
  }

  static Future<void> _addAuthToken() async {
    try {
      await LocalStorage.init();
      final token = await SecureStorage.getAuthToken();
      if (token != null && token.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $token';
        if (kDebugMode) {
          print('ApiClient: Adding auth token - Bearer ${token.substring(0, 20)}...');
          print('ApiClient: Headers after adding token: ${_dio.options.headers}');
        }
      } else {
        if (kDebugMode) {
          print('ApiClient: No auth token found in storage');
          print('ApiClient: Current headers: ${_dio.options.headers}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ApiClient: Error getting auth token: $e');
        print('ApiClient: Stack trace: ${StackTrace.current}');
      }
    }
  }
}
