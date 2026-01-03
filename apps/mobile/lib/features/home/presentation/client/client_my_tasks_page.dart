import 'dart:async'; // Add this for Future.delayed
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/task.dart';
import '../../application/tasks_provider.dart';
import '../../application/task_service.dart';
import '../../../chat/application/chat_providers.dart';
import '../../../chat/domain/chat_models.dart';
import '../../../profile/application/user_service.dart';
import '../../../reviews/presentation/review_dialog.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'widgets/client_offers_list.dart';
import 'widgets/client_detail_pane.dart'; // For ChatDialogContent
import 'widgets/task_review_button.dart';

// Enums for UI State
enum TaskFilter { active, history }

class ClientMyTasksPage extends ConsumerStatefulWidget {
  const ClientMyTasksPage({super.key});

  @override
  ConsumerState<ClientMyTasksPage> createState() => _ClientMyTasksPageState();
}

class _ClientMyTasksPageState extends ConsumerState<ClientMyTasksPage> {
  TaskFilter _filter = TaskFilter.active;
  int? _selectedTaskId;
  bool _isWideScreen = false;

  @override
  Widget build(BuildContext context) {
    _isWideScreen = MediaQuery.of(context).size.width > 800;
    
    final tasksAsync = ref.watch(myCreatedTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Le Mie Task', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.teal.shade600),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
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
                 VerticalDivider(width: 1, color: Colors.teal.shade100),
                 Expanded(
                   child: _selectedTaskId == null 
                     ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app, size: 64, color: Colors.teal.shade200),
                            const SizedBox(height: 16),
                            Text('Seleziona una task', style: TextStyle(color: Colors.teal.shade400)),
                          ],
                        ),
                      )
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
        error: (e, s) => Center(child: Text('Errore: $e', style: TextStyle(color: Colors.red.shade600))),
        loading: () => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.teal.shade400))),
      ),
    );
  }

  List<Task> _applyFilter(List<Task> tasks, TaskFilter filter) {
    if (filter == TaskFilter.active) {
       return tasks.where((t) => ['posted', 'assigned', 'in_progress', 'in_confirmation'].contains(t.status.trim().toLowerCase())).toList();
    } else {
       return tasks.where((t) => ['completed', 'cancelled', 'payment_failed'].contains(t.status.trim().toLowerCase())).toList();
    }
  }

  Widget _buildFilterSegment() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _filter = TaskFilter.active; _selectedTaskId = null; }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _filter == TaskFilter.active ? Colors.teal.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Center(
                  child: Text(
                    'Attive',
                    style: TextStyle(
                      color: _filter == TaskFilter.active ? Colors.white : Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() { _filter = TaskFilter.history; _selectedTaskId = null; }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _filter == TaskFilter.history ? Colors.teal.shade600 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Center(
                  child: Text(
                    'Cronologia',
                    style: TextStyle(
                      color: _filter == TaskFilter.history ? Colors.white : Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.assignment_outlined, size: 48, color: Colors.teal.shade300),
            ),
            const SizedBox(height: 16),
            Text('Nessuna task', style: TextStyle(color: Colors.teal.shade600, fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text(
              _filter == TaskFilter.active ? 'Crea una nuova task per iniziare' : 'Nessuna task completata',
              style: TextStyle(color: Colors.teal.shade400, fontSize: 14),
            ),
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
              color: isSelected ? Colors.teal.shade50 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.teal.shade400 : Colors.teal.shade100, 
                width: isSelected ? 2 : 1
              ),
              boxShadow: [
                if (!isSelected)
                  BoxShadow(
                    color: Colors.teal.withValues(alpha: 0.08),
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
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.w800,
                        color: Colors.teal.shade700
                      ),
                    ),
                    if (task.status == 'posted')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.offers.isNotEmpty ? Colors.green.shade50 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${task.offers.length} Offers',
                          style: TextStyle(
                            color: task.offers.isNotEmpty ? Colors.green.shade700 : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 12
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(task.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      timeago.format(task.createdAt), 
                      style: TextStyle(fontSize: 10, color: Colors.grey[400])
                    ),
                    // Review button for completed tasks
                    if (task.status == 'completed')
                      TaskReviewButton(task: task),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch(status.toLowerCase()) {
      case 'posted': color = Colors.blue; break;
      case 'assigned': color = Colors.orange; break;
      case 'in_progress': color = Colors.purple; break;
      case 'completed': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      padding: EdgeInsets.zero,
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

  // --- DETAIL VIEW ---
  
  Widget _buildTaskDetail(Task task) {
     if (!_isWideScreen) {
        // Wrap in WillPopScope to handle back nav for mobile split simulation
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
            // Details Section (Viewing + Editing if Allowed)
            _EditTaskSection(task: task),
              
            const SizedBox(height: 24),
            
            // Actions Card (like Helper)
            if (['assigned', 'in_progress', 'in_confirmation'].contains(task.status)) ...[
               _ActiveTaskActions(task: task),
               const SizedBox(height: 24),
            ],
            
            // Review Section for completed tasks
            if (task.status == 'completed') ...[
               _ReviewSection(task: task),
               const SizedBox(height: 24),
            ],
            
            // Messages & Offers (Client-specific)
            if (['posted', 'assigned', 'in_progress'].contains(task.status)) ...[
               _ChatThreadsSection(taskId: task.id),
               const SizedBox(height: 24),
               _OffersSection(task: task),
            ],
         ],
       ),
     );
  }
}

// --- SUB WIDGETS ---

class _EditTaskSection extends ConsumerStatefulWidget {
  final Task task;
  const _EditTaskSection({required this.task});

  @override
  ConsumerState<_EditTaskSection> createState() => _EditTaskSectionState();
}

class _EditTaskSectionState extends ConsumerState<_EditTaskSection> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  String _selectedCategory = 'General';
  String _selectedUrgency = 'medium';
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _priceCtrl = TextEditingController(text: (widget.task.priceCents / 100).toStringAsFixed(2));
    _selectedCategory = widget.task.category;
    _selectedUrgency = widget.task.urgency;
  }

  @override
  void didUpdateWidget(covariant _EditTaskSection oldWidget) {
     super.didUpdateWidget(oldWidget);
     if (oldWidget.task.id != widget.task.id) {
        _initControllers();
        _isEditing = false;
     }
  }

  Future<void> _save() async {
    try {
      final priceDouble = double.tryParse(_priceCtrl.text) ?? 0.0;
      final priceCents = (priceDouble * 100).round();
      
      await ref.read(taskServiceProvider.notifier).updateTask(widget.task.id, {
        'title': _titleCtrl.text,
        'description': _descCtrl.text,
        'category': _selectedCategory,
        'price_cents': priceCents,
        'urgency': _selectedUrgency,
        'lat': widget.task.lat,
        'lon': widget.task.lon
      });
      ref.invalidate(myCreatedTasksProvider);
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
      ],
      border: Border.all(color: Colors.teal.shade100),
    );

    if (!_isEditing) {
      return Container(
        decoration: cardDecoration,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Header: Title + Status + Edit
             Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(widget.task.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                       const SizedBox(height: 8),
                       _buildStatusChip(widget.task.status),
                     ],
                   ),
                 ),
                 if (widget.task.status == 'posted')
                   InkWell(
                     onTap: () => setState(() => _isEditing = true),
                     borderRadius: BorderRadius.circular(8),
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                       decoration: BoxDecoration(
                         color: Colors.teal.shade50,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: Row(
                         children: [
                           Icon(Icons.edit, size: 16, color: Colors.teal.shade700),
                           const SizedBox(width: 6),
                           Text('Edit', style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold)),
                         ],
                       ),
                     ),
                   )
               ],
             ),
             Divider(height: 32, color: Colors.teal.shade100),
             
             // Key Info Grid
             Row(
               children: [
                 Expanded(child: _buildInfoItem(Icons.category_outlined, 'Category', widget.task.category)),
                 const SizedBox(width: 16),
                 Expanded(child: _buildInfoItem(Icons.euro, 'Budget', '€${(widget.task.priceCents/100).toStringAsFixed(2)}')),
                 const SizedBox(width: 16),
                 Expanded(child: _buildInfoItem(Icons.timelapse, 'Urgency', widget.task.urgency.toUpperCase(), isBadge: true)),
               ],
             ),
             const SizedBox(height: 24),

             // Description
             Row(
               children: [
                 Icon(Icons.description_outlined, size: 16, color: Colors.teal.shade500),
                 const SizedBox(width: 6),
                 Text('Descrizione', style: TextStyle(fontSize: 12, color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
               ],
             ),
             const SizedBox(height: 8),
             Container(
               padding: const EdgeInsets.all(14),
               decoration: BoxDecoration(
                 color: Colors.teal.shade50.withValues(alpha: 0.3),
                 borderRadius: BorderRadius.circular(10),
                 border: Border.all(color: Colors.teal.shade100),
               ),
               child: Text(
                 widget.task.description, 
                 style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey.shade700),
               ),
             ),
             
             const SizedBox(height: 24),
             
             // Photos Section (Placeholder)
             Row(
               children: [
                 Icon(Icons.photo_outlined, size: 16, color: Colors.teal.shade500),
                 const SizedBox(width: 6),
                 Text('Foto', style: TextStyle(fontSize: 12, color: Colors.teal.shade600, fontWeight: FontWeight.w500)),
               ],
             ),
             const SizedBox(height: 12),
             if (widget.task.proofs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade100)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_outlined, color: Colors.teal.shade300),
                      const SizedBox(width: 8),
                      Text('Nessuna foto', style: TextStyle(color: Colors.teal.shade400)),
                    ],
                  ),
                )
             else 
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.task.proofs.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (c, i) => Container(
                       width: 100,
                       decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                       child: const Icon(Icons.image, color: Colors.grey), // Placeholder for actual image
                    ),
                  ),
                ),
          ],
        ),
      );
    }
    
    // Edit Mode
    return Container(
      decoration: cardDecoration,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           const Text('Edit Task Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
           const SizedBox(height: 24),
           TextField(
             controller: _titleCtrl, 
             decoration: _inputDeco('Title'),
           ),
           const SizedBox(height: 16),
           Row(
             children: [
               Expanded(
                 child: DropdownButtonFormField<String>(
                   value: _selectedCategory,
                   decoration: _inputDeco('Category'),
                   items: ['General', 'Cleaning', 'Moving', 'Gardening', 'Tech Support']
                     .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                     .toList(),
                   onChanged: (v) => setState(() => _selectedCategory = v ?? 'General'),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: DropdownButtonFormField<String>(
                   value: _selectedUrgency,
                   decoration: _inputDeco('Urgency'),
                   items: ['low', 'medium', 'high']
                     .map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase(), style: TextStyle(color: u=='high'?Colors.red:null))))
                     .toList(),
                   onChanged: (v) => setState(() => _selectedUrgency = v ?? 'medium'),
                 ),
               ),
             ],
           ),
           const SizedBox(height: 16),
           TextField(
             controller: _priceCtrl,
             decoration: _inputDeco('Price').copyWith(prefixText: '€ ', suffixText: ' EUR'),
             keyboardType: const TextInputType.numberWithOptions(decimal: true),
           ),
           const SizedBox(height: 16),
           TextField(
             controller: _descCtrl, 
             decoration: _inputDeco('Description').copyWith(alignLabelWithHint: true), 
             maxLines: 6
           ),
           const SizedBox(height: 24),
           Row(
             mainAxisAlignment: MainAxisAlignment.end,
             children: [
               TextButton(
                 onPressed: () => setState(() => _isEditing = false), 
                 child: const Text('Cancel')
               ),
               const SizedBox(width: 8),
               ElevatedButton(
                 onPressed: _save,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.black,
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                 ),
                 child: const Text('Save Changes'),
               ),
             ],
           )
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch(status.toLowerCase()) {
      case 'posted': color = Colors.teal; break;
      case 'assigned': color = Colors.orange; break;
      case 'in_progress': return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.purple.withValues(alpha: 0.2))),
          child: const Text('IN CORSO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.purple)),
      );
      case 'completed': color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(status.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {bool isBadge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
           Icon(icon, size: 16, color: Colors.teal.shade500),
           const SizedBox(width: 4),
           Text(label, style: TextStyle(fontSize: 12, color: Colors.teal.shade600)),
        ]),
        const SizedBox(height: 4),
        if (isBadge)
           Container(
             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
             decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
             child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red.shade700)),
           )
        else
           Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal.shade800), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _OffersSection extends ConsumerStatefulWidget {
  final Task task;
  
  const _OffersSection({required this.task});

  @override
  ConsumerState<_OffersSection> createState() => _OffersSectionState();
}

