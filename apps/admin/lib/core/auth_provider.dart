import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client.dart';

// ============================================
// AUTH STATE
// ============================================

class AdminUser {
  final int id;
  final String email;
  final String? name;
  final bool isAdmin;
  final String? adminRole;
  
  AdminUser({
    required this.id,
    required this.email,
    this.name,
    required this.isAdmin,
    this.adminRole,
  });
  
  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      isAdmin: json['is_admin'] ?? false,
      adminRole: json['admin_role'],
    );
  }
  
  bool get isSuperAdmin => adminRole == 'SUPER_ADMIN';
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<AdminUser?>>((ref) {
  return AuthStateNotifier(ref);
});

class AuthStateNotifier extends StateNotifier<AsyncValue<AdminUser?>> {
  final Ref ref;
  
  AuthStateNotifier(this.ref) : super(const AsyncValue.loading()) {
    _checkAuth();
  }
  
  Future<void> _checkAuth() async {
    final token = ref.read(tokenProvider);
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }
    
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/admin/me');
      state = AsyncValue.data(AdminUser.fromJson(response.data));
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }
  
  Future<bool> login(String email, String password) async {
    state = const AsyncValue.loading();
    
    try {
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        headers: {'Content-Type': 'application/json'},
      ));
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final token = response.data['access_token'];
      await ref.read(tokenProvider.notifier).setToken(token);
      
      // Fetch admin info
      final dioAuth = ref.read(dioProvider);
      final meResponse = await dioAuth.get('/admin/me');
      final user = AdminUser.fromJson(meResponse.data);
      
      if (!user.isAdmin) {
        await ref.read(tokenProvider.notifier).clearToken();
        state = AsyncValue.error('Non sei un amministratore', StackTrace.current);
        return false;
      }
      
      state = AsyncValue.data(user);
      return true;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Errore di login';
      state = AsyncValue.error(message, StackTrace.current);
      return false;
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
      return false;
    }
  }
  
  Future<void> logout() async {
    await ref.read(tokenProvider.notifier).clearToken();
    state = const AsyncValue.data(null);
  }
}

final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull != null;
});
