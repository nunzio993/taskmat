
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../auth/application/auth_provider.dart';
import '../../home/domain/task.dart';
import '../../home/application/tasks_provider.dart';

part 'task_controller.g.dart';

@riverpod
class TaskController extends _$TaskController {
  @override
  FutureOr<void> build() {}

  // Alias to refresh global tasks list
  void fetchTasks() {
    ref.invalidate(nearbyTasksProvider);
  }

  Future<void> lockTask(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    if (session == null) throw Exception('User not logged in');

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await dio.post('/tasks/$taskId/lock', queryParameters: {'helper_id': session.id});
      ref.invalidate(nearbyTasksProvider);
    });
  }

  Future<void> assignTask(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    if (session == null) return;
    
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await dio.post('/tasks/$taskId/assign', queryParameters: {'helper_id': session.id});
      ref.invalidate(nearbyTasksProvider);
    });
  }

  Future<void> startTask(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    if (session == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await dio.post('/tasks/$taskId/start', queryParameters: {'helper_id': session.id});
      ref.invalidate(nearbyTasksProvider);
    });
  }

  Future<void> completeRequest(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    if (session == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await dio.post('/tasks/$taskId/complete-request', queryParameters: {'helper_id': session.id});
       ref.invalidate(nearbyTasksProvider);
    });
  }

  Future<void> confirmCompletion(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    if (session == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await dio.post('/tasks/$taskId/confirm', queryParameters: {'client_id': session.id});
      ref.invalidate(nearbyTasksProvider);
    });
  }
}