class _OffersSectionState extends ConsumerState<_OffersSection> {

  void _showChatDialog(BuildContext context, WidgetRef ref, ChatThread thread, TaskOffer? offer) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ChatDialogContent(
          thread: thread,
          taskId: widget.task.id,
          offer: offer,
          onAcceptOffer: (o) => _acceptOffer(context, ref, o),
          onDeclineOffer: (o) => _declineOffer(context, ref, o),
        ),
      ),
    );
  }

  void _openChatWithHelper(BuildContext context, WidgetRef ref, int helperId) async {
    print('DEBUG: _openChatWithHelper called with helperId=$helperId, taskId=${widget.task.id}');
    try {
      print('DEBUG: Loading threads...');
      final threads = await ref.read(taskThreadsProvider(widget.task.id).future);
      print('DEBUG: Loaded ${threads.length} threads');
      var thread = threads.where((t) => t.helperId == helperId).firstOrNull;

      if (thread == null) {
        print('DEBUG: No thread found locally for helper $helperId, creating one...');
        try {
          thread = await ref.read(chatServiceProvider).getOrCreateThreadAsClient(widget.task.id, helperId);
          // Refresh the list provider so it appears there too
          ref.invalidate(taskThreadsProvider(widget.task.id));
        } catch (e) {
          print('DEBUG: Failed to create thread: $e');
        }
      }
      
      if (thread != null) {
        print('DEBUG: Found/Created thread for helper $helperId, opening dialog');
        // Find the offer from this helper (if any)
        final offer = (widget.task.offers).where((o) => o.helperId == helperId).firstOrNull;
        if (context.mounted) {
          _showChatDialog(context, ref, thread, offer);
        }
      } else {
        print('DEBUG: Still no thread for helper $helperId');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to start chat with this helper.')),
          );
        }
      }
    } catch (e) {
      print('DEBUG: Error in _openChatWithHelper: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading chat: $e')),
        );
      }
    }
  }

  void _acceptOffer(BuildContext context, WidgetRef ref, TaskOffer offer) async {
    try {
      print('DEBUG: Accepting offer ${offer.id}...');
      await ref.read(taskServiceProvider.notifier).selectOffer(widget.task.id, offer.id);
      
      print('DEBUG: API call success. Waiting 500ms before refresh...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('DEBUG: Invalidating tasks provider...');
      ref.invalidate(myCreatedTasksProvider); 
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer accepted!')),
        );
      }
    } catch (e) {
      print('DEBUG: Error accepting offer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _declineOffer(BuildContext context, WidgetRef ref, TaskOffer offer) async {
    try {
      print('DEBUG: Declining offer ${offer.id}...');
      await ref.read(taskServiceProvider.notifier).declineOffer(widget.task.id, offer.id);
      
      print('DEBUG: API call success. Waiting 500ms before refresh...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      print('DEBUG: Invalidating tasks provider...');
      ref.invalidate(myCreatedTasksProvider); 
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer declined.')),
        );
      }
    } catch (e) {
      print('DEBUG: Error declining offer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     if (widget.task.offers.isEmpty) return const SizedBox.shrink();

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
              children: [
                Icon(Icons.local_offer_outlined, color: Colors.teal.shade600),
                const SizedBox(width: 8),
                Text(
                  'Offerte (${widget.task.offers.length})', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800)
                ),
              ],
            ),
            const SizedBox(height: 16),
            
             ClientOffersList(
               task: widget.task,
               onOpenChat: (helperId) => _openChatWithHelper(context, ref, helperId),
               onAcceptOffer: (offer) => _acceptOffer(context, ref, offer),
               onDeclineOffer: (offer) => _declineOffer(context, ref, offer),
             ),
          ],
        ),
     );
  }
}

