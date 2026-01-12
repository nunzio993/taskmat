import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/task.dart';
import '../../helper/widgets/task_location_map.dart';
import 'client_offers_list.dart';
import '../../../../chat/application/chat_providers.dart';
import '../../../../chat/domain/chat_models.dart';
import '../../../../auth/application/auth_provider.dart';
import '../../../application/task_service.dart';
import '../../../application/tasks_provider.dart';
import '../../../../../core/api_client.dart';


class ClientDetailPane extends ConsumerWidget {
  final Task task;

  const ClientDetailPane({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Colors.grey.shade50,
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
                   Row(
                     children: [
                       Icon(Icons.description_outlined, color: Colors.teal.shade600, size: 20),
                       const SizedBox(width: 8),
                       Text('Descrizione', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Container(
                     padding: const EdgeInsets.all(16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.teal.shade100),
                     ),
                     child: Text(task.description, style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700)),
                   ),
                   const SizedBox(height: 24),
                   
                   // Address Section
                   _buildAddressSection(context, ref),
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
         gradient: LinearGradient(
           colors: [Colors.teal.shade50, Colors.white],
           begin: Alignment.topCenter,
           end: Alignment.bottomCenter,
         ),
         border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
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
                 Text(timeago.format(task.createdAt), style: TextStyle(color: Colors.teal.shade500, fontSize: 12)),
             ],
           ),
           const SizedBox(height: 16),
           Text(task.title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800)),
           const SizedBox(height: 8),
           Row(
             children: [
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.teal.shade100,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Text(task.category, style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.w500)),
               ),
               const SizedBox(width: 10),
               Text('€${(task.priceCents / 100).toStringAsFixed(2)}', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 18)),
             ],
           ),
         ],
       ),
    );
  }

  Widget _buildAddressSection(BuildContext context, WidgetRef ref) {
    final canEdit = task.status == 'posted';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 8),
                Text('Indirizzo', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () => _showEditAddressDialog(context, ref),
                icon: Icon(Icons.edit, size: 16, color: Colors.teal.shade600),
                label: Text('Modifica', style: TextStyle(color: Colors.teal.shade600)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.displayAddress ?? 'Indirizzo non disponibile',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey.shade800),
              ),
              if (task.accessNotes != null && task.accessNotes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.teal.shade400, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.accessNotes!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
              if (!canEdit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'L\'indirizzo non è modificabile dopo l\'assegnazione',
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _showEditAddressDialog(BuildContext context, WidgetRef ref) async {
    final streetController = TextEditingController(text: task.street ?? '');
    final streetNumberController = TextEditingController(text: task.streetNumber ?? '');
    final cityController = TextEditingController(text: task.city ?? '');
    final postalCodeController = TextEditingController(text: task.postalCode ?? '');
    final accessNotesController = TextEditingController(text: task.accessNotes ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('Modifica Indirizzo'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: streetController,
                decoration: InputDecoration(
                  labelText: 'Via/Piazza',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: streetNumberController,
                decoration: InputDecoration(
                  labelText: 'Numero civico',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'Città',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: postalCodeController,
                      decoration: InputDecoration(
                        labelText: 'CAP',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: accessNotesController,
                decoration: InputDecoration(
                  labelText: 'Note di accesso (citofono, piano...)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annulla', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600),
            child: const Text('Salva', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final dio = ref.read(apiClientProvider);
        await dio.patch('/tasks/${task.id}/address', data: {
          'street': streetController.text,
          'street_number': streetNumberController.text,
          'city': cityController.text,
          'postal_code': postalCodeController.text,
          'access_notes': accessNotesController.text,
        });
        
        // Refresh tasks
        ref.invalidate(myCreatedTasksProvider);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Indirizzo aggiornato!'),
              backgroundColor: Colors.teal.shade600,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildStatusArea(BuildContext context, WidgetRef ref) {
    switch (task.status) {
      case 'posted':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 8),
                Text('Offerte', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            ClientOffersList(
              task: task,
              onOpenChat: (helperId) => _openChatWithHelper(context, ref, helperId),
              onAcceptOffer: (offer) => _acceptOffer(context, ref, offer),
              onDeclineOffer: (offer) => _declineOffer(context, ref, offer),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.chat_outlined, color: Colors.teal.shade600, size: 20),
                const SizedBox(width: 8),
                Text('Domande', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            _buildQuestionsSection(context, ref),
          ],
        );
      case 'assigned':
      case 'in_progress':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Icon(Icons.person, color: Colors.teal.shade600, size: 20),
                 const SizedBox(width: 8),
                 Text('Helper Assegnato', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
               ],
             ),
             const SizedBox(height: 8),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.teal.shade50,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.teal.shade200),
               ),
               child: Row(
                 children: [
                   CircleAvatar(backgroundColor: Colors.teal.shade200, child: Icon(Icons.person, color: Colors.teal.shade700)),
                   const SizedBox(width: 12),
                   const Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('Helper Name', style: TextStyle(fontWeight: FontWeight.bold)),
                         Text('Top Rated Helper', style: TextStyle(fontSize: 12, color: Colors.grey)),
                       ],
                     ),
                   ),
                   IconButton(
                     icon: Icon(Icons.chat, color: Colors.teal.shade600),
                     onPressed: () {},
                   ),
                 ],
               ),
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
           child: Container(
             padding: const EdgeInsets.all(32),
             decoration: BoxDecoration(
               color: Colors.green.shade50,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.green.shade200),
             ),
             child: Column(
               children: [
                  Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
                  const SizedBox(height: 16),
                  const Text('Task Completata!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Totale: €${(task.priceCents/100).toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 16)),
               ],
             ),
           ),
         );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildQuestionsSection(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(taskThreadsProvider(task.id));

    return threadsAsync.when(
      loading: () => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400))),
      error: (e, st) => Text('Errore: $e', style: TextStyle(color: Colors.red.shade600)),
      data: (threads) {
        if (threads.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.teal.shade300),
                const SizedBox(width: 10),
                Text('Nessuna domanda', style: TextStyle(color: Colors.teal.shade500)),
              ],
            ),
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
                title: GestureDetector(
                  onTap: () => context.push('/u/${thread.helperId}'),
                  child: Text(
                    thread.helperName ?? 'Helper #${thread.helperId}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, decoration: TextDecoration.underline),
                  ),
                ),
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
       case 'posted': return Colors.teal.shade600;
       case 'assigned': return Colors.orange.shade600;
       case 'in_progress': return Colors.purple.shade600;
       case 'completed': return Colors.green.shade600;
       case 'cancelled': return Colors.red.shade600;
       case 'payment_failed': return Colors.red.shade600;
       default: return Colors.grey.shade600;
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
      // Refresh task data to show updated offer statuses (other offers are auto-declined by backend)
      ref.invalidate(myCreatedTasksProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted!')),
        );
        Navigator.pop(context); // Close the detail pane to refresh view
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
    final isOfferDeclined = offer.status == 'rejected' || offer.status == 'declined';
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
      bgColor = Colors.teal.shade50;
      borderColor = Colors.teal.shade200;
      statusWidget = Row(
        children: [
          OutlinedButton(
            onPressed: () {
              widget.onDeclineOffer?.call(offer);
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade600,
              side: BorderSide(color: Colors.red.shade300),
            ),
            child: const Text('Rifiuta'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              widget.onAcceptOffer?.call(offer);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accetta'),
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
                Text(isOfferPending ? 'Offerta Attuale' : 'Offerta', style: TextStyle(fontSize: 12, color: Colors.teal.shade600)),
                Text(
                  '€${(offer.priceCents / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isOfferAccepted ? Colors.green.shade700 : isOfferDeclined ? Colors.red.shade700 : Colors.teal.shade700,
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
               gradient: LinearGradient(
                 colors: [Colors.teal.shade50, Colors.white],
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
               ),
               border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
             ),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 GestureDetector(
                   onTap: () {
                     Navigator.pop(context);
                     context.push('/u/${widget.thread.helperId}');
                   },
                   child: Text(
                     'Chat con ${widget.thread.helperName ?? "Helper"}',
                     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal.shade700, decoration: TextDecoration.underline),
                   ),
                 ),
                 IconButton(icon: Icon(Icons.close, color: Colors.teal.shade600), onPressed: () => Navigator.pop(context)),
               ],
             ),
          ),
          
          // Offer Action Bar (if offer exists)
          if (widget.offer != null)
            _buildOfferBar(context),
          
          // Messages
          Expanded(
            child: messagesAsync.when(
              loading: () => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400))),
              error: (e, st) => Center(child: Text('Errore: $e', style: TextStyle(color: Colors.red.shade600))),
              data: (messages) {
                 if (messages.isEmpty) {
                   return Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.chat_bubble_outline, size: 48, color: Colors.teal.shade200),
                         const SizedBox(height: 12),
                         Text('Nessun messaggio', style: TextStyle(color: Colors.teal.shade400)),
                       ],
                     ),
                   );
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
                              border: Border.all(color: isThisOfferAccepted ? Colors.green.shade200 : Colors.teal.shade100),
                              boxShadow: [
                                BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isThisOfferAccepted ? 'Offerta Accettata' : (isTaskAssigned ? 'Offerta' : 'Nuova Offerta'),
                                  style: TextStyle(
                                    color: isThisOfferAccepted ? Colors.green.shade700 : Colors.teal.shade700,
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
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade600,
                                          side: BorderSide(color: Colors.red.shade300),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        child: const Text('Rifiuta'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          final tempOffer = TaskOffer(id: offerId, taskId: widget.taskId, helperId: msg.senderId, priceCents: priceCents, message: "", status: 'submitted');
                                          widget.onAcceptOffer?.call(tempOffer);
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.teal.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                        child: const Text('Accetta'),
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
                             color: isMe ? Colors.teal.shade100 : Colors.grey.shade100,
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
              border: Border(top: BorderSide(color: Colors.teal.shade100)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                      hintStyle: TextStyle(color: Colors.teal.shade300),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.teal.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
