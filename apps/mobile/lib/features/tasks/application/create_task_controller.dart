
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../auth/application/auth_provider.dart';
import '../../home/application/tasks_provider.dart';

part 'create_task_controller.g.dart';

@riverpod
class CreateTaskController extends _$CreateTaskController {
  @override
  FutureOr<void> build() {}

  Future<bool> createTask({
    required String title,
    required String description,
    required String category,
    required int priceCents,
    required String urgency,
    required double lat,
    required double lon,
  }) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    
    if (session == null || session.role != 'client') {
      throw Exception('Only logged-in clients can create tasks');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await dio.post('/tasks/', data: {
        'title': title,
        'description': description,
        'category': category,
        'price_cents': priceCents,
        'urgency': urgency,
        'client_id': session.id,
        'lat': lat,
        'lon': lon,
      });
      // Refresh the nearby tasks list so the new task appears on the map when we return
      ref.invalidate(nearbyTasksProvider);
    });

    return !state.hasError;
  }
}