class _ActiveTaskActions extends ConsumerWidget {
  final Task task;
  const _ActiveTaskActions({required this.task});
  
  void _openChatWithHelper(BuildContext context, WidgetRef ref) async {
    // We try to find the thread with the assigned helper
    // If not found, we might need to handle it, but usually if assigned/in_progress it exists or we can find it via offers.
    // For simplicity, we'll try to get the thread for the task and open the first one (usually 1:1 if assigned).
    try {
      final threads = await ref.read(taskThreadsProvider(task.id).future);
      // In a 1:1 assigned task, there should be one main thread or we pick the one matching assigned_to logic if available.
      // For now, open the first thread or show error
      if (threads.isNotEmpty) {
        if (context.mounted) {
             showDialog(
              context: context,
              builder: (_) => Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ChatDialogContent(
                  thread: threads.first,
                  taskId: task.id,
                ),
              ),
            );
        }
      } else {
         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No chat thread found')));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _confirmCompletion(BuildContext context, WidgetRef ref) async {
     try {
       await ref.read(taskServiceProvider.notifier).confirmCompletion(task.id);
       ref.invalidate(myCreatedTasksProvider);
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task confirmed completed!')));
       }
     } catch (e) {
       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
     }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
     final status = task.status;
     final isInConfirmation = status == 'in_confirmation';
     final isInProgress = status == 'in_progress';
     final isAssigned = status == 'assigned';
     
     return Container(
       padding: const EdgeInsets.all(20),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         border: Border.all(color: Colors.teal.shade100),
         boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
           Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Icon(
                 isInConfirmation ? Icons.hourglass_empty : isInProgress ? Icons.play_circle : Icons.assignment_turned_in,
                 color: isInConfirmation ? Colors.purple.shade600 : Colors.teal.shade600,
               ),
               const SizedBox(width: 8),
               Text(
                 isInConfirmation ? 'In Attesa Conferma' : isInProgress ? 'Lavoro in Corso' : 'Lavoro Assegnato',
                 style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800),
               ),
             ],
           ),
           const SizedBox(height: 16),
           
           OutlinedButton.icon(
             onPressed: () => _openChatWithHelper(context, ref),
             icon: Icon(Icons.chat_bubble_outline, color: Colors.teal.shade600),
             label: Text('Chat con Helper', style: TextStyle(color: Colors.teal.shade600)),
             style: OutlinedButton.styleFrom(
               padding: const EdgeInsets.symmetric(vertical: 14),
               side: BorderSide(color: Colors.teal.shade300),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
             ),
           ),
           
           if (isInConfirmation) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _confirmCompletion(context, ref),
                icon: const Icon(Icons.check_circle),
                label: const Text('Conferma Completamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
           ]
         ],
       ),
     );
  }
}

