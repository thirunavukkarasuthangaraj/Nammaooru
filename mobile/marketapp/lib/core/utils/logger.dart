import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

class Logger {
  static const String _tag = 'NammaOoru';

  // Debug log
  static void d(String message, [String? tag]) {
    if (EnvConfig.enableLogging && kDebugMode) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 500, // DEBUG level
      );
    }
  }

  // Info log
  static void i(String message, [String? tag]) {
    if (EnvConfig.enableLogging) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 800, // INFO level
      );
    }
  }

  // Warning log
  static void w(String message, [String? tag]) {
    if (EnvConfig.enableLogging) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 900, // WARNING level
      );
    }
  }

  // Error log
  static void e(String message, [String? tag, Object? error, StackTrace? stackTrace]) {
    if (EnvConfig.enableLogging) {
      developer.log(
        message,
        name: tag ?? _tag,
        level: 1000, // ERROR level
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // Network log
  static void network(String method, String url, int statusCode, [String? response]) {
    if (EnvConfig.enableNetworkLogging && kDebugMode) {
      d('$method $url -> $statusCode${response != null ? '\nResponse: $response' : ''}', 'NETWORK');
    }
  }

  // API log
  static void api(String message) {
    d(message, 'API');
  }

  // Auth log
  static void auth(String message) {
    d(message, 'AUTH');
  }

  // Cart log
  static void cart(String message) {
    d(message, 'CART');
  }

  // Order log
  static void order(String message) {
    d(message, 'ORDER');
  }

  // Location log
  static void location(String message) {
    d(message, 'LOCATION');
  }
}