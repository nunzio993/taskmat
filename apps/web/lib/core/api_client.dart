import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'api_client.g.dart';

/// Base URL for API - change this for different environments
const String apiBaseUrl = 'http://localhost:8000';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (e, handler) async {
      if (e.response?.statusCode == 401) {
        // Token expired - try refresh
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refresh_token');
        
        if (refreshToken != null) {
          try {
            final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
            final response = await refreshDio.post('/auth/refresh', data: {
              'refresh_token': refreshToken,
            });
            
            final newAccessToken = response.data['access_token'];
            await prefs.setString('auth_token', newAccessToken);
            
            // Retry original request
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          } catch (_) {
            // Refresh failed - clear tokens
            await prefs.remove('auth_token');
            await prefs.remove('refresh_token');
          }
        }
      }
      handler.next(e);
    },
  ));

  return dio;
}
