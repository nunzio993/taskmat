import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/application/task_service.dart';
import 'package:mobile/features/home/domain/task.dart';
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
  late Future<int> _helperIdFuture;
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _helperIdFuture = _resolveHelperId();
  }

  Future<int> _resolveHelperId() async {
    if (widget.helperId != 0) return widget.helperId;
    
    // If helperId is 0, we are Client and need to find the accepted offer/helper
    final offers = await ref.read(taskServiceProvider.notifier).getOffers(widget.taskId);
    // Find accepted offer. Backend might call it 'accepted' or we infer from task status?
    // Let's look for any offer that is NOT pending/rejected if we can't find explicit 'accepted'.
    // Actually, when we select an offer, its status becomes 'accepted'.
    try {
      final acceptedOffer = offers.firstWhere((o) => o.status == 'accepted');
      return acceptedOffer.helperId;
    } catch (e) {
      // Fallback or error
      throw Exception('No accepted offer found for this task.');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final body = _messageController.text;
    _messageController.clear();

    try {
      final helperId = await _helperIdFuture;
      await ref.read(taskServiceProvider.notifier).sendMessage(
        widget.taskId,
        helperId,
        body,
      );
      setState(() {}); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error sending: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<int>(
        future: _helperIdFuture,
        builder: (context, idSnapshot) {
          if (idSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (idSnapshot.hasError) {
             return Center(child: Text('Error resolving chat: ${idSnapshot.error}'));
          }
          
          final resolvedHelperId = idSnapshot.data!;
          final messagesFuture = ref.watch(taskServiceProvider.notifier).getMessages(widget.taskId, resolvedHelperId);
          final user = ref.watch(authProvider).valueOrNull?.user;
          final currentUserId = user?.id;

          return Column(
            children: [
              Expanded(
                child: FutureBuilder<List<TaskMessage>>(
                  future: messagesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final messages = snapshot.data ?? [];
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
                            Text(
                              timeago.format(msg.createdAt),
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
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
