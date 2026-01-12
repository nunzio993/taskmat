
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/application/auth_provider.dart';

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
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        final path = e.requestOptions.path;
        
        // Skip refresh attempt for auth endpoints
        if (path.contains('/auth/')) {
          return handler.next(e);
        }
        
        // Try to refresh the token
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refresh_token');
        
        if (refreshToken != null) {
          try {
            // Use a clean Dio instance for refresh to avoid interceptor loop
            final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
            final response = await refreshDio.post('/auth/refresh', data: {
              'refresh_token': refreshToken,
            });
            
            final newAccessToken = response.data['access_token'];
            await prefs.setString('auth_token', newAccessToken);
            
            // Retry the original request with new token
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          } catch (refreshError) {
            // Refresh failed - clear tokens and logout
            await prefs.remove('auth_token');
            await prefs.remove('refresh_token');
            try {
              await ref.read(authProvider.notifier).logout();
            } catch (_) {}
          }
        } else {
          // No refresh token - logout
          await prefs.remove('auth_token');
          try {
            await ref.read(authProvider.notifier).logout();
          } catch (_) {}
        }
      }
      return handler.next(e);
    },
  ));
  
  // SEC-012: Verbose logging in debug mode
  // Note: Auth endpoints with passwords will still be logged, consider custom interceptor if needed
  if (kDebugMode) {
    dio.interceptors.add(LogInterceptor(
      requestBody: false,  // Don't log request body to avoid password exposure
      responseBody: true,
    ));
  }
  
  return dio;
}

