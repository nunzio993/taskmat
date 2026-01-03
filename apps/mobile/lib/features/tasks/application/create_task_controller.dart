
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
    Map<String, dynamic>? addressData,
  }) async {
    final dio = ref.read(apiClientProvider);
    final session = ref.read(authProvider).value;
    
    if (session == null || session.role != 'client') {
      throw Exception('Only logged-in clients can create tasks');
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'price_cents': priceCents,
        'urgency': urgency,
        'client_id': session.id,
        'lat': lat,
        'lon': lon,
      };
      
      // Add address fields if provided
      if (addressData != null) {
        if (addressData['street']?.isNotEmpty == true) data['street'] = addressData['street'];
        if (addressData['street_number']?.isNotEmpty == true) data['street_number'] = addressData['street_number'];
        if (addressData['city']?.isNotEmpty == true) data['city'] = addressData['city'];
        if (addressData['postal_code']?.isNotEmpty == true) data['postal_code'] = addressData['postal_code'];
        if (addressData['province']?.isNotEmpty == true) data['province'] = addressData['province'];
        if (addressData['address_extra']?.isNotEmpty == true) data['address_extra'] = addressData['address_extra'];
        if (addressData['place_id']?.isNotEmpty == true) data['place_id'] = addressData['place_id'];
        if (addressData['formatted_address']?.isNotEmpty == true) data['formatted_address'] = addressData['formatted_address'];
        if (addressData['access_notes']?.isNotEmpty == true) data['access_notes'] = addressData['access_notes'];
      }
      
      await dio.post('/tasks/', data: data);
      ref.invalidate(nearbyTasksProvider);
    });

    return !state.hasError;
  }
}
