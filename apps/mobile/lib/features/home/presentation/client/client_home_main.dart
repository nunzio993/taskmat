import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/tasks_provider.dart';
import 'widgets/task_status_counters.dart';
import 'widgets/active_tasks_preview.dart';
import 'widgets/become_helper_section.dart';

/// Main Home view for Client mode
class ClientHomeMain extends ConsumerWidget {
  const ClientHomeMain({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myCreatedTasksProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Blocco A: CTA primaria
            _buildCreateTaskCTA(context),
            const SizedBox(height: 24),
            
            // Contatori stati
            const TaskStatusCounters(),
            const SizedBox(height: 32),
            
            // Blocco B: Preview task attive
            const ActiveTasksPreview(),
            const SizedBox(height: 32),
            
            // Blocco C: Sezione conversione helper
            const BecomeHelperSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTaskCTA(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/create-task'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Crea una Nuova Task',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
