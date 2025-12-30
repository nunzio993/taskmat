import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/task.dart';
import '../../../../chat/application/chat_providers.dart';
import '../../../../chat/domain/chat_models.dart';
import '../../../../auth/application/auth_provider.dart';

class ClarificationChatWidget extends ConsumerStatefulWidget {
  final Task task;
  final bool isEnabled;

  const ClarificationChatWidget({
    super.key, 
    required this.task, 
    this.isEnabled = true,
  });

  @override
  ConsumerState<ClarificationChatWidget> createState() => _ClarificationChatWidgetState();
}

class _ClarificationChatWidgetState extends ConsumerState<ClarificationChatWidget> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _templates = [
    "Is the price negotiable?",
    "Can I have more details?",
    "Is the date flexible?",
    "Do you have necessary tools?",
    "Can I see a photo of the item?",
  ];

  void _sendMessage(int threadId) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    
    // Optimistic UI or wait? Controller handles state, we just fire and forget here
    // But better to close keyboard?
    
    await ref.read(chatControllerProvider.notifier).sendMessage(threadId, text);
    
    _scrollToBottom();
  }

  void _useTemplate(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(myTaskThreadProvider(widget.task.id));
    final currentUser = ref.watch(authProvider).value;

    return Column(
      children: [
        // Chat Area
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: threadAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading chat: $e', style: const TextStyle(color: Colors.red))),
            data: (thread) {
               final messagesAsync = ref.watch(threadMessagesProvider(thread.id));
               
               return Column(
                 children: [
                   Expanded(
                     child: messagesAsync.when(
                       loading: () => const Center(child: CircularProgressIndicator()),
                       error: (e, st) => Center(child: Text('Error: $e')),
                       data: (messages) {
                          if (messages.isEmpty) {
                            return Center(
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade300),
                                   const SizedBox(height: 8),
                                   Text(
                                     "No messages yet.\nAsk for clarification below.", 
                                     textAlign: TextAlign.center,
                                     style: TextStyle(color: Colors.grey.shade400),
                                   ),
                                 ],
                               ),
                             );
                          }
                          
                          // Auto scroll on first load
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                             if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
                                // Only if near bottom? Or always?
                             }
                          });

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.senderId == currentUser?.id;
                              return _buildMessageBubble(msg, isMe, context);
                            },
                          );
                       }
                     ),
                   ),
                   
                   // Templates
                   if (widget.isEnabled)
                     Container(
                       height: 50,
                       alignment: Alignment.centerLeft,
                       decoration: BoxDecoration(
                         border: Border(top: BorderSide(color: Colors.grey.shade200)),
                       ),
                       child: ListView.separated(
                         padding: const EdgeInsets.symmetric(horizontal: 16),
                         scrollDirection: Axis.horizontal,
                         itemCount: _templates.length,
                         separatorBuilder: (_, __) => const SizedBox(width: 8),
                         itemBuilder: (context, index) {
                           return ActionChip(
                             label: Text(_templates[index], style: const TextStyle(fontSize: 12)),
                             backgroundColor: Theme.of(context).colorScheme.surface,
                             onPressed: () => _useTemplate(_templates[index]),
                           );
                         },
                       ),
                     ),
            
                   // Input Area
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                       border: Border(top: BorderSide(color: Colors.grey.shade200)),
                     ),
                     child: Row(
                       children: [
                         Expanded(
                           child: TextField(
                             controller: _controller,
                             decoration: const InputDecoration(
                               hintText: "Type a message...",
                               border: InputBorder.none,
                               isDense: true,
                             ),
                             enabled: widget.isEnabled,
                             onSubmitted: (_) => _sendMessage(thread.id),
                           ),
                         ),
                         IconButton(
                           icon: Icon(Icons.send, color: widget.isEnabled ? Theme.of(context).colorScheme.primary : Colors.grey),
                           onPressed: widget.isEnabled ? () => _sendMessage(thread.id) : null,
                         ),
                       ],
                     ),
                   ),
                 ],
               );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(TaskMessage msg, bool isMe, BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
          boxShadow: [
             if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(msg.body, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              timeago.format(msg.createdAt, locale: 'en_short'), 
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
