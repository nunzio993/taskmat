import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/tasks_provider.dart';

/// Inbox preview section showing recent message threads
class InboxPreviewSection extends ConsumerWidget {
  const InboxPreviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(helperRecentThreadsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inbox, color: Colors.teal.shade600, size: 22),
            const SizedBox(width: 8),
            Text('Messaggi', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/my-jobs'), child: Text('Vedi tutti', style: TextStyle(color: Colors.teal.shade600))),
          ],
        ),
        const SizedBox(height: 12),
        threadsAsync.when(
          data: (threads) {
            if (threads.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.inbox_outlined, color: Colors.grey.shade400), const SizedBox(width: 10), Text('Nessun messaggio', style: TextStyle(color: Colors.grey.shade500))]),
              );
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade100)),
              child: Column(children: threads.take(5).map((thread) => _buildThreadItem(context, thread)).toList()),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Errore caricamento messaggi'),
        ),
      ],
    );
  }
  
  Widget _buildThreadItem(BuildContext context, RecentThread thread) {
    final diff = DateTime.now().difference(thread.lastMessageAt);
    final timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes}m' : (diff.inHours < 24 ? '${diff.inHours}h' : '${diff.inDays}g');
    
    // Build full avatar URL if it's a relative path
    String? avatarUrl = thread.otherUserAvatar;
    if (avatarUrl != null && !avatarUrl.startsWith('http')) {
      avatarUrl = 'http://57.131.20.93/api$avatarUrl';
    }
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Route based on task status
          if (thread.taskStatus == 'posted') {
            context.go('/find-work?focusTaskId=${thread.taskId}');
          } else {
            // assigned, in_progress, in_confirmation, completed
            context.go('/my-jobs');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.teal.shade50))),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.teal.shade100,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null ? Text(thread.otherUserName.isNotEmpty ? thread.otherUserName[0] : '?', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Expanded(child: Text(thread.otherUserName, style: TextStyle(fontWeight: thread.hasUnread ? FontWeight.bold : FontWeight.w500, color: Colors.grey.shade800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)), Text(timeAgo, style: TextStyle(color: Colors.grey.shade500, fontSize: 11))]),
                    const SizedBox(height: 2),
                    Text(thread.lastMessage, style: TextStyle(color: thread.hasUnread ? Colors.grey.shade800 : Colors.grey.shade500, fontSize: 13, fontWeight: thread.hasUnread ? FontWeight.w500 : FontWeight.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (thread.hasUnread) Container(margin: const EdgeInsets.only(left: 8), width: 10, height: 10, decoration: BoxDecoration(color: Colors.teal.shade600, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}
