import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../domain/task.dart';
import '../../application/tasks_provider.dart';
import '../../application/task_service.dart';
import '../../../../features/chat/application/chat_providers.dart';
import '../../../../features/chat/domain/chat_models.dart';
import '../client/widgets/client_detail_pane.dart';

// Enums for UI State
enum TaskFilter { active, history }

class HelperMyJobsPage extends ConsumerStatefulWidget {
  const HelperMyJobsPage({super.key});

  @override
  ConsumerState<HelperMyJobsPage> createState() => _HelperMyJobsPageState();
}

class _HelperMyJobsPageState extends ConsumerState<HelperMyJobsPage> {
  TaskFilter _filter = TaskFilter.active;
  int? _selectedTaskId;
  bool _isWideScreen = false;

  @override
  Widget build(BuildContext context) {
    _isWideScreen = MediaQuery.of(context).size.width > 800;
    
    // CHANGE: Use assigned tasks provider
    final tasksAsync = ref.watch(myAssignedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Jobs'),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: _buildFilterSegment()
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final filtered = _applyFilter(tasks, _filter);
          
          if (_isWideScreen) {
             return Row(
               children: [
                 SizedBox(
                   width: 350, 
                   child: _buildTaskList(filtered)
                 ),
                 const VerticalDivider(width: 1),
                 Expanded(
                   child: _selectedTaskId == null 
                     ? const Center(child: Text('Select a job'))
                     : _buildTaskDetail(tasks.firstWhere((t) => t.id == _selectedTaskId))
                 ),
               ],
             );
          } else {
             return _selectedTaskId == null 
               ? _buildTaskList(filtered)
               : _buildTaskDetail(tasks.firstWhere((t) => t.id == _selectedTaskId));
          }
        },
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  List<Task> _applyFilter(List<Task> tasks, TaskFilter filter) {
    if (filter == TaskFilter.active) {
       // Helper sees assigned or in_progress tasks here
       return tasks.where((t) => ['assigned', 'in_progress', 'in_confirmation'].contains(t.status.trim().toLowerCase())).toList();
    } else {
       return tasks.where((t) => ['completed', 'cancelled', 'payment_failed'].contains(t.status.trim().toLowerCase())).toList();
    }
  }

  Widget _buildFilterSegment() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SegmentedButton<TaskFilter>(
        segments: const [
          ButtonSegment(value: TaskFilter.active, label: Text('Active')),
          ButtonSegment(value: TaskFilter.history, label: Text('History')),
        ],
        selected: {_filter},
        onSelectionChanged: (newSelection) {
           setState(() {
             _filter = newSelection.first;
             _selectedTaskId = null; // Reset selection on filter change
           });
        },
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No jobs assigned yet', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTaskId == task.id;
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedTaskId = task.id;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, 
                width: 2
              ),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${task.category} • ${task.urgency.toUpperCase()}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(task.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '€${(task.priceCents/100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w800,
                        color: Colors.black87
                      ),
                    ),
                    // If assigned or inactive, maybe just show time or nothing, or status badge duplicated?
                    // Client's page shows "N Offers" or "Assigned".
                    // Let's mirror client: Show a small status text/icon if not posted.
                    if (task.status != 'posted')
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                         decoration: BoxDecoration(
                           color: _getStatusColor(task.status).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Row(
                           children: [
                             Icon(Icons.info_outline, size: 12, color: _getStatusColor(task.status)),
                             const SizedBox(width: 4),
                             Text(
                               task.status.toUpperCase(),
                               style: TextStyle(
                                 color: _getStatusColor(task.status),
                                 fontWeight: FontWeight.bold,
                                 fontSize: 10
                               ),
                             ),
                           ],
                         ),
                       ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    timeago.format(task.createdAt), 
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch(status.toLowerCase()) {
      case 'posted': return Colors.blue;
      case 'assigned': return Colors.orange;
      case 'in_progress': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildStatusBadge(String status) {
    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: _getStatusColor(status),
      padding: EdgeInsets.zero,
    );
  }

  // --- DETAIL VIEW ---
  
  Widget _buildTaskDetail(Task task) {
     if (!_isWideScreen) {
        return WillPopScope(
          onWillPop: () async {
            setState(() {
              _selectedTaskId = null;
            });
            return false;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(task.title),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedTaskId = null),
              ),
            ),
            body: _buildDetailContent(task),
          ),
        );
     }
     
     return Scaffold(
        body: _buildDetailContent(task),
     );
  }

  Widget _buildDetailContent(Task task) {
     return SingleChildScrollView(
       padding: const EdgeInsets.all(16),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            _JobDetailsCard(task: task),
            const SizedBox(height: 24),
            // Actions for Helper
            if (['assigned', 'in_progress', 'completed'].contains(task.status)) ...[
               _ActiveJobActions(task: task),
            ],
         ],
       ),
     );
  }
}

