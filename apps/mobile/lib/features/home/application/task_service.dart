import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../domain/task.dart';

import 'package:dio/dio.dart'; // For FormData, MultipartFile
import 'package:image_picker/image_picker.dart'; // For XFile

part 'task_service.g.dart';

@riverpod
class TaskService extends _$TaskService {
  @override
  FutureOr<void> build() {}

  // --- TASKS ---
  
  Future<Task> updateTask(int taskId, Map<String, dynamic> data) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.patch('/tasks/$taskId', data: data);
    return Task.fromJson(response.data);
  }

  // --- OFFERS ---
  
  Future<List<TaskOffer>> getOffers(int taskId) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/tasks/$taskId/offers');
    return (response.data as List).map((e) => TaskOffer.fromJson(e)).toList();
  }

  Future<TaskOffer> createOffer(int taskId, int priceCents, String message) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.post('/tasks/$taskId/offers', data: {
      'price_cents': priceCents,
      'message': message,
      // Status is handled by backend
    });
    return TaskOffer.fromJson(response.data);
  }

  Future<void> selectOffer(int taskId, int offerId) async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/tasks/$taskId/offers/$offerId/select');
  }

  Future<void> declineOffer(int taskId, int offerId) async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/tasks/$taskId/offers/$offerId/reject');
  }

  // --- CHAT ---

  Future<List<TaskMessage>> getMessages(int taskId, int helperId) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get('/tasks/$taskId/threads/$helperId/messages');
    return (response.data as List).map((e) => TaskMessage.fromJson(e)).toList();
  }

  Future<TaskMessage> sendMessage(int taskId, int helperId, String body) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.post('/tasks/$taskId/threads/$helperId/messages', data: {
      'body': body,
      'type': 'text',
    });
    return TaskMessage.fromJson(response.data);
  }

  Future<void> uploadProof(int taskId, XFile file) async {
    final dio = ref.read(apiClientProvider);
    
    // For Web robustness, use bytes
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    
    await dio.post('/tasks/$taskId/proofs/upload', data: formData);
  }

  // --- LIFECYCLE ---

  Future<void> startTask(int taskId) async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/tasks/$taskId/start');
  }

  Future<void> requestCompletion(int taskId) async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/tasks/$taskId/complete-request');
  }

  Future<void> confirmCompletion(int taskId) async {
    final dio = ref.read(apiClientProvider);
    await dio.post('/tasks/$taskId/confirm');
  }
}
