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
      loading: () => SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            valueColor: AlwaysStoppedAnimation(Colors.teal.shade400),
          ),
        ),
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
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade50,
                Colors.teal.shade100.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_outlined, color: Colors.teal.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Riepilogo Task',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (posted > 0) _buildCounterChip(context, 'Pubblicate', posted, Icons.publish),
                  if (assigned > 0) _buildCounterChip(context, 'Assegnate', assigned, Icons.assignment_ind),
                  if (inProgress > 0) _buildCounterChip(context, 'In Lavoro', inProgress, Icons.work),
                  if (inConfirmation > 0) _buildCounterChip(context, 'Da Confermare', inConfirmation, Icons.pending_actions),
                  if (paymentFailed > 0) _buildPaymentFailedChip(context, paymentFailed),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCounterChip(BuildContext context, String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
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
          Icon(icon, color: Colors.teal.shade400, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.teal.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFailedChip(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.red.shade600,
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
          Icon(Icons.payment, color: Colors.red.shade400, size: 16),
          const SizedBox(width: 4),
          Text(
            'Pagamento Fallito',
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
