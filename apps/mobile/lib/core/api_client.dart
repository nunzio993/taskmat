
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/application/auth_provider.dart';

part 'api_client.g.dart';

@riverpod
Dio apiClient(Ref ref) {
  // Use 10.0.2.2 for Android Emulator to access host localhost
  // Use localhost for Web/iOS Simulator
  // We can add platform detection later. For Web default (localhost) works.
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000', 
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      // Lazy load prefs to avoid async provider issues if possible, 
      // or just accept the tiny delay.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
        print('🔐 Auth Header added to ${options.method} ${options.path}');
      } else {
        print('⚠️ No Auth Token found for ${options.method} ${options.path}');
      }
    return handler.next(options);
    },
    onError: (DioException e, handler) async {
      print('API Error: ${e.message} ${e.response?.statusCode}');
      if (e.response?.statusCode == 401) {
        // Only logout on 401 if it's NOT the /profile/me endpoint
        // (profile/me 401 is handled separately in auth_provider build())
        final path = e.requestOptions.path;
        if (!path.contains('/profile/me') && !path.contains('/auth/')) {
          try {
            await ref.read(authProvider.notifier).logout();
          } catch (err) {
            print('Error during auto-logout: $err');
          }
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
