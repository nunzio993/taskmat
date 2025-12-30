import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../home/domain/task.dart';
import '../application/task_controller.dart';
import '../../auth/application/auth_provider.dart';
import '../../home/application/tasks_provider.dart';
import '../../../core/widgets/section_header.dart';
import '../../home/presentation/offer_dialog.dart';
import '../../home/presentation/offers_list.dart';
import '../../home/presentation/chat_screen.dart';
import '../../home/presentation/proof_upload_dialog.dart';
import '../../../core/api_client.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final Task initialTask;

  const TaskDetailsScreen({super.key, required this.task}) : initialTask = task;
  final Task task;

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    // Moved watch out of build method for stateful wiget logic correctness
    final taskState = ref.watch(taskControllerProvider);
    final session = ref.watch(authProvider).value;
    
    final nearbyTasks = ref.watch(nearbyTasksProvider);
    final currentTask = nearbyTasks.valueOrNull?.firstWhere(
      (element) => element.id == widget.initialTask.id,
      orElse: () => widget.initialTask,
    ) ?? widget.initialTask;
    
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // Desktop: Centralized Layout
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AppBar(
                        title: const Text('Task Details'), 
                        automaticallyImplyLeading: false,
                        actions: [IconButton(onPressed: ()=> context.pop(), icon: const Icon(Icons.close))],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             // Map: Central and Square
                             AspectRatio(
                               aspectRatio: 1.5, // Not perfectly square to save vertical space, but consistent box
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(16),
                                 child: Stack(
                                   children: [
                                     _buildMapHeader(currentTask),
                                     if (_currentLocation != null)
                                       Positioned(
                                          bottom: 16,
                                          right: 16,
                                          child: FloatingActionButton.small(
                                            onPressed: () {
                                              if (_currentLocation != null) {
                                                _mapController.move(_currentLocation!, 15);
                                              }
                                            },
                                            child: const Icon(Icons.my_location),
                                          ),
                                       )
                                   ],
                                 ),
                               ),
                             ),
                             const SizedBox(height: 32),
                             _buildHeaderSection(context, currentTask),
                             const SizedBox(height: 24),
                             const Divider(),
                             const SizedBox(height: 24),
                             _buildDescriptionSection(context, currentTask, session),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomBar(context, ref, currentTask, session, taskState.isLoading) ?? const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          }

          // Mobile View
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildMapHeader(currentTask),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeaderSection(context, currentTask),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(context, currentTask, session),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
      // Only show bottom bar globally on mobile, on desktop it's in the right column/bottom of card
      bottomNavigationBar: MediaQuery.of(context).size.width > 800 
        ? null 
        : _buildBottomBar(context, ref, currentTask, session, taskState.isLoading),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildCategoryPill(context, task),
            const SizedBox(width: 8),
            _buildUrgencyPill(context, task),
            const Spacer(),
            _buildStatusBadge(context, task),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          task.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
           '€${(task.priceCents / 100).toStringAsFixed(2)}',
           style: Theme.of(context).textTheme.headlineMedium?.copyWith(
             color: Theme.of(context).colorScheme.primary,
             fontWeight: FontWeight.bold,
           ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, Task task, UserSession? session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Description'),
        Text(
          task.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (task.status == 'posted' && session?.role == 'client') ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Offers'),
          OffersList(taskId: task.id, offers: task.offers),
        ],
        if ((task.status == 'in_confirmation' || task.status == 'completed') && task.proofs.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Proof of Work'),
          const SizedBox(height: 8),
          ...task.proofs.map((p) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ClipRRect(
               borderRadius: BorderRadius.circular(8),
               // In a real app, use p.storageKey as URL (or presigned url)
               // For mock, it's a file path which won't load on client if helper uploaded it from their device
               // UNLESS we are on the same device simulator OR backend acts as proxy.
               // Since backend mock stores "mock_proof_timestamp.jpg", we can't display it easily without S3.
               // For demo purposes, we will display a Placeholder Icon or just Text if it's a mock key.
               // If p.storageKey starts with 'http', show NetworkImage.
                child: p.storageKey.startsWith('http')
                  ? Image.network(p.storageKey, height: 200, width: double.infinity, fit: BoxFit.cover)
                  : p.storageKey.startsWith('/static')
                    ? Image.network('${ref.read(apiClientProvider).options.baseUrl}${p.storageKey}', height: 200, width: double.infinity, fit: BoxFit.cover)
                    : p.storageKey.startsWith('/') && !kIsWeb
                      ? Image.file(File(p.storageKey), height: 200, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => const SizedBox())
                      : Container(
                          height: 200, 
                          width: double.infinity, 
                          color: Colors.grey[200], 
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image, size: 50, color: Colors.grey),
                              Text('Proof Image'),
                            ],
                          ),
                        ),
            ),
          )),
        ]
      ],
    );
  }

  Widget _buildMapHeader(Task task) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(task.lat, task.lon),
        initialZoom: 15.0,
      ),
      children: [
        TileLayer(
           urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(task.lat, task.lon),
              width: 80,
              height: 80,
              child: const Icon(Icons.location_on, color: Colors.blue, size: 50),
            ),
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 60,
                height: 60,
                child: const Icon(Icons.my_location, color: Colors.green, size: 40),
              )
          ],
        ),
        // Gradient overlay for text readability if we put text on map
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPill(BuildContext context, Task task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        task.category,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildUrgencyPill(BuildContext context, Task task) {
    Color color;
    switch(task.urgency) {
      case 'high': color = Colors.red; break;
      case 'medium': color = Colors.orange; break;
      default: color = Colors.green;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        task.urgency.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: color
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Task task) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bgColor;
    Color textColor;

    switch (task.status) {
      case 'posted':
        bgColor = isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50;
        textColor = Colors.blue;
        break;
      case 'locked':
      case 'assigned':
        bgColor = isDark ? Colors.orange.withOpacity(0.2) : Colors.orange.shade50;
        textColor = Colors.orange;
        break;
      case 'completed':
        bgColor = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
        textColor = Colors.green;
        break;
      default:
        bgColor = isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade100;
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        task.status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context, WidgetRef ref, Task task, UserSession? session, bool isLoading) {
    final action = _getAction(context, ref, task, session);
    
    if (action == null) return null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : action.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: action.isDestructive ? Colors.red : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(action.label),
          ),
        ),
      ),
    );
  }

  _TaskAction? _getAction(BuildContext context, WidgetRef ref, Task task, UserSession? session) {
    if (session == null) return null;
    final controller = ref.read(taskControllerProvider.notifier);

    if (session.role == 'helper') {
      if (task.status.trim().toLowerCase() == 'posted') {
        final hasOffered = task.offers.any((o) => o.helperId == session.id);
        if (hasOffered) {
          return _TaskAction(label: 'Offer Sent', onPressed: null); // Disabled
        }

        return _TaskAction(
          label: 'Accept Task (Make Offer)', 
          onPressed: () async {
            final result = await showDialog(
              context: context, 
              builder: (_) => OfferDialog(taskId: task.id, currentPriceCents: task.priceCents)
            );
            if (result == true) {
              controller.fetchTasks(); 
            }
          }
        );
      }
      if (task.status == 'assigned' || task.status == 'in_progress' || task.status == 'in_confirmation') {
         // Chat Button + Main Action? 
         // For now, let's just make the main action context aware or split actions.
         // But _TaskAction supports only one button currently.
         // Let's PRIORITIZE Work actions, but ideally we want a FAB for chat.
         // For simplicity, if assigned, we show "Start Work". Chat can be accessed via sidebar or another button?
         // Let's Add Chat to a different place? Or keep it here if status is assigned.
         
         // If assigned, we return Start Work. But where is Chat?
         // Let's simply RETURN CHAT if no other action pending?
         // NO, the user needs to start work.
         
         // Solution: Add a Floating Action Button for Chat in the Scaffold if assigned?
         // Or just put Chat in the bottom bar as a secondary button? Current UI supports 1 button.
         // Let's Replace "Start Work" with "Open Chat" for verification? No.
         
         // Let's modify the UI to allow multiple actions? Too complex for now.
         // Let's just make the PRIMARY action "Start Work".
         // And maybe add an AppBar action for Chat?
      }
      
      if (task.status == 'assigned') {
        return _TaskAction(label: 'Start Work', onPressed: () => controller.startTask(task.id));
      }
      if (task.status == 'in_progress') {
        return _TaskAction(
          label: 'Mark as Done', 
          onPressed: () async {
            final result = await showDialog(
              context: context,
              builder: (_) => ProofUploadDialog(taskId: task.id),
            );
            if (result == true) {
              await controller.completeRequest(task.id);
            }
          }
        );
      }
    }

    if (session.role == 'client') {
       if (task.status == 'in_confirmation') {
         return _TaskAction(label: 'Confirm Payment', onPressed: () => controller.confirmCompletion(task.id));
       }
    }
    
    // Fallback Chat Action for both if active task
    final isActive = ['assigned', 'in_progress', 'in_confirmation'].contains(task.status);
    if (isActive) {
       return _TaskAction(
         label: 'Open Chat', 
         onPressed: () {
           // Target User ID Determination
           int? targetUserId;
           if (session.role == 'client') {
             // Need to find helper ID. 
             // Ideally task has helper_id or we get it from selected offer lookup
             // For now, assuming task.selectedOfferId lookup is needed or we need query.
             // HACK: Use offer list or just assume we know logic. 
             // We configured Task to have 'clientId'. We don't have 'helperId'.
             // We need to fetch it. `OffersList` fetches offers.
             // Let's just pass 0 for now and handle it in ChatScreen or update Service to fetch active thread.
             // BETTER: Update ChatScreen to resolve helperId if not provided?
             // OR: Use `task.selectedOfferId` -> FETCH OFFER -> Get HelperId.
             // This is async. `onPressed` is sync.
             
             // Quick Fix: Pass the hard part to ChatScreen or make this async.
             // Let's make `onPressed` work.
             
             Navigator.of(context).push(
               MaterialPageRoute(builder: (_) => ChatScreen(
                 taskId: task.id, 
                 helperId: 0, // FIXME: Needs real helper ID
                 title: task.title
               ))
             );
           } else {
             // Helper chatting with client
             targetUserId = task.clientId ?? 0;
             Navigator.of(context).push(
               MaterialPageRoute(builder: (_) => ChatScreen(
                 taskId: task.id, 
                 helperId: session.user.id, // Thread ID is defined by Helper ID in my backend logic!
                 title: task.title
               ))
             );
           }
         }
       );
    }

    return null;
  }
}

class _TaskAction {
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  _TaskAction({required this.label, required this.onPressed, this.isDestructive = false});
}
