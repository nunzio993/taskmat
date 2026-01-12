import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/task.dart';
import '../../../application/tasks_provider.dart';

/// Opportunities preview section showing nearby available tasks
class OpportunitiesPreviewSection extends ConsumerWidget {
  const OpportunitiesPreviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(nearbyTasksProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.explore, color: Colors.teal.shade600, size: 22),
            const SizedBox(width: 8),
            Text('Opportunità Vicine', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/find-work'), child: Text('Vedi tutte', style: TextStyle(color: Colors.teal.shade600))),
          ],
        ),
        const SizedBox(height: 12),
        tasksAsync.when(
          data: (tasks) {
            final postedTasks = tasks.where((t) => t.status == 'posted').take(5).toList();
            if (postedTasks.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, color: Colors.grey.shade400), const SizedBox(width: 10), Text('Nessuna opportunità al momento', style: TextStyle(color: Colors.grey.shade500))]),
              );
            }
            return Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal.shade100)),
              child: Column(children: postedTasks.map((task) => _buildTaskItem(context, task)).toList()),
            );
          },
          loading: () => Center(child: Padding(padding: const EdgeInsets.all(20), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)))),
          error: (_, __) => const Text('Errore caricamento opportunità'),
        ),
      ],
    );
  }
  
  Widget _buildTaskItem(BuildContext context, Task task) {
    final diff = DateTime.now().difference(task.createdAt);
    final timeAgo = diff.inMinutes < 60 ? '${diff.inMinutes} min fa' : (diff.inHours < 24 ? '${diff.inHours} ore fa' : '${diff.inDays} giorni fa');
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/find-work?focusTaskId=${task.id}'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.teal.shade50))),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                child: Icon(_getCategoryIcon(task.category), color: Colors.teal.shade600, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        if (task.urgency.toLowerCase() == 'high')
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                            child: Text('URGENTE', style: TextStyle(color: Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                        Text(task.category, style: TextStyle(color: Colors.teal.shade600, fontSize: 12)),
                        Text(' • $timeAgo', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.teal.shade600, borderRadius: BorderRadius.circular(8)),
                child: Text('€${(task.priceCents / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pulizie': return Icons.cleaning_services;
      case 'traslochi': return Icons.local_shipping;
      case 'giardinaggio': return Icons.grass;
      case 'montaggio mobili': return Icons.handyman;
      case 'idraulica': return Icons.plumbing;
      default: return Icons.work;
    }
  }
}
