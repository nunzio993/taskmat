import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/widgets/task_card.dart';
import '../../../domain/task.dart';
import '../../../application/tasks_provider.dart';

class HelperMasterList extends ConsumerStatefulWidget {
  final AsyncValue<List<Task>> tasksAsync;
  final LatLng? userLocation;
  final Function(Task) onTaskSelected;
  final int? selectedTaskId;

  const HelperMasterList({
    super.key, 
    required this.tasksAsync, 
    this.userLocation, 
    required this.onTaskSelected,
    this.selectedTaskId,
  });

  @override
  ConsumerState<HelperMasterList> createState() => _HelperMasterListState();
}

class _HelperMasterListState extends ConsumerState<HelperMasterList> {
  // Filters
  String? _selectedCategory;
  bool _onlyUrgent = false;
  String _sortBy = 'distance'; // distance, price_desc, price_asc, created_desc

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: widget.tasksAsync.when(
            data: (tasks) {
              // Apply Filters
              var filtered = tasks.where((t) {
                if (_selectedCategory != null && t.category != _selectedCategory) return false;
                if (_onlyUrgent) {
                   // Mock urgency check (assume urgent logic exists or based on createdAt)
                   // For now, let's say "Urgent" tasks are placeholder logic or we add 'urgency' field later.
                   // Let's assume urgency is checked by description containing "ASAP" or similar for MVP?
                   // No, let's skip strict urgency logic implementation until backend supports it, 
                   // or just filter generic.
                   return true; 
                }
                return true;
              }).toList();

              // Apply Sort
              filtered.sort((a, b) {
                if (_sortBy == 'price_desc') {
                  return b.priceCents.compareTo(a.priceCents);
                } else if (_sortBy == 'price_asc') {
                  return a.priceCents.compareTo(b.priceCents);
                } else if (_sortBy == 'distance' && widget.userLocation != null) {
                   final distA = const Distance().as(LengthUnit.Meter, widget.userLocation!, LatLng(a.lat, a.lon));
                   final distB = const Distance().as(LengthUnit.Meter, widget.userLocation!, LatLng(b.lat, b.lon));
                   return distA.compareTo(distB);
                }
                // default created_desc
                return b.createdAt.compareTo(a.createdAt);
              });

              if (filtered.isEmpty) {
                return const Center(child: Text('No tasks found matching criteria.'));
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
                       ),
                       if (isSelected)
                         Positioned.fill(
                           child: IgnorePointer(
                             child: Container(
                               decoration: BoxDecoration(
                                 border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                                 borderRadius: BorderRadius.circular(16),
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

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                 // Sort
                 DropdownButton<String>(
                   value: _sortBy,
                   underline: const SizedBox(),
                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                   onChanged: (v) => setState(() => _sortBy = v!),
                   items: const [
                     DropdownMenuItem(value: 'distance', child: Text('Distance')),
                     DropdownMenuItem(value: 'created_desc', child: Text('Newest')),
                     DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                     DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                   ],
                 ),
                 const SizedBox(width: 12),
                 // Category
                 FilterChip(
                   label: Text(_selectedCategory ?? 'All Categories'),
                   selected: _selectedCategory != null,
                   onSelected: (v) {
                     // Show dialog or cycling logic?
                     // For MVP simple cycle or dialog
                     _showCategoryPicker();
                   },
                 ),
                 const SizedBox(width: 8),
                 // Urgency
                 FilterChip(
                   label: const Text('Urgent Only'),
                   selected: _onlyUrgent,
                   onSelected: (v) => setState(() => _onlyUrgent = v),
                 ),
                 const SizedBox(width: 8),
                 // Refresh
                 IconButton(
                   icon: const Icon(Icons.sync), 
                   onPressed: () => ref.refresh(nearbyTasksProvider),
                 ),
                 // Reset
                 if (_selectedCategory != null || _onlyUrgent || _sortBy != 'distance')
                   IconButton(
                     icon: const Icon(Icons.refresh), 
                     onPressed: () => setState(() {
                       _selectedCategory = null;
                       _onlyUrgent = false;
                       _sortBy = 'distance';
                     }),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() async {
     // Mock categories - normally fetch from config/backend
     final categories = ['Cleaning', 'Delivery', 'Repair', 'Moving', 'Gardening'];
     
     final result = await showDialog<String>(
       context: context, 
       builder: (context) => SimpleDialog(
         title: const Text('Select Category'),
         children: [
           SimpleDialogOption(
             onPressed: () => Navigator.pop(context, null),
             child: const Text('All Categories'),
           ),
           ...categories.map((c) => SimpleDialogOption(
             onPressed: () => Navigator.pop(context, c),
             child: Text(c),
           )),
         ],
       ),
     );
     
     setState(() {
       _selectedCategory = result;
     });
  }
}