class _JobDetailsCard extends StatelessWidget {
  final Task task;
  const _JobDetailsCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                     const SizedBox(height: 8),
                     _buildStatusChip(task.status),
                   ],
                 ),
               ),
             ],
           ),
           const Divider(height: 32),
           Row(
             children: [
               Expanded(child: _buildInfoItem(Icons.category_outlined, 'Category', task.category)),
               const SizedBox(width: 16),
               Expanded(child: _buildInfoItem(Icons.euro, 'Earnings', '€${(task.priceCents/100).toStringAsFixed(2)}')),
               const SizedBox(width: 16),
               Expanded(child: _buildInfoItem(Icons.timelapse, 'Urgency', task.urgency.toUpperCase(), isBadge: true)),
             ],
           ),
           const SizedBox(height: 24),
           Text('Description', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
           const SizedBox(height: 8),
           Text(
             task.description, 
             style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
           ),
           const SizedBox(height: 24),
           Text('Photos from Client', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey)),
           const SizedBox(height: 12),
           if (task.proofs.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_outlined, color: Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text('No photos attached', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              )
           else 
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: task.proofs.length,
                  separatorBuilder: (c, i) => const SizedBox(width: 8),
                  itemBuilder: (c, i) => Container(
                     width: 100,
                     decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                     child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
        ],
      ),
    );
  }
  
  Widget _buildStatusChip(String status) {
    Color color;
    switch(status.toLowerCase()) {
      case 'posted': color = Colors.blue; break;
      case 'assigned': color = Colors.orange; break;
      case 'in_progress': color = Colors.purple; break;
      case 'completed': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
           Icon(icon, size: 16, color: Colors.grey),
           const SizedBox(width: 4),
           Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
        const SizedBox(height: 4),
        if (isBadge)
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
             child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade700)),
           )
        else
           Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _ActiveJobActions extends ConsumerStatefulWidget {
  final Task task;
  const _ActiveJobActions({required this.task});
  
  @override
  ConsumerState<_ActiveJobActions> createState() => _ActiveJobActionsState();
}

class _ActiveJobActionsState extends ConsumerState<_ActiveJobActions> {
  bool _isLoading = false;

  void _openChatWithClient() async {
    try {
      final thread = await ref.read(myTaskThreadProvider(widget.task.id).future);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ChatDialogContent(
              thread: thread,
              taskId: widget.task.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error opening chat: $e'))
        );
      }
    }
  }

  Future<void> _startWork() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(taskServiceProvider.notifier).startTask(widget.task.id);
      // Refresh
      ref.invalidate(myAssignedTasksProvider);
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work started! Good luck.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeWork() async {
     setState(() => _isLoading = true);
     try {
       await ref.read(taskServiceProvider.notifier).requestCompletion(widget.task.id);
       // Refresh
       ref.invalidate(myAssignedTasksProvider);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completion requested! Waiting for client confirmation.')));
       }
     } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     } finally {
       if (mounted) setState(() => _isLoading = false);
     }
  }

  @override
  Widget build(BuildContext context) {
     final status = widget.task.status;
     final isAssigned = status == 'assigned';
     final isInProgress = status == 'in_progress';
     final isCompleted = status == 'completed';

     return Card(
       color: Colors.blue.shade50,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: Padding(
         padding: const EdgeInsets.all(16),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
              Text(
                isCompleted 
                 ? 'Job Completed' 
                 : isInProgress 
                   ? 'Job In Progress' 
                   : 'Job Active',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), 
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 16),
              
              if (!isCompleted)
              ElevatedButton.icon(
                onPressed: _openChatWithClient,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat with Client'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey.shade300)
                ),
              ),
              
              const SizedBox(height: 12),

              if (isAssigned)
                 ElevatedButton(
                   onPressed: _isLoading ? null : _startWork,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.orange,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Start Work'),
                 ),

              if (isInProgress)
                 ElevatedButton(
                   onPressed: _isLoading ? null : _completeWork,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Colors.purple,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 16),
                   ),
                   child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Mark as Completed'),
                 ),
                 
              if (isCompleted)
                 Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(8)),
                   child: const Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Job Done!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                     ],
                   ),
                 )
           ],
         ),
       ),
     );
  }
}
