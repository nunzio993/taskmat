import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../../domain/task.dart';
import '../../application/tasks_provider.dart';
import 'widgets/helper_master_list.dart';
import 'widgets/helper_detail_pane.dart';

class FindWorkScreen extends ConsumerStatefulWidget {
  final LatLng? userLocation;
  
  const FindWorkScreen({super.key, this.userLocation});

  @override
  ConsumerState<FindWorkScreen> createState() => _FindWorkScreenState();
}

class _FindWorkScreenState extends ConsumerState<FindWorkScreen> {
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

  @override
  Widget build(BuildContext context) {
    final nearbyTasksAsync = ref.watch(nearbyTasksProvider);
    final width = MediaQuery.of(context).size.width;
    final isSplitView = width > 900;
    
    // Find selected task in the fresh list
    Task? selectedTask;
    if (_selectedTaskId != null && nearbyTasksAsync.hasValue) {
       final found = nearbyTasksAsync.value!.where((t) => t.id == _selectedTaskId);
       if (found.isNotEmpty) {
         selectedTask = found.first;
       }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Work'),
      ),
      body: Row(
        children: [
          // Left: Master List
          Expanded(
            flex: 4,
            child: HelperMasterList(
              tasksAsync: nearbyTasksAsync,
              userLocation: widget.userLocation,
              onTaskSelected: _onTaskSelected,
              selectedTaskId: _selectedTaskId,
            ),
          ),
          
          // Right: Detail Pane (Only in Split View)
          if (isSplitView) ...[
             const VerticalDivider(width: 1),
             Expanded(
               flex: 6,
               child: selectedTask != null 
                 ? HelperDetailPane(
                     key: ValueKey(selectedTask.id),
                     task: selectedTask,
                     userLocation: widget.userLocation,
                   )
                 : const Center(
                     child: Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Icon(Icons.touch_app, size: 64, color: Colors.grey),
                         SizedBox(height: 16),
                         Text('Select a task to view details', style: TextStyle(color: Colors.grey)),
                       ],
                     ),
                   ),
             ),
          ],
        ],
      ),
    );
  }
}
