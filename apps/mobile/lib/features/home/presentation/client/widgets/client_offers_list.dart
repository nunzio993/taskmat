import 'package:flutter/material.dart';
import '../../../domain/task.dart';
import 'package:timeago/timeago.dart' as timeago;

class ClientOffersList extends StatelessWidget {
  final Task task;
  final Function(int helperId)? onOpenChat;
  final Function(TaskOffer offer)? onAcceptOffer;
  final Function(TaskOffer offer)? onDeclineOffer;

  const ClientOffersList({
    super.key, 
    required this.task,
    this.onOpenChat,
    this.onAcceptOffer,
    this.onDeclineOffer,
  });

  @override
  Widget build(BuildContext context) {
    final offers = task.offers ?? [];
    
    if (offers.isEmpty) {
       return Container(
         padding: const EdgeInsets.all(24),
         decoration: BoxDecoration(
           color: Colors.grey.shade50,
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.shade200),
         ),
         child: Center(
           child: Column(
             children: [
               Icon(Icons.access_time, size: 48, color: Colors.grey.shade300),
               const SizedBox(height: 16),
               Text('No offers yet.', style: TextStyle(color: Colors.grey.shade500)),
               const SizedBox(height: 4),
               const Text('Helpers near you will be notified.', style: TextStyle(color: Colors.grey, fontSize: 12)),
             ],
           ),
         ),
       );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final offer = offers[index];
        final isDeclined = offer.status == 'declined';
        final isAccepted = offer.status == 'accepted';
        final isTaskAssigned = ['assigned', 'in_progress', 'completed'].contains(task.status);
        
        // If task is assigned, but this offer is NOT the accepted one, we treat it as effectively declined/ignored UI-wise
        // effectively disabling the "Accept" button.
        final showActions = !isAccepted && !isDeclined && !isTaskAssigned;

        return Card(
           elevation: 0,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(12),
             side: BorderSide(color: isAccepted ? Colors.green : (isDeclined ? Colors.red.shade200 : Colors.grey.shade200)),
           ),
           child: Padding(
             padding: const EdgeInsets.all(16),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: offer.helperAvatarUrl != null ? NetworkImage(offer.helperAvatarUrl!) : null,
                        child: offer.helperAvatarUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer.helperName ?? 'Helper', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              Text('${offer.helperRating?.toStringAsFixed(1) ?? "N/A"}', style: const TextStyle(fontSize: 12)),
                            ],
                          )
                        ],
                      ),
                      const Spacer(),
                      Text('€${(offer.priceCents/100).toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                   ],
                 ),
                 if (offer.message.isNotEmpty) ...[
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.grey.shade50,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(offer.message, style: const TextStyle(fontSize: 13)),
                   ),
                 ],
                 const SizedBox(height: 16),
                 // Status badge or action buttons
                 if (isAccepted)
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     child: const Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.check_circle, color: Colors.green),
                         SizedBox(width: 8),
                         Text('Accepted', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   )
                 else if (isDeclined)
                   Container(
                     padding: const EdgeInsets.symmetric(vertical: 12),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.cancel, color: Colors.red.shade300),
                         const SizedBox(width: 8),
                         Text('Declined', style: TextStyle(color: Colors.red.shade300)),
                       ],
                     ),
                   )
                 else if (showActions)
                   Row(
                     children: [
                       Expanded(
                         child: OutlinedButton(
                           onPressed: () {
                             print('DEBUG: Chat button pressed for helper ${offer.helperId}');
                             onOpenChat?.call(offer.helperId);
                           },
                           child: const Text('Chat Now'),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: OutlinedButton(
                           onPressed: () => onDeclineOffer?.call(offer),
                           style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                           child: const Text('Decline'),
                         ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: ElevatedButton(
                           onPressed: () => onAcceptOffer?.call(offer),
                           child: const Text('Accept'),
                         ),
                       ),
                     ],
                   )
                 else
                   // Task is assigned (to someone else), show simple Chat button or text?
                   // User said "rendere non accettabili le altre offerte". 
                   // Let's show "Chat" but no Accept/Decline.
                   Row(
                     children: [
                        Expanded(
                         child: OutlinedButton(
                           onPressed: () {
                             onOpenChat?.call(offer.helperId);
                           },
                           child: const Text('Chat'),
                         ),
                       ),
                     ]
                   ),
               ],
             ),
           ),
        );
      },
    );
  }
}
