import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:latlong2/latlong.dart';

import '../../domain/task.dart';
import '../../application/tasks_provider.dart';
import 'widgets/client_master_list.dart';
import 'widgets/client_detail_pane.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  final LatLng? userLocation;

  const ClientDashboardScreen({super.key, this.userLocation});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  int? _selectedTaskId;

  void _onTaskSelected(Task task) {
    if (MediaQuery.of(context).size.width > 900) {
      setState(() {
        _selectedTaskId = task.id;
      });
    } else {
      context.push('/task', extra: task);
    }
  }

  void _onCreateTask() {
    context.push('/create-task');
  }

  @override
  Widget build(BuildContext context) {
    // For clients, we might need a different provider or filter 'myTasks'.
    // Assuming nearbyTasksProvider is generic enough or we create 'myTasksProvider'.
    // For now, let's use nearbyTasksProvider but in real app clients see THEIR tasks.
    // Let's assume we filter locally for now or need a new provider.
    // Ideally Ref: `myTasksProvider`. Using `nearbyTasksProvider` as placeholder.
    final myTasksAsync = ref.watch(nearbyTasksProvider); // TODO: Switch to myTasksProvider
    
    final width = MediaQuery.of(context).size.width;
    final isSplitView = width > 900;
    
    Task? selectedTask;
    if (_selectedTaskId != null && myTasksAsync.hasValue) {
       final found = myTasksAsync.value!.where((t) => t.id == _selectedTaskId);
       if (found.isNotEmpty) selectedTask = found.first;
    }

    return Scaffold(
      body: Row(
        children: [
          // Left: Master List
          Expanded(
            flex: 4,
            child: ClientMasterList(
              tasksAsync: myTasksAsync,
              userLocation: widget.userLocation,
              onTaskSelected: _onTaskSelected,
              selectedTaskId: _selectedTaskId,
              onCreateTask: _onCreateTask,
            ),
          ),
          
          // Right: Detail Pane
          if (isSplitView) ...[
            const VerticalDivider(width: 1),
            Expanded(
              flex: 6,
              child: selectedTask != null 
                ? ClientDetailPane(
                    key: ValueKey(selectedTask.id),
                    task: selectedTask,
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Select a task to manage', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
            ),
          ]
        ],
      ),
      floatingActionButton: !isSplitView 
        ? FloatingActionButton(
            onPressed: _onCreateTask,
            child: const Icon(Icons.add),
          )
        : null, // FAB handled within MasterList for desktop or just hidden
    );
  }
}
