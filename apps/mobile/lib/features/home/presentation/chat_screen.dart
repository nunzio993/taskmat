import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/application/task_service.dart';
import 'package:mobile/features/home/domain/task.dart';
import 'package:mobile/features/chat/application/chat_providers.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:mobile/features/auth/application/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int taskId;
  final int helperId;
  final String title;

  const ChatScreen({
    super.key,
    required this.taskId,
    required this.helperId,
    required this.title,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  late Future<int> _threadIdFuture;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _threadIdFuture = _resolveThreadId();
  }

  Future<int> _resolveThreadId() async {
    // We need the thread ID for the messages provider.
    // If we are coming from the list, we might have it, but for now we look it up via task+helper.
    // The backend endpoint POST /tasks/{id}/thread gets or creates one for the CURRENT user.
    // But here we are the Client, and we want to chat with specific helperId.
    // We should use 'getTaskThreads' and find the one matching helperId.
    
    final threads = await ref.read(taskThreadsProvider(widget.taskId).future);
    final thread = threads.firstWhere(
      (t) => t.helperId == widget.helperId, 
      orElse: () => throw Exception('Chat thread not found for this helper.')
    );
    return thread.id;
  }

  Future<void> _sendMessage(int threadId) async {
    if (_messageController.text.trim().isEmpty) return;
    
    final body = _messageController.text;
    _messageController.clear();

    try {
      await ref.read(chatControllerProvider.notifier).sendMessage(threadId, body);
      // Provider auto-updates via polling, but we can also trigger manual refresh if needed
      ref.invalidate(threadMessagesProvider(threadId));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull?.user;
    final currentUserId = user?.id;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<int>(
        future: _threadIdFuture,
        builder: (context, idSnapshot) {
          if (idSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (idSnapshot.hasError) {
            return Center(child: Text('Error resolving chat: ${idSnapshot.error}'));
          }
          
          final threadId = idSnapshot.data!;
          // Use the AUTO-REFRESHING provider
          final messagesAsync = ref.watch(threadMessagesProvider(threadId));

          return Column(
            children: [
              Expanded(
                child: messagesAsync.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const Center(child: Text('No messages yet.'));
                    }

                    // Auto scroll to bottom
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_scrollController.hasClients) {
                        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = currentUserId != null && msg.senderId == currentUserId;
                        
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(msg.body),
                                const SizedBox(height: 4),
                                Text(
                                  timeago.format(msg.createdAt, locale: 'en_short'),
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(threadId),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(threadId),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
