import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/tasks_provider.dart';

/// Contatori per stato delle task del cliente
class TaskStatusCounters extends ConsumerWidget {
  const TaskStatusCounters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(myCreatedTasksProvider);
    
    return tasksAsync.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        // Count by status
        final posted = tasks.where((t) => t.status == 'posted').length;
        final assigned = tasks.where((t) => t.status == 'assigned').length;
        final inProgress = tasks.where((t) => t.status == 'in_progress').length;
        final inConfirmation = tasks.where((t) => t.status == 'in_confirmation').length;
        final paymentFailed = tasks.where((t) => t.status == 'payment_failed').length;
        
        final activeTotal = posted + assigned + inProgress + inConfirmation + paymentFailed;
        
        if (activeTotal == 0) return const SizedBox.shrink();
        
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (posted > 0) _buildCounterChip(context, 'Pubblicate', posted, Colors.blue),
            if (assigned > 0) _buildCounterChip(context, 'Assegnate', assigned, Colors.orange),
            if (inProgress > 0) _buildCounterChip(context, 'In Lavoro', inProgress, Colors.green),
            if (inConfirmation > 0) _buildCounterChip(context, 'Da Confermare', inConfirmation, Colors.purple),
            if (paymentFailed > 0) _buildCounterChip(context, 'Pagamento Fallito', paymentFailed, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildCounterChip(BuildContext context, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
