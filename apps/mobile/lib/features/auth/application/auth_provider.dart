
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api_client.dart';

part 'auth_provider.g.dart';


class UserSession {
  final int id;
  final String role; // 'client' or 'helper'
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final double? hourlyRate;
  
  // Advanced Preferences
  final bool isAvailable;
  final Map<String, bool> readiness; // e.g. {'stripe': true, 'profile': true}
  final double matchingRadius;
  final List<String> categories;
  final List<String> languages; // Spoken languages
  final Set<String> urgencyFilters; // 'NOW', 'TODAY', 'SLOT'
  final double minPrice;
  final Map<String, bool> notifications;

  const UserSession({
    required this.id, 
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.hourlyRate,
    this.isAvailable = false,
    this.readiness = const {'stripe': true, 'profile': true, 'categories': false},
    this.matchingRadius = 15.0,
    this.categories = const [],
    this.languages = const ['Italiano'],
    this.urgencyFilters = const {'NOW', 'TODAY', 'SLOT'},
    this.minPrice = 0.0,
    this.notifications = const {'match': true, 'chat': true, 'updates': true},
  });

  // Self-reference getter to fix access patterns like `session.user.id` 
  UserSession get user => this;

  UserSession copyWith({
    String? name, 
    String? email,
    String? phone,
    String? bio,
    double? hourlyRate,
    bool? isAvailable,
    Map<String, bool>? readiness,
    double? matchingRadius,
    List<String>? categories,
    List<String>? languages,
    Set<String>? urgencyFilters,
    double? minPrice,
    Map<String, bool>? notifications,
  }) {
    return UserSession(
      id: id,
      role: role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      isAvailable: isAvailable ?? this.isAvailable,
      readiness: readiness ?? this.readiness,
      matchingRadius: matchingRadius ?? this.matchingRadius,
      categories: categories ?? this.categories,
      languages: languages ?? this.languages,
      urgencyFilters: urgencyFilters ?? this.urgencyFilters,
      minPrice: minPrice ?? this.minPrice,
      notifications: notifications ?? this.notifications,
    );
  }
}

@riverpod
class Auth extends _$Auth {
  @override
  FutureOr<UserSession?> build() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) return null;

    try {
      final dio = ref.read(apiClientProvider);
      // Token is attached by interceptor automatically if present in prefs
      final response = await dio.get('/profile/me');
      
      final user = _parseUser(response.data);
      return user;
    } on DioException catch (e) {
      // Only clear token on 401 Unauthorized
      if (e.response?.statusCode == 401) {
        await prefs.remove('auth_token');
        return null;
      }
      // For network errors, keep the token and rethrow
      // This prevents logout on temporary network issues
      rethrow;
    } catch (e) {
      // Unknown error, don't clear token
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final data = response.data;
      final token = data['access_token'];
      final userMap = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      
      // Parse User
      final user = _parseUser(userMap);
      await _persistUser(user);

      state = AsyncData(user);
    } catch (e) {
      // On error, we reset to null (not logged in) instead of keeping error state
      // This prevents the router/UI from getting stuck in an error view
      state = const AsyncData(null);
      rethrow;
    }
  }

  Future<void> register(String email, String password, String role, String firstName, String lastName) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider);
      await dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'role': role,
        'first_name': firstName,
        'last_name': lastName,
      });
      
      // Auto-login after register
      await login(email, password); 
    } catch (e) {
       state = const AsyncData(null);
       rethrow;
    }
  }

  Future<void> updateProfile({
    String? name, String? email, String? phone, String? bio, double? hourlyRate,
    bool? isAvailable, double? matchingRadius, List<String>? categories,
    List<String>? languages, double? minPrice, Set<String>? urgencyFilters, 
    Map<String, bool>? notifications,
  }) async {
    final current = state.value;
    if (current == null) return;
    
    // Optimistic Update
    // ... (Optional, skip for now to simplify)

    try {
      final dio = ref.read(apiClientProvider);
      final updateData = <String, dynamic>{};
      
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (bio != null) updateData['bio'] = bio;
      if (hourlyRate != null) updateData['hourly_rate'] = hourlyRate;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (languages != null) updateData['languages'] = languages;
      
      final prefs = <String, dynamic>{};
      if (matchingRadius != null) prefs['radius'] = matchingRadius;
      if (categories != null) prefs['categories'] = categories;
      if (minPrice != null) prefs['min_price'] = minPrice;
      if (urgencyFilters != null) prefs['urgency'] = urgencyFilters.toList();
      if (notifications != null) prefs['notifications'] = notifications;
      
      if (prefs.isNotEmpty) updateData['preferences'] = prefs;
      
      // We don't have an endpoint for readiness update yet, it's usually calculated backend side 
      // or requires specific verification endpoints. For MVP, we ignore readiness updates from client directly 
      // except maybe if we had a specific "mark profile complete" implementation.
      
      final response = await dio.patch('/profile/me', data: updateData);
      final user = _parseUser(response.data);
      await _persistUser(user);
      
      state = AsyncData(user);
    } catch (e) {
      // Revert optimistic update if we did one
      state = AsyncData(current); // Reset to old
      // Show error?
    }
  }

  Future<void> becomeHelper() async {
    final currentUser = state.value;
    state = const AsyncLoading();
    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.post('/profile/become-helper');
      final user = _parseUser(response.data);
      await _persistUser(user);
      state = AsyncData(user);
    } catch (e, st) {
       // Revert to previous state so user isn't logged out
       if (currentUser != null) {
         state = AsyncData(currentUser);
       } else {
         state = AsyncError(e, st);
       }
       rethrow;
    }
  }

  // Helper to parse User from JSON
  UserSession _parseUser(Map<String, dynamic> data) {
    final prefs = data['preferences'] ?? {};
    final readiness = data['readiness_status'] ?? {};
    
    return UserSession(
      id: data['id'],
      role: data['role'],
      name: data['name'] ?? '',
      email: data['email'],
      phone: data['phone'],
      bio: data['bio'],
      hourlyRate: (data['hourly_rate'] as num?)?.toDouble(),
      isAvailable: data['is_available'] ?? false,
      readiness: Map<String, bool>.from(readiness),
      matchingRadius: (prefs['radius'] as num?)?.toDouble() ?? 15.0,
      categories: List<String>.from(prefs['categories'] ?? []),
      languages: List<String>.from(data['languages'] ?? ['Italiano']),
      minPrice: (prefs['min_price'] as num?)?.toDouble() ?? 0.0,
      urgencyFilters: Set<String>.from(prefs['urgency'] ?? []),
      notifications: Map<String, bool>.from(prefs['notifications'] ?? {}),
    );
  }
  
  Future<void> _persistUser(UserSession user) async {
      // For offline support, we could persist fields to SharedPreferences
      // But for this stage, we rely on Backend + Token re-fetch on boot
      // Or we can simple cache key fields if needed.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', user.id);
      await prefs.setString('user_role', user.role);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); 
    state = const AsyncData(null);
  }
}
