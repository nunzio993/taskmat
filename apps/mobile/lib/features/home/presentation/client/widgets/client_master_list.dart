import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/widgets/task_card.dart';
import '../../../domain/task.dart';
import '../../../application/tasks_provider.dart';

class ClientMasterList extends ConsumerStatefulWidget {
  final AsyncValue<List<Task>> tasksAsync;
  final Function(Task) onTaskSelected;
  final int? selectedTaskId;
  final VoidCallback onCreateTask;
  final LatLng? userLocation;

  const ClientMasterList({
    super.key, 
    required this.tasksAsync, 
    required this.onTaskSelected,
    this.selectedTaskId,
    required this.onCreateTask,
    this.userLocation,
  });

  @override
  ConsumerState<ClientMasterList> createState() => _ClientMasterListState();
}

class _ClientMasterListState extends ConsumerState<ClientMasterList> {
  bool _showHistory = false; // Filter: Active (default) vs History

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Bar & Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Text('My Tasks', style: Theme.of(context).textTheme.headlineSmall),
                   // Desktop Create Button
                   if (MediaQuery.of(context).size.width > 900)
                     ElevatedButton.icon(
                       onPressed: widget.onCreateTask,
                       icon: const Icon(Icons.add),
                       label: const Text('New Task'),
                     ),
                 ],
               ),
               const SizedBox(height: 16),
               // Filters
               Row(
                 children: [
                    FilterChip(
                      label: const Text('Active'),
                      selected: !_showHistory,
                      onSelected: (v) => setState(() => _showHistory = !v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('History'),
                      selected: _showHistory,
                      onSelected: (v) => setState(() => _showHistory = v),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: () => ref.refresh(nearbyTasksProvider),
                    ),
                 ],
               ),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: widget.tasksAsync.when(
            data: (tasks) {
               // Filter logic
               // Active: posted, assigning, assigned, in_progress, in_confirmation, payment_failed
               // History: completed, cancelled
               final filtered = tasks.where((t) {
                  final isHistoryStatus = ['completed', 'cancelled'].contains(t.status);
                  return _showHistory ? isHistoryStatus : !isHistoryStatus;
               }).toList();
               
               // Sort by updated_at desc
               filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Fallback to createdAt

               if (filtered.isEmpty) {
                 return Center(
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.inbox, size: 64, color: Colors.grey.shade300),
                       const SizedBox(height: 16),
                       Text(
                         _showHistory ? 'No past tasks.' : 'No active tasks.',
                         style: const TextStyle(color: Colors.grey),
                       ),
                     ],
                   ),
                 );
               }

               return ListView.separated(
                 padding: const EdgeInsets.all(16),
                 itemCount: filtered.length,
                 separatorBuilder: (_, __) => const SizedBox(height: 16),
                 itemBuilder: (context, index) {
                    final task = filtered[index];
                    final isSelected = task.id == widget.selectedTaskId;
                    
                    return Stack(
                      children: [
                        TaskCard(
                          task: task,
                          userLocation: widget.userLocation,
                          onTap: () => widget.onTaskSelected(task),
                          // Specific Client visual tweaks could be passed here
                        ),
                        if (isSelected)
                           Positioned.fill(
                             child: IgnorePointer(
                               child: Container(
                                 decoration: BoxDecoration(
                                   borderRadius: BorderRadius.circular(16),
                                   border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                                 ),
                               ),
                             ),
                           ),
                      ],
                    );
                 },
               );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
