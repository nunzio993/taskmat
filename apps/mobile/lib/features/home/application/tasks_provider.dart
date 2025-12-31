
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
  if (session == null || session.role != 'client') return [];

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
