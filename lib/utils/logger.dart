// lib/utils/logger.dart
import 'package:dio/dio.dart';

class AppLogger {
  static void log(String message) {
    print('ℹ️  $message');
  }

  static void error(String message) {
    print('❌ ERROR: $message');
  }

  static void logRequest(RequestOptions options) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🚀 REQUEST: ${options.method} ${options.path}');
    print('📦 HEADERS: ${options.headers}');
    if (options.data != null) {
      print('📝 BODY: ${options.data}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static void logResponse(Response response) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('✅ RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
    print('📦 DATA: ${response.data}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static void logError(DioException error) {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('❌ ERROR: ${error.message}');
    if (error.response != null) {
      print('📦 RESPONSE: ${error.response?.data}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
