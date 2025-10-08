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
      _dio.interceptors.add(_CustomLogInterceptor());
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

class _CustomLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('\n');
    print('╔════════════════════════════════════════════════════════════════════════');
    print('║ 🚀 API REQUEST');
    print('╠════════════════════════════════════════════════════════════════════════');
    print('║ Method: ${options.method}');
    print('║ URL: ${options.baseUrl}${options.path}');
    if (options.queryParameters.isNotEmpty) {
      print('║ Query Parameters: ${options.queryParameters}');
    }
    print('║ Headers:');
    options.headers.forEach((key, value) {
      if (key.toLowerCase() == 'authorization' && value.toString().startsWith('Bearer ')) {
        print('║   $key: Bearer ${value.toString().substring(7, 27)}...');
      } else {
        print('║   $key: $value');
      }
    });
    if (options.data != null) {
      print('║ Request Body:');
      print('║ ${options.data}');
    }
    print('╚════════════════════════════════════════════════════════════════════════');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('\n');
    print('╔════════════════════════════════════════════════════════════════════════');
    print('║ ✅ API RESPONSE');
    print('╠════════════════════════════════════════════════════════════════════════');
    print('║ Status Code: ${response.statusCode}');
    print('║ URL: ${response.requestOptions.baseUrl}${response.requestOptions.path}');
    print('║ Response Data:');
    print('║ ${response.data}');
    print('╚════════════════════════════════════════════════════════════════════════');
    print('\n');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('\n');
    print('╔════════════════════════════════════════════════════════════════════════');
    print('║ ❌ API ERROR');
    print('╠════════════════════════════════════════════════════════════════════════');
    print('║ Error Type: ${err.type}');
    print('║ URL: ${err.requestOptions.baseUrl}${err.requestOptions.path}');
    print('║ Method: ${err.requestOptions.method}');
    if (err.response != null) {
      print('║ Status Code: ${err.response?.statusCode}');
      print('║ Error Response:');
      print('║ ${err.response?.data}');
    } else {
      print('║ Error Message: ${err.message}');
    }
    print('╚════════════════════════════════════════════════════════════════════════');
    print('\n');
    super.onError(err, handler);
  }
}
