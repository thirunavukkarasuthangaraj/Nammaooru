import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getAuthToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await SecureStorage.getRefreshToken();
      if (refreshToken != null) {
        try {
          final response = await Dio().post(
            '${ApiEndpoints.baseUrl}${ApiEndpoints.refreshToken}',
            data: {'refreshToken': refreshToken},
          );
          
          final newToken = response.data['accessToken'];
          await SecureStorage.saveAuthToken(newToken);
          
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          
          final cloneReq = await Dio().fetch(opts);
          handler.resolve(cloneReq);
          return;
        } catch (e) {
          await SecureStorage.clearAuthData();
        }
      }
    }
    handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    print('Headers: ${options.headers}');
    print('Data: ${options.data}');
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
    print('Data: ${response.data}');
    handler.next(response);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
    print('Message: ${err.message}');
    handler.next(err);
  }
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    String errorMessage = 'Something went wrong';
    
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please try again.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode != null) {
          switch (statusCode) {
            case 400:
              errorMessage = 'Bad request. Please check your input.';
              break;
            case 401:
              errorMessage = 'Unauthorized. Please login again.';
              break;
            case 403:
              errorMessage = 'Forbidden. You don\'t have permission.';
              break;
            case 404:
              errorMessage = 'Resource not found.';
              break;
            case 500:
              errorMessage = 'Internal server error. Please try again later.';
              break;
            default:
              errorMessage = 'Server error (${statusCode}). Please try again.';
          }
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request was cancelled.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'No internet connection. Please check your network.';
        break;
      case DioExceptionType.unknown:
        errorMessage = 'Unknown error occurred. Please try again.';
        break;
      case DioExceptionType.badCertificate:
        errorMessage = 'Certificate error. Please try again.';
        break;
    }
    
    final customError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage,
    );
    
    handler.next(customError);
  }
}