import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/application/task_service.dart';
import 'package:mobile/features/home/domain/task.dart';
import '../application/tasks_provider.dart';

class OffersList extends ConsumerWidget {
  final int taskId;
  final List<TaskOffer> offers;

  const OffersList({super.key, required this.taskId, required this.offers});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (offers.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Text('No offers yet.'),
      ));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: offers.length,
      itemBuilder: (context, index) {
        final offer = offers[index];
        return Card(
          child: ListTile(
            title: Text('€${(offer.priceCents / 100).toStringAsFixed(2)}'),
            subtitle: Text(offer.message),
            trailing: offer.status == 'submitted' 
              ? FilledButton(
                  onPressed: () async {
                    try {
                      await ref.read(taskServiceProvider.notifier).selectOffer(taskId, offer.id);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer accepted!')));
                      // Request refresh of nearby tasks (although this task might disappear from it)
                      // Ideally we should navigate away or refresh specific task
                      ref.invalidate(nearbyTasksProvider);
                      // Also pop if desired, but user might want to see result
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text('Accept'),
                )
              : Chip(label: Text(offer.status.toUpperCase())),
          ),
        );
      },
    );
  }
}
