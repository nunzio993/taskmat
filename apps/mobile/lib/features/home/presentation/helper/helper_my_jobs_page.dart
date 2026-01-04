import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';

import '../../domain/task.dart';
import '../../application/tasks_provider.dart';
import '../../application/task_service.dart';
import '../../../../features/chat/application/chat_providers.dart';
import '../../../../features/chat/domain/chat_models.dart';
import '../client/widgets/client_detail_pane.dart';
import '../../../../features/reviews/presentation/review_dialog.dart';
import '../../../../features/profile/application/user_service.dart';

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
    final tasksAsync = ref.watch(myAssignedTasksProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('I Miei Lavori', style: TextStyle(color: Colors.teal.shade800, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.teal.shade600),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterSegment(),
        ),
      ),
      body: tasksAsync.when(
        data: (tasks) {
          final filtered = _applyFilter(tasks, _filter);
          
          if (_isWideScreen) {
            return Row(
              children: [
                SizedBox(width: 380, child: _buildTaskList(filtered)),
                VerticalDivider(width: 1, color: Colors.teal.shade100),
                Expanded(
                  child: _selectedTaskId == null 
                    ? _buildEmptySelection()
                    : _buildTaskDetail(tasks.firstWhere((t) => t.id == _selectedTaskId)),
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

  Widget _buildEmptySelection() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.teal.shade50, shape: BoxShape.circle),
            child: Icon(Icons.touch_app, size: 48, color: Colors.teal.shade300),
          ),
          const SizedBox(height: 16),
          Text('Seleziona un lavoro', style: TextStyle(color: Colors.teal.shade600, fontSize: 16)),
        ],
      ),
    );
  }

  List<Task> _applyFilter(List<Task> tasks, TaskFilter filter) {
    if (filter == TaskFilter.active) {
      return tasks.where((t) => ['assigned', 'in_progress', 'in_confirmation'].contains(t.status.trim().toLowerCase())).toList();
    } else {
      return tasks.where((t) => ['completed', 'cancelled', 'payment_failed'].contains(t.status.trim().toLowerCase())).toList();
    }
  }

  Widget _buildFilterSegment() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildFilterButton('Attivi', TaskFilter.active, Icons.work)),
          const SizedBox(width: 12),
          Expanded(child: _buildFilterButton('Storico', TaskFilter.history, Icons.history)),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, TaskFilter filter, IconData icon) {
    final isSelected = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() { _filter = filter; _selectedTaskId = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.teal.shade400 : Colors.teal.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.teal.shade700 : Colors.teal.shade400),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.teal.shade700 : Colors.teal.shade500,
            )),
          ],
        ),
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
                gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.5)]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.work_off_outlined, size: 48, color: Colors.teal.shade300),
            ),
            const SizedBox(height: 16),
            Text('Nessun lavoro', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade700, fontSize: 16)),
            const SizedBox(height: 4),
            Text(_filter == TaskFilter.active ? 'Cerca nuove opportunità!' : 'Nessun lavoro completato', 
              style: TextStyle(color: Colors.teal.shade500, fontSize: 13)),
          ],
        ),
      );
    }
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTaskId == task.id;
        final statusInfo = _getStatusInfo(task.status);
        
        return GestureDetector(
          onTap: () => setState(() => _selectedTaskId = task.id),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? Colors.teal.shade400 : statusInfo.color.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(color: statusInfo.color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: statusInfo.color,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusInfo.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(statusInfo.label, style: TextStyle(color: statusInfo.color, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.teal.shade600, borderRadius: BorderRadius.circular(8)),
                            child: Text('€${(task.priceCents / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(task.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.grey.shade800), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 14, color: Colors.teal.shade400),
                          const SizedBox(width: 4),
                          Text(task.category, style: TextStyle(color: Colors.teal.shade600, fontSize: 12)),
                          const Spacer(),
                          Text(timeago.format(task.createdAt, locale: 'it'), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ({String label, Color color}) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'in_confirmation': return (label: 'DA CONFERMARE', color: Colors.purple.shade600);
      case 'in_progress': return (label: 'IN CORSO', color: Colors.teal.shade600);
      case 'assigned': return (label: 'ASSEGNATO', color: Colors.orange.shade600);
      case 'completed': return (label: 'COMPLETATO', color: Colors.green.shade600);
      case 'cancelled': return (label: 'CANCELLATO', color: Colors.red.shade600);
      default: return (label: status.toUpperCase(), color: Colors.grey);
    }
  }

  Widget _buildTaskDetail(Task task) {
    if (!_isWideScreen) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) setState(() => _selectedTaskId = null);
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(task.title, style: TextStyle(color: Colors.teal.shade800)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.teal.shade600),
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
      backgroundColor: Colors.grey.shade50,
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
          const SizedBox(height: 20),
          if (['assigned', 'in_progress', 'in_confirmation', 'completed'].contains(task.status.toLowerCase()))
            _ActiveJobActions(task: task),
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
    final statusInfo = _getStatusInfo(task.status);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.teal.shade50, Colors.teal.shade100.withValues(alpha: 0.5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.teal.withValues(alpha: 0.2), blurRadius: 8)]),
                  child: Icon(Icons.work, color: Colors.teal.shade600, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal.shade800)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: statusInfo.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                        child: Text(statusInfo.label, style: TextStyle(color: statusInfo.color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: Colors.teal.shade600, borderRadius: BorderRadius.circular(10)),
                  child: Text('€${(task.priceCents / 100).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoItem(Icons.category_outlined, 'Categoria', task.category)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoItem(Icons.timelapse, 'Urgenza', task.urgency.toUpperCase())),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Descrizione', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 14)),
                const SizedBox(height: 8),
                Text(task.description, style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade700)),
                const SizedBox(height: 20),
                Text('Foto allegati', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700, fontSize: 14)),
                const SizedBox(height: 10),
                if (task.proofs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.photo_outlined, color: Colors.grey.shade400), const SizedBox(width: 8), Text('Nessuna foto', style: TextStyle(color: Colors.grey.shade500))]),
                  )
                else
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: task.proofs.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 8),
                      itemBuilder: (c, i) => Container(width: 80, decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade200)), child: Icon(Icons.image, color: Colors.teal.shade400)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color color}) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'in_confirmation': return (label: 'DA CONFERMARE', color: Colors.purple.shade600);
      case 'in_progress': return (label: 'IN CORSO', color: Colors.teal.shade600);
      case 'assigned': return (label: 'ASSEGNATO', color: Colors.orange.shade600);
      case 'completed': return (label: 'COMPLETATO', color: Colors.green.shade600);
      default: return (label: status.toUpperCase(), color: Colors.grey);
    }
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.teal.shade50.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal.shade500),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.teal.shade500)),
                Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.teal.shade700)),
              ],
            ),
          ),
        ],
      ),
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
  bool _isUploading = false;

  void _openChatWithClient() async {
    try {
      final thread = await ref.read(myTaskThreadProvider(widget.task.id).future);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ChatDialogContent(thread: thread, taskId: widget.task.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red.shade600));
    }
  }

  Future<void> _startWork() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(taskServiceProvider.notifier).startTask(widget.task.id);
      ref.invalidate(myAssignedTasksProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Lavoro iniziato!'), backgroundColor: Colors.green.shade600));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadProof() async {
    // Show picker dialog
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Carica Prova di Completamento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal.shade800)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(context, Icons.camera_alt, 'Fotocamera', 'camera'),
                _buildSourceOption(context, Icons.photo_library, 'Galleria', 'gallery'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    
    if (source == null) return;
    
    setState(() => _isUploading = true);
    
    try {
      // Use image_picker
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image == null) {
        setState(() => _isUploading = false);
        return;
      }
      
      // Upload to backend
      await ref.read(taskServiceProvider.notifier).uploadProof(widget.task.id, image);
      ref.invalidate(myAssignedTasksProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Foto caricata!'), backgroundColor: Colors.green.shade600),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore upload: $e'), backgroundColor: Colors.red.shade600),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildSourceOption(BuildContext context, IconData icon, String label, String value) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.teal.shade600),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Future<void> _completeWork() async {
    // Check if proofs exist
    if (widget.task.proofs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Devi caricare almeno una foto di prova prima di completare'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await ref.read(taskServiceProvider.notifier).requestCompletion(widget.task.id);
      ref.invalidate(myAssignedTasksProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('In attesa di conferma dal cliente'), backgroundColor: Colors.purple.shade600));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red.shade600));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.task.status.toLowerCase();
    final isAssigned = status == 'assigned';
    final isInProgress = status == 'in_progress';
    final isInConfirmation = status == 'in_confirmation';
    final isCompleted = status == 'completed';
    final hasProofs = widget.task.proofs.isNotEmpty;

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
            children: [
              Icon(Icons.flash_on, color: Colors.teal.shade600),
              const SizedBox(width: 8),
              Text('Azioni', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!isCompleted)
            OutlinedButton.icon(
              onPressed: _openChatWithClient,
              icon: Icon(Icons.chat_bubble_outline, color: Colors.teal.shade600),
              label: Text('Chat con Cliente', style: TextStyle(color: Colors.teal.shade600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.teal.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          
          const SizedBox(height: 12),

          if (isAssigned)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startWork,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Inizia Lavoro'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),

          // Proof Upload Section (only show when in_progress)
          if (isInProgress) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.teal.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text('Prove di Completamento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal.shade700)),
                      const Spacer(),
                      if (!hasProofs)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text('Richiesto', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Show uploaded proofs
                  if (widget.task.proofs.isNotEmpty) ...[
                    SizedBox(
                      height: 70,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.task.proofs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return Container(
                            width: 70,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.teal.shade300),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.teal.shade600, size: 28),
                                Positioned(
                                  bottom: 4,
                                  child: Text('Foto ${index + 1}', style: TextStyle(fontSize: 9, color: Colors.teal.shade700)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Upload button
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _uploadProof,
                    icon: _isUploading 
                      ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.teal.shade600)))
                      : Icon(Icons.add_a_photo, color: Colors.teal.shade600),
                    label: Text(_isUploading ? 'Caricamento...' : 'Aggiungi Foto', style: TextStyle(color: Colors.teal.shade600)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.teal.shade400),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Complete button (enabled only if proofs exist)
            ElevatedButton.icon(
              onPressed: (_isLoading || !hasProofs) ? null : _completeWork,
              icon: const Icon(Icons.check),
              label: Text(hasProofs ? 'Segna come Completato' : 'Carica foto per completare'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasProofs ? Colors.teal.shade600 : Colors.grey.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],

          if (isInConfirmation)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.purple.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.purple.shade600),
                  const SizedBox(width: 10),
                  Text('In attesa di conferma cliente', style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
               
          if (isCompleted) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 10),
                  Text('Lavoro completato!', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Review button for helper
            _HelperReviewButton(task: widget.task),
          ],
        ],
      ),
    );
  }
}

/// Review button for helpers to review clients
class _HelperReviewButton extends ConsumerWidget {
  final Task task;
  const _HelperReviewButton({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ReviewStatus>(
      future: ref.read(userServiceProvider.notifier).getTaskReviewStatus(task.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.amber.shade600))),
                const SizedBox(width: 10),
                Text('Caricamento recensione...', style: TextStyle(color: Colors.amber.shade700)),
              ],
            ),
          );
        }

        final status = snapshot.data;
        if (status != null && status.hasReviewed) {
          // Already reviewed - show status
          final stars = status.myReview?.stars ?? 0;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(stars, (i) => Icon(Icons.star_rounded, size: 18, color: Colors.amber.shade600)),
                ...List.generate(5 - stars, (i) => Icon(Icons.star_border_rounded, size: 18, color: Colors.amber.shade300)),
                const SizedBox(width: 10),
                if (status.reviewsVisible)
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green.shade500),
                      const SizedBox(width: 4),
                      Text('Pubblicata', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.w500)),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.hourglass_empty, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('In attesa del cliente', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
              ],
            ),
          );
        }

        // Can review - show button
        return ElevatedButton.icon(
          onPressed: () async {
            final result = await showDialog<bool>(
              context: context,
              builder: (_) => ReviewDialog(
                taskId: task.id,
                targetUserName: task.clientName ?? 'Cliente',
                isReviewingAsClient: false,
              ),
            );

            if (result == true) {
              ref.invalidate(myAssignedTasksProvider);
            }
          },
          icon: const Icon(Icons.star_outline_rounded),
          label: const Text('Lascia una Recensione'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }
}
