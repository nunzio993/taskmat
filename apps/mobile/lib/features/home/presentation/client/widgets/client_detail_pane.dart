import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/task.dart';
import '../../helper/widgets/task_location_map.dart';
import 'client_offers_list.dart';
import '../../../../chat/application/chat_providers.dart';
import '../../../../chat/domain/chat_models.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../application/task_service.dart';


class ClientDetailPane extends ConsumerWidget {
  final Task task;

  const ClientDetailPane({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Map
                   TaskLocationMapWidget(task: task),
                   const SizedBox(height: 24),
                   
                   // Description
                   Text('Description', style: Theme.of(context).textTheme.titleMedium),
                   const SizedBox(height: 8),
                   Text(task.description, style: Theme.of(context).textTheme.bodyMedium),
                   const SizedBox(height: 24),
                   
                   // Dynamic Status Area
                   _buildStatusArea(context, ref),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surface,
         border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                // Status Badge
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: bgForStatus(task.status),
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: colorForStatus(task.status)),
                   ),
                   child: Text(
                     task.status.toUpperCase(),
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 12,
                       color: colorForStatus(task.status),
                     ),
                   ),
                 ),
                 Text(timeago.format(task.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
             ],
           ),
           const SizedBox(height: 16),
           Text(task.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
           const SizedBox(height: 8),
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
             decoration: BoxDecoration(
               color: Theme.of(context).colorScheme.surfaceContainerHighest,
               borderRadius: BorderRadius.circular(8),
             ),
             child: Text(task.category, style: Theme.of(context).textTheme.labelSmall),
           ),
         ],
       ),
    );
  }

  Widget _buildStatusArea(BuildContext context, WidgetRef ref) {
    switch (task.status) {
      case 'posted':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Offers', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClientOffersList(
              task: task,
              onOpenChat: (helperId) => _openChatWithHelper(context, ref, helperId),
              onAcceptOffer: (offer) => _acceptOffer(context, ref, offer),
              onDeclineOffer: (offer) => _declineOffer(context, ref, offer),
            ),
            const SizedBox(height: 24),
            Text('Questions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildQuestionsSection(context, ref),
          ],
        );
      case 'assigned':
      case 'in_progress':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Assigned Helper', style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 8),
             // Mock Helper Info
             ListTile(
               leading: const CircleAvatar(child: Icon(Icons.person)),
               title: const Text('Helper Name'), // Would need task.helper populated
               subtitle: const Text('Top Rated Helper'),
               trailing: IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
               tileColor: Colors.grey.shade50,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
             ),
          ],
        );
      case 'payment_failed':
         return Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: Colors.red.shade50,
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: Colors.red.shade200),
           ),
           child: Column(
             children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Payment Failed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Please update your payment method to proceed.', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {}, 
                  child: const Text('Update Payment Method')
                ),
             ],
           ),
         );
      case 'completed':
         return Center(
           child: Column(
             children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text('Task Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Total: €${(task.priceCents/100).toStringAsFixed(2)}'),
             ],
           ),
         );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionsSection(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(taskThreadsProvider(task.id));

    return threadsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error: $e'),
      data: (threads) {
        if (threads.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('No questions yet.', style: TextStyle(color: Colors.grey))),
          );
        }

        return Column(
          children: threads.map((thread) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: thread.helperAvatarUrl != null 
                    ? NetworkImage(thread.helperAvatarUrl!)
                    : null,
                  child: thread.helperAvatarUrl == null 
                    ? const Icon(Icons.person_outline)
                    : null,
                ),
                title: Text(thread.helperName ?? 'Helper #${thread.helperId}'),
                subtitle: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      thread.helperRating != null 
                        ? '${thread.helperRating!.toStringAsFixed(1)} (${thread.helperReviewCount ?? 0})'
                        : 'Nuovo (0)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.chat_bubble_outline),
                onTap: () {
                  final offer = task.offers.where((o) => o.helperId == thread.helperId).firstOrNull;
                  _showChatDialog(context, ref, thread, offer);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showChatDialog(BuildContext context, WidgetRef ref, ChatThread thread, TaskOffer? offer) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ChatDialogContent(
          thread: thread,
          taskId: task.id,
          taskStatus: task.status,
          offer: offer,
          onAcceptOffer: (o) => _acceptOffer(context, ref, o),
          onDeclineOffer: (o) => _declineOffer(context, ref, o),
        ),
      ),
    );
  }

  Color colorForStatus(String status) {
     switch(status) {
       case 'posted': return Colors.blue;
       case 'assigned': return Colors.orange;
       case 'in_progress': return Colors.purple;
       case 'completed': return Colors.green;
       case 'cancelled': return Colors.red;
       case 'payment_failed': return Colors.red;
       default: return Colors.grey;
     }
  }

  Color bgForStatus(String status) {
     return colorForStatus(status).withOpacity(0.1);
  }

  void _openChatWithHelper(BuildContext context, WidgetRef ref, int helperId) async {
    print('DEBUG: _openChatWithHelper called with helperId=$helperId, taskId=${task.id}');
    try {
      // Wait for threads to load
      print('DEBUG: Loading threads...');
      final threads = await ref.read(taskThreadsProvider(task.id).future);
      print('DEBUG: Loaded ${threads.length} threads');
      var thread = threads.where((t) => t.helperId == helperId).firstOrNull;
      
      if (thread == null) {
        print('DEBUG: No thread found locally for helper $helperId, creating one...');
        try {
          thread = await ref.read(chatServiceProvider).getOrCreateThreadAsClient(task.id, helperId);
          // Refresh the list provider so it appears there too
          ref.invalidate(taskThreadsProvider(task.id));
        } catch (e) {
          print('DEBUG: Failed to create thread: $e');
        }
      }
      
      if (thread != null) {
        print('DEBUG: Found/Created thread for helper $helperId, opening dialog');
        // Find the offer from this helper (if any)
        final offer = task.offers.where((o) => o.helperId == helperId).firstOrNull;
        print('DEBUG: Offer found? ${offer != null}');
        if (context.mounted) {
          _showChatDialog(context, ref, thread, offer);
        }
      } else {
        print('DEBUG: Still no thread for helper $helperId');
        // If no thread exists yet, show a message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to start chat with this helper.')),
          );
        }
      }
    } catch (e, st) {
      print('DEBUG: Error in _openChatWithHelper: $e');
      print('DEBUG: Stack trace: $st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  void _acceptOffer(BuildContext context, WidgetRef ref, TaskOffer offer) async {
    try {
      await ref.read(taskServiceProvider.notifier).selectOffer(task.id, offer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _declineOffer(BuildContext context, WidgetRef ref, TaskOffer offer) async {
    try {
      await ref.read(taskServiceProvider.notifier).declineOffer(task.id, offer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer declined.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class ChatDialogContent extends ConsumerStatefulWidget {
  final ChatThread thread;
  final int taskId;
  final String? taskStatus;
  final TaskOffer? offer;
  final Function(TaskOffer)? onAcceptOffer;
  final Function(TaskOffer)? onDeclineOffer;

  const ChatDialogContent({
    super.key, 
    required this.thread, 
    required this.taskId,
    this.taskStatus,
    this.offer,
    this.onAcceptOffer,
    this.onDeclineOffer,
  });

  @override
  ConsumerState<ChatDialogContent> createState() => _ChatDialogContentState();
}

class _ChatDialogContentState extends ConsumerState<ChatDialogContent> {
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    await ref.read(chatControllerProvider.notifier).sendMessage(widget.thread.id, text);
    ref.invalidate(threadMessagesProvider(widget.thread.id));
  }

  Widget _buildOfferBar(BuildContext context) {
    final offer = widget.offer!;
    final taskStatus = widget.taskStatus ?? 'posted';
    final isTaskAssigned = ['assigned', 'in_progress', 'in_confirmation', 'completed'].contains(taskStatus);
    final isOfferAccepted = offer.status == 'accepted';
    final isOfferDeclined = offer.status == 'declined';
    final isOfferPending = offer.status == 'submitted';
    
    Color bgColor;
    Color borderColor;
    Widget statusWidget;
    
    if (isOfferAccepted) {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      statusWidget = Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Text('Offer Accepted', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (isOfferDeclined) {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade200;
      statusWidget = Row(
        children: [
          Icon(Icons.cancel, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Text('Offer Declined', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
        ],
      );
    } else if (isTaskAssigned && !isOfferAccepted) {
      // Task is assigned but this offer wasn't the one accepted
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade300;
      statusWidget = Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Text('Another offer was accepted', style: TextStyle(color: Colors.grey.shade600)),
        ],
      );
    } else {
      // Pending offer, show action buttons
      bgColor = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
      borderColor = Colors.grey.shade200;
      statusWidget = Row(
        children: [
          OutlinedButton(
            onPressed: () {
              widget.onDeclineOffer?.call(offer);
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              widget.onAcceptOffer?.call(offer);
              Navigator.pop(context);
            },
            child: const Text('Accept'),
          ),
        ],
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOfferPending ? 'Current Offer' : 'Offer', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(
                  '€${(offer.priceCents / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isOfferAccepted ? Colors.green.shade700 : isOfferDeclined ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          statusWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(threadMessagesProvider(widget.thread.id));
    final currentUser = ref.watch(authProvider).value;

    return Container(
      height: 500,
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          // Header
          Container(
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text('Chat with ${widget.thread.helperName ?? "Helper"}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                 IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
               ],
             ),
          ),
          
          // Offer Action Bar (if offer exists)
          if (widget.offer != null)
            _buildOfferBar(context),
          
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (messages) {
                 if (messages.isEmpty) {
                   return const Center(child: Text('No messages.'));
                 }
                 return ListView.builder(
                   padding: const EdgeInsets.all(16),
                   itemCount: messages.length,
                   itemBuilder: (context, index) {
                     final msg = messages[index];
                     final isMe = msg.senderId == currentUser?.id;
                     
                     // Custom rendering for Offer Updates
                     if (msg.type == 'offer_update') {
                        final priceCents = msg.payload['price_cents'];
                        final offerId = msg.payload['offer_id'];
                        final isClient = ref.read(authProvider).value?.role == 'client';
                        final taskStatus = widget.taskStatus ?? 'posted';
                        final isTaskAssigned = ['assigned', 'in_progress', 'in_confirmation', 'completed'].contains(taskStatus);
                        
                        // Determine if this specific offer is the accepted one
                        final isThisOfferAccepted = widget.offer?.id == offerId && widget.offer?.status == 'accepted';

                        return Align(
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            padding: const EdgeInsets.all(16),
                            width: 250,
                            decoration: BoxDecoration(
                              color: isThisOfferAccepted ? Colors.green.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isThisOfferAccepted ? Colors.green.shade200 : Colors.blue.shade100),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isThisOfferAccepted ? 'Accepted Offer' : (isTaskAssigned ? 'Offer' : 'New Offer'),
                                  style: TextStyle(
                                    color: isThisOfferAccepted ? Colors.green.shade700 : Colors.blue.shade700,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                                const SizedBox(height: 8),
                                Text('€${(priceCents/100).toStringAsFixed(2)}', style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isThisOfferAccepted ? Colors.green.shade700 : null
                                )),
                                const SizedBox(height: 12),
                                Text(msg.body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 12),
                                // Show buttons only if client, task not assigned, and this is a pending offer
                                if (isClient && !isTaskAssigned)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () {
                                          final tempOffer = TaskOffer(id: offerId, taskId: widget.taskId, helperId: msg.senderId, priceCents: priceCents, message: "", status: 'submitted');
                                          widget.onDeclineOffer?.call(tempOffer);
                                          Navigator.pop(context);
                                        },
                                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 12)),
                                        child: const Text('Decline'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          final tempOffer = TaskOffer(id: offerId, taskId: widget.taskId, helperId: msg.senderId, priceCents: priceCents, message: "", status: 'submitted');
                                          widget.onAcceptOffer?.call(tempOffer);
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
                                        child: const Text('Accept'),
                                      ),
                                    ],
                                  )
                                else if (isThisOfferAccepted)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                                      const SizedBox(width: 4),
                                      Text('Accepted', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                                    ],
                                  )
                                else if (isTaskAssigned)
                                  Text('Task already assigned', style: TextStyle(color: Colors.grey.shade500, fontSize: 11))
                              ],
                            ),
                          ),
                        );
                     } else if (msg.type == 'system') {
                        return Align(
                           alignment: Alignment.center,
                           child: Container(
                             margin: const EdgeInsets.symmetric(vertical: 8),
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: Colors.grey.shade200,
                               borderRadius: BorderRadius.circular(12),
                             ),
                             child: Text(msg.body, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                           ),
                        );
                     }

                     return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                           margin: const EdgeInsets.only(bottom: 8),
                           padding: const EdgeInsets.all(10),
                           decoration: BoxDecoration(
                             color: isMe ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade100,
                             borderRadius: BorderRadius.circular(12),
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.end,
                             children: [
                               Text(msg.body),
                               Text(timeago.format(msg.createdAt, locale: 'en_short'), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                             ],
                           ),
                        ),
                     );
                   },
                 );
              }
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Reply...'))),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