class _ChatThreadsSection extends ConsumerWidget {
  final int taskId;
  const _ChatThreadsSection({required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(taskThreadsProvider(taskId));

    return threadsAsync.when(
      data: (threads) {
        if (threads.isEmpty) return const SizedBox.shrink();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: Colors.teal.shade100),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 children: [
                   Icon(Icons.chat_bubble_outline, size: 20, color: Colors.teal.shade600),
                   const SizedBox(width: 8),
                   Text('Messaggi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800)),
                 ],
               ),
              const SizedBox(height: 16),
              ...threads.map((thread) => _buildThreadItem(context, thread)),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (e, st) => Text('Error loading chats: $e', style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildThreadItem(BuildContext context, ChatThread thread) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.shade100,
          child: Text(
            (thread.helperName?.isNotEmpty == true ? thread.helperName! : 'Helper').substring(0, 1).toUpperCase(),
            style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => context.push('/u/${thread.helperId}'),
              child: Text(
                thread.helperName ?? 'Helper',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, decoration: TextDecoration.underline),
              ),
            ),
            if (thread.messages.isNotEmpty)
               Text(
                 timeago.format(thread.messages.last.createdAt, locale: 'en_short'),
                 style: const TextStyle(fontSize: 12, color: Colors.grey),
               ),
          ],
        ),
        subtitle: Text(
          thread.messages.isNotEmpty ? thread.messages.last.body : 'Start chatting...',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: thread.messages.isNotEmpty ? Colors.grey.shade700 : Colors.grey.shade400),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
             showDialog(
                context: context,
                builder: (_) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ChatDialogContent(
                    thread: thread,
                    taskId: taskId,
                  ),
                ),
             );
        },
      ),
    );
  }
}

