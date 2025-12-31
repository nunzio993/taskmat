
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../home/domain/task.dart'; // For TaskMessage if needed, or re-export
import '../domain/chat_models.dart';

// Service
class ChatService {
  final dynamic dio; // Dio instance

  ChatService(this.dio);

  Future<ChatThread> getOrCreateThread(int taskId) async {
    final response = await dio.post('/chat/tasks/$taskId/thread');
    return ChatThread.fromJson(response.data);
  }

  Future<List<ChatThread>> getTaskThreads(int taskId) async {
    final response = await dio.get('/chat/tasks/$taskId/threads');
    return (response.data as List).map((e) => ChatThread.fromJson(e)).toList();
  }

  Future<List<TaskMessage>> getMessages(int threadId) async {
    final response = await dio.get('/chat/threads/$threadId/messages');
    return (response.data as List).map((e) => TaskMessage.fromJson(e)).toList();
  }

  Future<TaskMessage> sendMessage(int threadId, String body) async {
    final response = await dio.post('/chat/threads/$threadId/messages', data: {
      'body': body,
      'type': 'text',
      'payload': {}
    });
    return TaskMessage.fromJson(response.data);
  }

  Future<ChatThread> getOrCreateThreadAsClient(int taskId, int helperId) async {
    final response = await dio.post('/chat/tasks/$taskId/thread', queryParameters: {
      'helper_id': helperId
    });
    return ChatThread.fromJson(response.data);
  }
}

final chatServiceProvider = Provider((ref) {
  final dio = ref.read(apiClientProvider);
  return ChatService(dio);
});

// Providers

// For Client: List of threads for a task
final taskThreadsProvider = FutureProvider.family<List<ChatThread>, int>((ref, taskId) async {
  final service = ref.watch(chatServiceProvider);
  return service.getTaskThreads(taskId);
});

// For Helper: Get specific thread for a task (Self <-> Client)
final myTaskThreadProvider = FutureProvider.family<ChatThread, int>((ref, taskId) async {
  final service = ref.watch(chatServiceProvider);
  return service.getOrCreateThread(taskId);
});

// Messages for a thread (Auto-refresh)
final threadMessagesProvider = FutureProvider.autoDispose.family<List<TaskMessage>, int>((ref, threadId) async {
  final service = ref.watch(chatServiceProvider);
  
  // Poll every 3 seconds for liveliness
  // In prod use WebSockets/SSE
  final timer = Stream.periodic(const Duration(seconds: 3)).listen((_) {
     ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  return service.getMessages(threadId);
});

// Controller for actions
class ChatController extends StateNotifier<AsyncValue<void>> {
  final ChatService _service;
  
  ChatController(this._service) : super(const AsyncValue.data(null));

  Future<void> sendMessage(int threadId, String body) async {
    state = const AsyncValue.loading();
    try {
      await _service.sendMessage(threadId, body);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, AsyncValue<void>>((ref) {
  return ChatController(ref.watch(chatServiceProvider));
});
