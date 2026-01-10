
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/websocket_service.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/task.dart';

part 'tasks_provider.g.dart';


/// Trigger for refreshing tasks based on WebSocket events
@riverpod
class TaskRefreshTrigger extends _$TaskRefreshTrigger {
  @override
  int build() {
    // Listen to WebSocket events
    ref.listen(webSocketEventsProvider, (previous, next) {
      next.whenData((event) {
        if (event.type == 'new_offer' || 
            event.type == 'task_status_changed' || 
            event.type == 'offer_accepted' || 
            event.type == 'offer_rejected' || 
            event.type == 'offer_status_changed') {
          // Increment state to trigger rebuild of dependents
          state++;
        }
      });
    });
    return 0;
  }
}

@riverpod
Future<List<Task>> nearbyTasks(Ref ref) async {
  // Watch refresh trigger for real-time updates
  ref.watch(taskRefreshTriggerProvider);

  // Watch auth to get helper's selected categories
  final session = ref.watch(authProvider).value;

  // Conservative fallback polling every 60 seconds
  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final dio = ref.read(apiClientProvider);
  // Default Rome location for MVP
  final response = await dio.get('/tasks/nearby', queryParameters: {
    'lat': 41.9028,
    'lon': 12.4964,
    'radius_km': 100.0 // Expanded for demo
  });
  
  var tasks = (response.data as List).map((json) => Task.fromJson(json)).toList();
  
  // Filter by helper's selected categories if the user is a helper with categories set
  if (session != null && session.role == 'helper' && session.categories.isNotEmpty) {
    tasks = tasks.where((task) => session.categories.contains(task.category)).toList();
  }
  
  return tasks;
}

@riverpod
Future<List<Task>> myCreatedTasks(Ref ref) async {
  // Watch auth to handle login/logout
  final session = ref.watch(authProvider).value;
  if (session == null) return [];
  
  // Watch the refresh trigger - this will cause this provider to rebuild whenever
  // the trigger increments (on WebSocket events)
  ref.watch(taskRefreshTriggerProvider);

  // Conservative fallback polling every 60 seconds
  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final dio = ref.read(apiClientProvider);

  final response = await dio.get('/tasks/created', queryParameters: {
    'client_id': session.id,
  });
  
  return (response.data as List).map((json) => Task.fromJson(json)).toList();
}

@riverpod
Future<List<Task>> myAssignedTasks(Ref ref) async {
  // Watch auth
  final session = ref.watch(authProvider).value;
  if (session == null || session.role != 'helper') return [];

  // Watch refresh trigger for real-time updates
  ref.watch(taskRefreshTriggerProvider);

  // Conservative fallback polling
  final timer = Timer(const Duration(seconds: 60), () => ref.invalidateSelf());
  ref.onDispose(() => timer.cancel());

  final dio = ref.read(apiClientProvider);

  final response = await dio.get('/tasks/assigned', queryParameters: {
    'helper_id': session.id,
  });
  
  return (response.data as List).map((json) => Task.fromJson(json)).toList();
}


/// Check if helper has any active job (for default Home routing)
@riverpod
Future<bool> hasActiveHelperJob(Ref ref) async {
  final session = ref.watch(authProvider).value;
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

/// Get the active helper job (first one) for display in the active job strip
@riverpod
Future<Task?> activeHelperJob(Ref ref) async {
  final session = ref.watch(authProvider).value;
  if (session == null || session.role != 'helper') return null;
  
  try {
    final tasks = await ref.watch(myAssignedTasksProvider.future);
    final activeJobs = tasks.where((t) => 
      ['assigned', 'in_progress', 'in_confirmation'].contains(t.status)
    ).toList();
    
    if (activeJobs.isEmpty) return null;
    return activeJobs.first;
  } catch (_) {
    return null;
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

// ============================================
// HELPER DASHBOARD PROVIDERS
// ============================================

/// Helper availability state (online/offline)
/// For now stored locally, in production would sync with backend
@riverpod
class HelperAvailability extends _$HelperAvailability {
  @override
  bool build() {
    // Default to available
    return true;
  }
  
  void setAvailable(bool available) {
    state = available;
    // TODO: In production, sync with backend
    // await ref.read(apiClientProvider).post('/helper/availability', data: {'available': available});
  }
  
  void toggle() {
    state = !state;
  }
}

/// Mock earnings data for helper dashboard
class HelperEarnings {
  final int todayCents;
  final int weekCents;
  final int pendingPayoutCents;
  final double rating;
  final int reviewCount;
  
  const HelperEarnings({
    required this.todayCents,
    required this.weekCents,
    required this.pendingPayoutCents,
    required this.rating,
    required this.reviewCount,
  });
}

@riverpod
Future<HelperEarnings> helperEarnings(Ref ref) async {
  final session = ref.watch(authProvider).value;
  if (session == null || session.role != 'helper') {
    return const HelperEarnings(
      todayCents: 0,
      weekCents: 0,
      pendingPayoutCents: 0,
      rating: 0,
      reviewCount: 0,
    );
  }
  
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/helper/stats');
    final data = response.data;
    
    return HelperEarnings(
      todayCents: data['today_cents'] ?? 0,
      weekCents: data['week_cents'] ?? 0,
      pendingPayoutCents: data['pending_payout_cents'] ?? 0,
      rating: (data['rating'] ?? 0).toDouble(),
      reviewCount: data['review_count'] ?? 0,
    );
  } catch (e) {
    // Return zeros on error
    return const HelperEarnings(
      todayCents: 0,
      weekCents: 0,
      pendingPayoutCents: 0,
      rating: 0,
      reviewCount: 0,
    );
  }
}

/// Recent chat threads for inbox preview
class RecentThread {
  final int threadId;
  final int taskId;
  final String taskTitle;
  final String taskStatus;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final bool hasUnread;
  
  const RecentThread({
    required this.threadId,
    required this.taskId,
    required this.taskTitle,
    required this.taskStatus,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.hasUnread,
  });
}

@riverpod
Future<List<RecentThread>> helperRecentThreads(Ref ref) async {
  final session = ref.watch(authProvider).value;
  if (session == null || session.role != 'helper') return [];
  
  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/helper/my-threads');
    final List<dynamic> data = response.data;
    
    return data.map((json) => RecentThread(
      threadId: json['thread_id'],
      taskId: json['task_id'],
      taskTitle: json['task_title'] ?? 'Task',
      taskStatus: json['task_status'] ?? 'posted',
      otherUserName: json['other_user_name'] ?? 'Cliente',
      otherUserAvatar: json['other_user_avatar'],
      lastMessage: json['last_message'] ?? 'Nessun messaggio',
      lastMessageAt: DateTime.parse(json['last_message_at']),
      hasUnread: json['has_unread'] ?? false,
    )).toList();
  } catch (e) {
    return [];
  }
}

/// Check if helper has critical alerts (e.g., Stripe not configured)
@riverpod
Future<List<String>> helperAlerts(Ref ref) async {
  final session = ref.watch(authProvider).value;
  if (session == null || session.role != 'helper') return [];
  
  // TODO: In production, check actual status
  // For now, return mock alerts
  final List<String> alerts = [];
  
  // Example alert (remove in production when Stripe is configured)
  // alerts.add('Configura Stripe Connect per ricevere pagamenti');
  
  return alerts;
}