class _ReviewSection extends ConsumerWidget {
  final Task task;
  const _ReviewSection({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ReviewStatus>(
      future: ref.read(userServiceProvider.notifier).getTaskReviewStatus(task.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final status = snapshot.data;
        final hasReviewed = status?.hasReviewed ?? false;
        final myReview = status?.myReview;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: Colors.amber.shade200),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Recensione',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber.shade800),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (hasReviewed && myReview != null) ...[
                // Show submitted review
                Row(
                  children: [
                    ...List.generate(myReview.stars, (i) =>
                      Icon(Icons.star_rounded, size: 24, color: Colors.amber.shade500)
                    ),
                    ...List.generate(5 - myReview.stars, (i) =>
                      Icon(Icons.star_outline_rounded, size: 24, color: Colors.grey.shade300)
                    ),
                  ],
                ),
                if (myReview.comment != null && myReview.comment!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '"${myReview.comment}"',
                    style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade700),
                  ),
                ],
                if (myReview.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: myReview.tags.map((tag) => Chip(
                      label: Text(tag, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.amber.shade50,
                    )).toList(),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      status!.reviewsVisible ? Icons.visibility : Icons.hourglass_empty,
                      size: 16,
                      color: status.reviewsVisible ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.reviewsVisible
                          ? 'Recensione visibile'
                          : 'In attesa della recensione dell\'helper',
                      style: TextStyle(
                        fontSize: 12,
                        color: status.reviewsVisible ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Show review button
                Text(
                  'Come è stata l\'esperienza con ${task.assignedHelperName ?? "l\'helper"}?',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (_) => ReviewDialog(
                        taskId: task.id,
                        targetUserName: task.assignedHelperName ?? 'Helper',
                        isReviewingAsClient: true,
                      ),
                    );
                    if (result == true) {
                      ref.invalidate(myCreatedTasksProvider);
                    }
                  },
                  icon: const Icon(Icons.star_outline_rounded),
                  label: const Text('Lascia una Recensione'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
