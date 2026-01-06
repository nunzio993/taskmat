import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/task.dart';
import '../../../application/tasks_provider.dart';

/// Active jobs section showing helper's current assignments
class ActiveJobsSection extends ConsumerWidget {
  const ActiveJobsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(myAssignedTasksProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work, color: Colors.teal.shade600, size: 22),
            const SizedBox(width: 8),
            Text('Incarichi Attivi', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold, fontSize: 17)),
            const Spacer(),
            TextButton(onPressed: () => context.go('/my-jobs'), child: Text('Vedi tutti', style: TextStyle(color: Colors.teal.shade600))),
          ],
        ),
        const SizedBox(height: 12),
        jobsAsync.when(
          data: (jobs) {
            final activeJobs = jobs.where((t) => 
              ['assigned', 'in_progress', 'in_confirmation'].contains(t.status.toLowerCase())
            ).toList();
            
            activeJobs.sort((a, b) {
              const priority = {'in_confirmation': 0, 'in_progress': 1, 'assigned': 2};
              return (priority[a.status.toLowerCase()] ?? 3).compareTo(priority[b.status.toLowerCase()] ?? 3);
            });
            
            if (activeJobs.isEmpty) return _buildEmptyState(context);
            return Column(children: activeJobs.take(5).map((job) => _buildJobCard(context, job)).toList());
          },
          loading: () => Center(child: Padding(padding: const EdgeInsets.all(32), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400)))),
          error: (e, _) => Text('Errore: $e'),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.3)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 8)]),
            child: Icon(Icons.search, size: 32, color: Colors.teal.shade400),
          ),
          const SizedBox(height: 14),
          Text('Nessun incarico attivo', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Cerca nuove opportunità di lavoro', style: TextStyle(color: Colors.teal.shade500, fontSize: 13)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => context.go('/find-work'),
            icon: const Icon(Icons.search),
            label: const Text('Trova lavoro'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade600, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildJobCard(BuildContext context, Task job) {
    final statusInfo = _getStatusInfo(job.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: statusInfo.color.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go('/my-jobs?selectedJobId=${job.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(width: 4, height: 50, decoration: BoxDecoration(color: statusInfo.color, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: statusInfo.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(statusInfo.label, style: TextStyle(color: statusInfo.color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('€${(job.priceCents / 100).toStringAsFixed(0)}', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(job.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: Icon(Icons.open_in_new, color: Colors.teal.shade400, size: 20), onPressed: () => context.go('/my-jobs?selectedJobId=${job.id}'), tooltip: 'Apri job'),
                    IconButton(icon: Icon(Icons.chat_bubble_outline, color: Colors.teal.shade400, size: 20), onPressed: () => context.go('/my-jobs?selectedJobId=${job.id}&openChat=true'), tooltip: 'Chat'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  ({String label, Color color}) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'in_confirmation': return (label: 'DA CONFERMARE', color: Colors.purple.shade600);
      case 'in_progress': return (label: 'IN LAVORO', color: Colors.teal.shade600);
      case 'assigned': return (label: 'ASSEGNATO', color: Colors.orange.shade600);
      default: return (label: status.toUpperCase(), color: Colors.grey);
    }
  }
}
