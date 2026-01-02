
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/task.dart';

part 'tasks_provider.g.dart';

@riverpod
Future<List<Task>> nearbyTasks(Ref ref) async {
  // Auto-refresh every 5 seconds
  final timer = Timer(const Duration(seconds: 5), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final dio = ref.read(apiClientProvider);
  // Default Rome location for MVP
  final response = await dio.get('/tasks/nearby', queryParameters: {
    'lat': 41.9028,
    'lon': 12.4964,
    'radius_km': 100.0 // Expanded for demo
  });
  
  return (response.data as List).map((json) => Task.fromJson(json)).toList();
}

@riverpod
Future<List<Task>> myCreatedTasks(Ref ref) async {
  // Auto-refresh every 5 seconds to catch new offers/messages
  final timer = Timer(const Duration(seconds: 5), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final dio = ref.read(apiClientProvider);
  final session = ref.read(authProvider).value;
  if (session == null) return [];

  final response = await dio.get('/tasks/created', queryParameters: {
    'client_id': session.id,
  });
  
  return (response.data as List).map((json) => Task.fromJson(json)).toList();
}

@riverpod
Future<List<Task>> myAssignedTasks(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  final session = ref.read(authProvider).value;
  if (session == null || session.role != 'helper') return [];

  final response = await dio.get('/tasks/assigned', queryParameters: {
    'helper_id': session.id,
  });
  
  return (response.data as List).map((json) => Task.fromJson(json)).toList();
}

/// Check if helper has any active job (for default Home routing)
@riverpod
Future<bool> hasActiveHelperJob(Ref ref) async {
  final session = ref.read(authProvider).value;
  if (session == null || session.role != 'helper') return false;
  
  try {
    final tasks = await ref.watch(myAssignedTasksProvider.future);
    return tasks.any((t) => 
      ['assigned', 'in_progress', 'in_confirmation'].contains(t.status)
    );
  } catch (_) {
    return false;
  }
}

/// Sanitized task for market preview (NO description, NO address, NO client identity)
class SanitizedTask {
  final String category;
  final int priceCents;
  final String urgency;
  final String distanceBand;
  final String postedAge;
  
  SanitizedTask({
    required this.category,
    required this.priceCents,
    required this.urgency,
    required this.distanceBand,
    required this.postedAge,
  });
}

/// Sanitized market preview for "Become Helper" section
/// Shows ONLY: category, price, urgency, distance_band, posted_age
/// Does NOT show: description, client identity, precise location, address
@riverpod
Future<List<SanitizedTask>> sanitizedMarketPreview(Ref ref) async {
  // Refresh every 60 seconds (not too frequent to avoid UI flickering)
  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());
  
  try {
    // Use read instead of watch to avoid triggering on every nearbyTasks update
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/tasks/nearby', queryParameters: {
      'lat': 41.9028,
      'lon': 12.4964,
      'radius_km': 100.0
    });
    final tasks = (response.data as List).map((json) => Task.fromJson(json)).toList();
    
    // Filter only POSTED tasks
    final postedTasks = tasks.where((t) => t.status == 'posted').toList();
    
    // Sanitize and return max 5
    return postedTasks.take(5).map((task) {
      // Calculate distance band (fake for now - in real app would use actual distance)
      String distanceBand = 'Vicino a te';
      // Randomize slightly for demo
      final distanceValue = (task.id % 3);
      if (distanceValue == 0) distanceBand = 'Vicino a te';
      else if (distanceValue == 1) distanceBand = '2-5 km';
      else distanceBand = 'Entro 10 km';
      
      // Calculate posted age
      final diff = DateTime.now().difference(task.createdAt);
      String postedAge;
      if (diff.inMinutes < 60) {
        postedAge = 'Adesso';
      } else if (diff.inHours < 24) {
        postedAge = '${diff.inHours}h fa';
      } else {
        postedAge = '${diff.inDays}g fa';
      }
      
      return SanitizedTask(
        category: task.category,
        priceCents: task.priceCents,
        urgency: task.urgency,
        distanceBand: distanceBand,
        postedAge: postedAge,
      );
    }).toList();
  } catch (_) {
    return [];
  }
}
