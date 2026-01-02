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
                return _buildEmptyState();
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                   final task = filtered[index];
                   final isSelected = task.id == widget.selectedTaskId;
                   
                   return _buildTaskCard(task, isSelected);
                },
              );
            },
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.teal.shade400),
              ),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.teal.shade300),
                  const SizedBox(height: 12),
                  Text('Errore: $e', style: TextStyle(color: Colors.teal.shade600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.teal.shade50,
              Colors.teal.shade100.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.search_off, size: 40, color: Colors.teal.shade400),
            ),
            const SizedBox(height: 16),
            Text(
              'Nessuna task trovata',
              style: TextStyle(
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prova a modificare i filtri',
              style: TextStyle(
                color: Colors.teal.shade500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Task task, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? Colors.teal.shade400 : Colors.teal.shade100,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(isSelected ? 0.15 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onTaskSelected(task),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category icon + Title
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(task.category),
                        color: Colors.teal.shade600,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.teal.shade900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Price + Distance + Time row
                Row(
                  children: [
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '€${(task.priceCents / 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Distance
                    Icon(Icons.location_on, size: 14, color: Colors.teal.shade400),
                    const SizedBox(width: 2),
                    Text(
                      _getDistanceString(task),
                      style: TextStyle(
                        color: Colors.teal.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // Time ago
                    Text(
                      _getTimeAgo(task.createdAt),
                      style: TextStyle(
                        color: Colors.teal.shade400,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Colors.teal.shade100)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
             // Sort Dropdown
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
               decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.teal.shade200),
               ),
               child: DropdownButton<String>(
                 value: _sortBy,
                 underline: const SizedBox(),
                 icon: Icon(Icons.arrow_drop_down, color: Colors.teal.shade600),
                 style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade700, fontSize: 13),
                 onChanged: (v) => setState(() => _sortBy = v!),
                 items: const [
                   DropdownMenuItem(value: 'distance', child: Text('Distanza')),
                   DropdownMenuItem(value: 'created_desc', child: Text('Più recenti')),
                   DropdownMenuItem(value: 'price_desc', child: Text('Prezzo: Alto')),
                   DropdownMenuItem(value: 'price_asc', child: Text('Prezzo: Basso')),
                 ],
               ),
             ),
             const SizedBox(width: 10),
             // Category Chip
             FilterChip(
               label: Text(_selectedCategory ?? 'Tutte le categorie'),
               selected: _selectedCategory != null,
               selectedColor: Colors.teal.shade100,
               checkmarkColor: Colors.teal.shade700,
               labelStyle: TextStyle(
                 color: _selectedCategory != null ? Colors.teal.shade700 : Colors.teal.shade600,
                 fontSize: 12,
               ),
               backgroundColor: Colors.white,
               side: BorderSide(color: Colors.teal.shade200),
               onSelected: (v) => _showCategoryPicker(),
             ),
             const SizedBox(width: 8),
             // Urgency Chip
             FilterChip(
               label: const Text('Solo Urgenti'),
               selected: _onlyUrgent,
               selectedColor: Colors.orange.shade100,
               checkmarkColor: Colors.orange.shade700,
               labelStyle: TextStyle(
                 color: _onlyUrgent ? Colors.orange.shade700 : Colors.teal.shade600,
                 fontSize: 12,
               ),
               backgroundColor: Colors.white,
               side: BorderSide(color: _onlyUrgent ? Colors.orange.shade300 : Colors.teal.shade200),
               onSelected: (v) => setState(() => _onlyUrgent = v),
             ),
             const SizedBox(width: 8),
             // Refresh Button
             Container(
               decoration: BoxDecoration(
                 color: Colors.teal.shade50,
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: Colors.teal.shade200),
               ),
               child: IconButton(
                 icon: Icon(Icons.refresh, color: Colors.teal.shade600, size: 20), 
                 constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                 padding: EdgeInsets.zero,
                 onPressed: () => ref.refresh(nearbyTasksProvider),
               ),
             ),
             // Reset Button
             if (_selectedCategory != null || _onlyUrgent || _sortBy != 'distance') ...[
               const SizedBox(width: 6),
               Container(
                 decoration: BoxDecoration(
                   color: Colors.red.shade50,
                   borderRadius: BorderRadius.circular(8),
                   border: Border.all(color: Colors.red.shade200),
                 ),
                 child: IconButton(
                   icon: Icon(Icons.clear, color: Colors.red.shade600, size: 20), 
                   constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                   padding: EdgeInsets.zero,
                   onPressed: () => setState(() {
                     _selectedCategory = null;
                     _onlyUrgent = false;
                     _sortBy = 'distance';
                   }),
                 ),
               ),
             ],
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() async {
     final categories = ['Pulizie', 'Traslochi', 'Giardinaggio', 'Montaggio Mobili', 'Idraulica'];
     
     final result = await showDialog<String>(
       context: context, 
       builder: (context) => SimpleDialog(
         title: Text('Seleziona Categoria', style: TextStyle(color: Colors.teal.shade800)),
         children: [
           SimpleDialogOption(
             onPressed: () => Navigator.pop(context, null),
             child: Row(
               children: [
                 Icon(Icons.all_inclusive, color: Colors.teal.shade400, size: 20),
                 const SizedBox(width: 12),
                 const Text('Tutte le categorie'),
               ],
             ),
           ),
           ...categories.map((c) => SimpleDialogOption(
             onPressed: () => Navigator.pop(context, c),
             child: Row(
               children: [
                 Icon(_getCategoryIcon(c), color: Colors.teal.shade400, size: 20),
                 const SizedBox(width: 12),
                 Text(c),
               ],
             ),
           )),
         ],
       ),
     );
     
     setState(() {
       _selectedCategory = result;
     });
  }

  String _getDistanceString(Task task) {
    if (widget.userLocation != null) {
      final dist = const Distance().as(LengthUnit.Kilometer, widget.userLocation!, LatLng(task.lat, task.lon));
      if (dist < 1) {
        return '${(dist * 1000).toStringAsFixed(0)} m';
      }
      return '${dist.toStringAsFixed(1)} km';
    }
    return 'Vicino a te';
  }

  String _getTimeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min fa';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ore fa';
    } else {
      return '${diff.inDays} giorni fa';
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
}
