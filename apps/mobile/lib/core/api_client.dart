
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/application/auth_provider.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000', 
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
      print('API_CLIENT: onError - status=${e.response?.statusCode}, path=${e.requestOptions.path}');
      
      if (e.response?.statusCode == 401) {
        final path = e.requestOptions.path;
        print('API_CLIENT: 401 error on path: $path');
        
        // Skip refresh attempt for auth endpoints
        if (path.contains('/auth/')) {
          print('API_CLIENT: Skipping refresh for auth endpoint');
          return handler.next(e);
        }
        
        // Try to refresh the token
        final prefs = await SharedPreferences.getInstance();
        final refreshToken = prefs.getString('refresh_token');
        print('API_CLIENT: Has refresh token: ${refreshToken != null}');
        
        if (refreshToken != null) {
          try {
            print('API_CLIENT: Attempting token refresh...');
            // Use a clean Dio instance for refresh to avoid interceptor loop
            final refreshDio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
            final response = await refreshDio.post('/auth/refresh', data: {
              'refresh_token': refreshToken,
            });
            
            final newAccessToken = response.data['access_token'];
            await prefs.setString('auth_token', newAccessToken);
            print('API_CLIENT: Token refresh SUCCESS, retrying original request');
            
            // Retry the original request with new token
            final opts = e.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final retryResponse = await dio.fetch(opts);
            return handler.resolve(retryResponse);
          } catch (refreshError) {
            // Refresh failed - clear tokens and logout
            print('API_CLIENT: Token refresh FAILED: $refreshError');
            await prefs.remove('auth_token');
            await prefs.remove('refresh_token');
            try {
              await ref.read(authProvider.notifier).logout();
            } catch (_) {}
          }
        } else {
          // No refresh token - logout
          print('API_CLIENT: No refresh token available, logging out');
          await prefs.remove('auth_token');
          try {
            await ref.read(authProvider.notifier).logout();
          } catch (_) {}
        }
      }
      return handler.next(e);
    },
  ));
  
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));
  
  return dio;
}

