import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/task.dart';
import '../../../application/tasks_provider.dart';

/// Preview delle task attive del cliente (max 5)
class ActiveTasksPreview extends ConsumerWidget {
  const ActiveTasksPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myCreatedTasksProvider);
    
    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Errore: $e')),
      data: (tasks) {
        // Filter active tasks and take max 5
        final activeTasks = tasks.where((t) => 
          ['posted', 'assigned', 'in_progress', 'in_confirmation', 'payment_failed', 'assigning']
            .contains(t.status)
        ).take(5).toList();
        
        if (activeTasks.isEmpty) {
          return _buildEmptyState(context);
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Le mie task attive',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (tasks.length > 5)
                  TextButton(
                    onPressed: () => context.go('/my-tasks'),
                    child: const Text('Vedi tutte'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...activeTasks.map((task) => _buildTaskCard(context, task)),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.task_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'Nessuna task attiva',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea la tua prima task per iniziare!',
            style: TextStyle(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    final statusInfo = _getStatusInfo(task.status);
    final offersCount = task.offers.length;
    final timeSinceCreated = _getTimeSince(task.createdAt);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.go('/my-tasks?selectedTaskId=${task.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon categoria
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(task.category),
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Info task
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Categoria: ${task.category}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status / Info destra
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Badge stato o info offerte
                  if (task.status == 'payment_failed')
                    _buildPaymentFailedBadge(context, task)
                  else if (task.status == 'posted' && offersCount > 0)
                    Text(
                      'Offerte ricevute: $offersCount',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusInfo.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusInfo.label,
                        style: TextStyle(
                          color: statusInfo.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    timeSinceCreated,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentFailedBadge(BuildContext context, Task task) {
    return InkWell(
      onTap: () => context.go('/my-tasks?selectedTaskId=${task.id}&action=retry_payment'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pagamento Fallito',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward, size: 14, color: Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  ({String label, Color color}) _getStatusInfo(String status) {
    switch (status) {
      case 'posted':
        return (label: 'Pubblicata', color: Colors.blue);
      case 'assigning':
        return (label: 'In Selezione', color: Colors.orange);
      case 'assigned':
        return (label: 'Assegnata', color: Colors.orange);
      case 'in_progress':
        return (label: 'In Lavoro', color: Colors.green);
      case 'in_confirmation':
        return (label: 'Da Confermare', color: Colors.purple);
      case 'payment_failed':
        return (label: 'Pagamento Fallito', color: Colors.red);
      default:
        return (label: status, color: Colors.grey);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'pulizie':
        return Icons.cleaning_services;
      case 'traslochi':
        return Icons.local_shipping;
      case 'giardinaggio':
        return Icons.grass;
      case 'montaggio mobili':
        return Icons.handyman;
      case 'idraulica':
        return Icons.plumbing;
      case 'elettricità':
        return Icons.electrical_services;
      case 'imbiancatura':
        return Icons.format_paint;
      case 'baby-sitting':
        return Icons.child_care;
      default:
        return Icons.work;
    }
  }

  String _getTimeSince(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min fa';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ore fa';
    } else {
      return '${diff.inDays} giorni fa';
    }
  }
}
