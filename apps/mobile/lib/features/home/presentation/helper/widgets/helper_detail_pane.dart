import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/task.dart';
import '../../../application/task_service.dart';
import '../../../../auth/application/auth_provider.dart';
import 'clarification_chat.dart';
import 'task_location_map.dart';

class HelperDetailPane extends ConsumerStatefulWidget {
  final Task task;
  final LatLng? userLocation;

  const HelperDetailPane({super.key, required this.task, this.userLocation});

  @override
  ConsumerState<HelperDetailPane> createState() => _HelperDetailPaneState();
}

class _HelperDetailPaneState extends ConsumerState<HelperDetailPane> {
  final _priceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isMakingOffer = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if needed? or just empty
    // _priceCtrl.text = (widget.task.priceCents / 100).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }
  
  // Basic validation check
  bool get _canOffer {
    final session = ref.read(authProvider).value;
    if (session == null || session.role != 'helper') return false;
    return widget.task.status == 'posted';
  }

  Future<void> _sendOffer() async {
    final price = double.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price')));
      return;
    }
    
    setState(() => _isMakingOffer = true);
    
    try {
      final priceCents = (price * 100).round();
      await ref.read(taskServiceProvider.notifier).createOffer(
        widget.task.id,
        priceCents,
        _noteCtrl.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer Sent!')));
        _priceCtrl.clear();
        _noteCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isMakingOffer = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
     final task = widget.task;
     final isAvailable = task.status == 'posted';

     return Container(
       color: Theme.of(context).colorScheme.surface,
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.stretch,
         children: [
            // Header
            _buildHeader(context, task),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unavailable Banner
                    if (!isAvailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: const Row(
                          children: [
                             Icon(Icons.lock, color: Colors.red),
                             SizedBox(width: 12),
                             Expanded(child: Text("Chat disabled: This task is no longer POSTED.", style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                      
                    // Description
                    Text('Description', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(task.description, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),

                    // Location Map
                    TaskLocationMapWidget(task: task),
                    const SizedBox(height: 24),
                    
                    // Chat Section (Real)
                    Text('Clarifications', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ClarificationChatWidget(
                      task: task,
                      isEnabled: isAvailable,
                    ),
                    const SizedBox(height: 24),
                    
                    // Offer Section
                    Text('Your Offer', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _priceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Price (€)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.euro),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      enabled: isAvailable,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(),
                        hintText: 'I can do this because...',
                      ),
                      maxLines: 2,
                      enabled: isAvailable,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isAvailable && !_isMakingOffer ? _sendOffer : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isMakingOffer 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                          : const Text('Send Offer'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
         ],
       ),
     );
  }
  
  Widget _buildHeader(BuildContext context, Task task) {
    return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: Theme.of(context).colorScheme.surface,
         border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
              children: [
                 // Client Info
                 CircleAvatar(
                   backgroundColor: Colors.grey.shade200,
                   backgroundImage: task.client?.avatarUrl != null ? NetworkImage(task.client!.avatarUrl!) : null,
                   child: task.client?.avatarUrl == null 
                     ? Text(task.client?.displayName.isNotEmpty == true ? task.client!.displayName[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold)) 
                     : null,
                 ),
                 const SizedBox(width: 12),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Row(
                       children: [
                         Text(task.client?.displayName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                         const SizedBox(width: 8),
                         const Icon(Icons.star, size: 14, color: Colors.amber),
                         Text(task.client?.avgRating.toStringAsFixed(1) ?? 'N/A', style: const TextStyle(fontSize: 12)),
                       ],
                     ),
                     Text('Posted ${timeago.format(task.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                   ],
                 ),
                 const Spacer(),
                 // Status Badge
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: task.status == 'posted' ? Colors.green.shade50 : Colors.grey.shade100,
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: task.status == 'posted' ? Colors.green : Colors.grey),
                   ),
                   child: Text(
                     task.status.toUpperCase(),
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 12,
                       color: task.status == 'posted' ? Colors.green : Colors.grey,
                     ),
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 16),
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(context, task.category, Icons.work_outline),
                if (widget.userLocation != null) ...[
                   const SizedBox(width: 8),
                   _buildChip(context, "${const Distance().as(LengthUnit.Kilometer, widget.userLocation!, LatLng(task.lat, task.lon)).toStringAsFixed(1)} km", Icons.location_on),
                ]
              ],
            )
         ],
       ),
    );
  }
  
  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
           Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
           const SizedBox(width: 4),
           Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
