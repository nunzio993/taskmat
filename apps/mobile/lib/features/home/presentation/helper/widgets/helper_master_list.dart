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
  double _maxDistance = 50.0; // km

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
                if (_onlyUrgent && t.urgency != 'high') return false;
                // Distance filter
                if (widget.userLocation != null) {
                  final dist = const Distance().as(LengthUnit.Kilometer, widget.userLocation!, LatLng(t.lat, t.lon));
                  if (dist > _maxDistance) return false;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Sort, Category, Urgency, Actions
          Row(
            children: [
              // Sort Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    underline: const SizedBox(),
                    isExpanded: true,
                    icon: Icon(Icons.sort, color: Colors.teal.shade600, size: 18),
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.teal.shade700, fontSize: 13),
                    onChanged: (v) => setState(() => _sortBy = v!),
                    items: const [
                      DropdownMenuItem(value: 'distance', child: Text('Più vicini')),
                      DropdownMenuItem(value: 'created_desc', child: Text('Più recenti')),
                      DropdownMenuItem(value: 'price_desc', child: Text('Prezzo ↓')),
                      DropdownMenuItem(value: 'price_asc', child: Text('Prezzo ↑')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Category Button
              _buildFilterButton(
                icon: Icons.category_outlined,
                label: _selectedCategory ?? 'Categoria',
                isActive: _selectedCategory != null,
                onTap: _showCategoryPicker,
              ),
              const SizedBox(width: 8),
              // Urgency Toggle
              _buildFilterButton(
                icon: Icons.flash_on,
                label: 'Urgenti',
                isActive: _onlyUrgent,
                activeColor: Colors.orange,
                onTap: () => setState(() => _onlyUrgent = !_onlyUrgent),
              ),
              const SizedBox(width: 8),
              // Refresh
              _buildIconButton(
                icon: Icons.refresh,
                onTap: () => ref.refresh(nearbyTasksProvider),
              ),
              // Reset (only if filters active)
              if (_selectedCategory != null || _onlyUrgent || _sortBy != 'distance' || _maxDistance != 50.0) ...[
                const SizedBox(width: 6),
                _buildIconButton(
                  icon: Icons.filter_alt_off,
                  color: Colors.red,
                  onTap: () => setState(() {
                    _selectedCategory = null;
                    _onlyUrgent = false;
                    _sortBy = 'distance';
                    _maxDistance = 50.0;
                  }),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Distance Slider Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Colors.teal.shade600, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Max:',
                  style: TextStyle(color: Colors.teal.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.teal.shade400,
                      inactiveTrackColor: Colors.teal.shade100,
                      thumbColor: Colors.teal.shade600,
                      overlayColor: Colors.teal.withOpacity(0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _maxDistance,
                      min: 1,
                      max: 100,
                      divisions: 99,
                      onChanged: (v) => setState(() => _maxDistance = v),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_maxDistance.toInt()} km',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required bool isActive,
    MaterialColor activeColor = Colors.teal,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive ? activeColor.shade100 : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isActive ? activeColor.shade700 : Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive ? activeColor.shade700 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildIconButton({
    required IconData icon,
    MaterialColor color = Colors.teal,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.shade50,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: color.shade600),
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
